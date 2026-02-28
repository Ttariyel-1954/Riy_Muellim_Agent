# ============================================================
# R Shiny Dashboard - Müəllim Agent İdarə Paneli
# ARTI 2026
# ============================================================

library(shiny)
library(shinydashboard)
library(DBI)
library(RPostgres)
library(DT)
library(plotly)
library(httr)
library(jsonlite)

# ─── Database Connection ─────────────────────────────────
get_db_connection <- function() {
  tryCatch({
    dbConnect(
      RPostgres::Postgres(),
      host = Sys.getenv("DB_HOST", "localhost"),
      port = as.integer(Sys.getenv("DB_PORT", "5432")),
      dbname = Sys.getenv("DB_NAME", "muellim_agent"),
      user = Sys.getenv("DB_USER", "arti_admin"),
      password = Sys.getenv("DB_PASSWORD", "")
    )
  }, error = function(e) {
    message("DB bağlantı xətası: ", e$message)
    NULL
  })
}

# ─── API Helper ──────────────────────────────────────────
api_call <- function(endpoint, method = "GET", body = NULL, token = NULL) {
  base_url <- Sys.getenv("API_URL", "http://localhost:3000/api/v1")
  url <- paste0(base_url, "/", endpoint)
  headers <- add_headers(Authorization = paste("Bearer", token))
  
  tryCatch({
    if (method == "GET") {
      resp <- GET(url, headers)
    } else {
      resp <- POST(url, headers, body = toJSON(body, auto_unbox = TRUE), content_type_json())
    }
    content(resp, "parsed")
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

# ═══════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = span(icon("graduation-cap"), " Müəllim Agent"),
    titleWidth = 280
  ),
  
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "tabs",
      menuItem("Ana Səhifə", tabName = "home", icon = icon("home")),
      menuItem("Dərs Planları", tabName = "lessons", icon = icon("book"),
        menuSubItem("Yeni Plan", tabName = "lesson_new"),
        menuSubItem("Planlarım", tabName = "lesson_list")
      ),
      menuItem("Qiymətləndirmə", tabName = "assessment", icon = icon("clipboard-check"),
        menuSubItem("Test Yarat", tabName = "test_create"),
        menuSubItem("CAT Test", tabName = "cat_test"),
        menuSubItem("Nəticə Analizi", tabName = "analysis")
      ),
      menuItem("Şagird Analizi", tabName = "students", icon = icon("users"),
        menuSubItem("Profilər", tabName = "student_profiles"),
        menuSubItem("Risk Qrupları", tabName = "risk_groups"),
        menuSubItem("İnklyuziv", tabName = "inclusive")
      ),
      menuItem("Sənədlər", tabName = "documents", icon = icon("file-alt")),
      menuItem("Kommunikasiya", tabName = "communication", icon = icon("comments")),
      menuItem("Standartlar", tabName = "standards", icon = icon("list-check")),
      menuItem("Statistika", tabName = "statistics", icon = icon("chart-bar")),
      hr(),
      div(class = "sidebar-footer",
        p(style = "padding: 10px; color: #b8c7ce; font-size: 11px;",
          "ARTI 2026 © Tariyel Talibov")
      )
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-top: 3px solid #3c8dbc; }
        .info-box-icon { background-color: #3c8dbc !important; }
        .skin-blue .main-header .navbar { background-color: #003366; }
        .skin-blue .main-header .logo { background-color: #002244; }
      "))
    ),
    
    tabItems(
      # ── Ana Səhifə ──────────────────────────────────
      tabItem(tabName = "home",
        fluidRow(
          infoBox("Dərs Planları", textOutput("plan_count"), icon = icon("book"), color = "blue", width = 3),
          infoBox("Testlər", textOutput("test_count"), icon = icon("clipboard"), color = "green", width = 3),
          infoBox("Şagirdlər", textOutput("student_count"), icon = icon("users"), color = "yellow", width = 3),
          infoBox("Risk Xəbərdarlıqları", textOutput("alert_count"), icon = icon("exclamation-triangle"), color = "red", width = 3)
        ),
        fluidRow(
          box(title = "Son Fəaliyyətlər", width = 8, solidHeader = TRUE, status = "primary",
            DTOutput("recent_activities")
          ),
          box(title = "Sinif Performansı", width = 4, solidHeader = TRUE, status = "info",
            plotlyOutput("class_performance_chart", height = "300px")
          )
        ),
        fluidRow(
          box(title = "Fənn üzrə Orta Bal", width = 6, solidHeader = TRUE,
            plotlyOutput("subject_scores_chart", height = "300px")
          ),
          box(title = "Şagird Səviyyə Paylanması", width = 6, solidHeader = TRUE,
            plotlyOutput("level_distribution_chart", height = "300px")
          )
        )
      ),
      
      # ── Yeni Dərs Planı ────────────────────────────
      tabItem(tabName = "lesson_new",
        fluidRow(
          box(title = "AI ilə Dərs Planı Yaratma", width = 12, solidHeader = TRUE, status = "primary",
            fluidRow(
              column(4, selectInput("lp_subject", "Fənn:", choices = c("RIYAZ" = "RIYAZ", "AZ_DIL" = "AZ_DIL", "FIZIKA" = "FIZIKA", "KIMYA" = "KIMYA", "BIOL" = "BIOL"))),
              column(2, numericInput("lp_grade", "Sinif:", value = 5, min = 1, max = 11)),
              column(4, textInput("lp_topic", "Mövzu:", placeholder = "Dərsin mövzusunu yazın")),
              column(2, selectInput("lp_type", "Plan tipi:", choices = c("Gündəlik" = "daily", "Həftəlik" = "weekly", "Aylıq" = "monthly")))
            ),
            fluidRow(
              column(3, checkboxGroupInput("lp_bloom", "Bloom səviyyələri:", 
                choices = c("Xatırlama" = "xatırlama", "Anlama" = "anlama", "Tətbiqetmə" = "tətbiqetmə", "Təhlil" = "təhlil", "Qiymətləndirmə" = "qiymətləndirmə", "Yaratma" = "yaratma"),
                selected = c("anlama", "tətbiqetmə"))),
              column(2, sliderInput("lp_dok", "DOK Səviyyəsi:", min = 1, max = 4, value = 2)),
              column(2, numericInput("lp_duration", "Müddət (dəq):", value = 45)),
              column(3, checkboxInput("lp_inclusive", "İnklyuziv uyğunlaşdırma", FALSE)),
              column(2, actionButton("lp_generate", "🤖 AI ilə Yarat", class = "btn-primary btn-lg", style = "margin-top: 25px;"))
            ),
            hr(),
            uiOutput("lp_result")
          )
        )
      ),
      
      # ── Test Yaratma ───────────────────────────────
      tabItem(tabName = "test_create",
        fluidRow(
          box(title = "AI Test Generatoru", width = 12, solidHeader = TRUE, status = "success",
            fluidRow(
              column(3, selectInput("tc_subject", "Fənn:", choices = c("RIYAZ", "AZ_DIL", "FIZIKA", "KIMYA", "BIOL"))),
              column(2, numericInput("tc_grade", "Sinif:", value = 5, min = 1, max = 11)),
              column(4, textInput("tc_topic", "Mövzu:")),
              column(3, selectInput("tc_type", "Test tipi:", choices = c("Formativ" = "formative", "Summativ" = "summative", "Diaqnostik" = "diagnostic", "CAT" = "cat")))
            ),
            fluidRow(
              column(2, numericInput("tc_mcq", "MCQ sayı:", value = 10, min = 0)),
              column(2, numericInput("tc_short", "Qısa cavab:", value = 3, min = 0)),
              column(2, numericInput("tc_essay", "Esse:", value = 1, min = 0)),
              column(2, numericInput("tc_tf", "Doğru/Yanlış:", value = 5, min = 0)),
              column(2, sliderInput("tc_diff", "Çətinlik:", min = 0.1, max = 1.0, value = c(0.3, 0.8), step = 0.1)),
              column(2, actionButton("tc_generate", "🤖 Test Yarat", class = "btn-success btn-lg", style = "margin-top: 25px;"))
            ),
            hr(),
            DTOutput("tc_questions_table")
          )
        )
      ),
      
      # ── Nəticə Analizi ────────────────────────────
      tabItem(tabName = "analysis",
        fluidRow(
          box(title = "Psixometrik Analiz", width = 12, solidHeader = TRUE, status = "warning",
            fluidRow(
              column(6, selectInput("an_assessment", "Test seçin:", choices = NULL)),
              column(3, actionButton("an_analyze", "📊 Analiz Et", class = "btn-warning"))
            ),
            hr(),
            fluidRow(
              column(6, plotlyOutput("item_difficulty_chart", height = "350px")),
              column(6, plotlyOutput("score_distribution_chart", height = "350px"))
            ),
            DTOutput("an_results_table")
          )
        )
      ),
      
      # ── Şagird Profilləri ──────────────────────────
      tabItem(tabName = "student_profiles",
        fluidRow(
          box(title = "Şagird Öyrənmə Profilləri", width = 12, solidHeader = TRUE,
            fluidRow(
              column(4, selectInput("sp_class", "Sinif seçin:", choices = NULL)),
              column(4, selectInput("sp_student", "Şagird seçin:", choices = NULL)),
              column(4, actionButton("sp_update", "🔄 Profil Yenilə", class = "btn-info", style = "margin-top: 25px;"))
            ),
            hr(),
            fluidRow(
              column(4, uiOutput("sp_strengths")),
              column(4, uiOutput("sp_weaknesses")),
              column(4, uiOutput("sp_recommendations"))
            ),
            plotlyOutput("sp_trend_chart", height = "300px")
          )
        )
      ),
      
      # ── Risk Qrupları ─────────────────────────────
      tabItem(tabName = "risk_groups",
        fluidRow(
          box(title = "Risk Qrupları - Avtomatik Aşkarlama", width = 12, solidHeader = TRUE, status = "danger",
            actionButton("rg_detect", "🔍 Risk Analizi", class = "btn-danger"),
            hr(),
            DTOutput("rg_table")
          )
        )
      ),
      
      # ── Standartlar ───────────────────────────────
      tabItem(tabName = "standards",
        fluidRow(
          box(title = "Kurikulum Standartları", width = 12, solidHeader = TRUE,
            fluidRow(
              column(4, selectInput("st_subject", "Fənn:", choices = c("RIYAZ", "AZ_DIL", "FIZIKA", "KIMYA", "BIOL"))),
              column(4, numericInput("st_grade", "Sinif:", value = 5, min = 1, max = 11)),
              column(4, actionButton("st_load", "Yüklə", class = "btn-primary", style = "margin-top: 25px;"))
            ),
            hr(),
            DTOutput("standards_table")
          )
        )
      ),
      
      # ── Sənədlər ──────────────────────────────────
      tabItem(tabName = "documents",
        fluidRow(
          box(title = "Sənəd Generatoru", width = 6, solidHeader = TRUE,
            selectInput("doc_type", "Sənəd tipi:", choices = c("Jurnal" = "journal", "Aylıq plan" = "monthly_plan", "Hesabat" = "activity_report")),
            textInput("doc_topic", "Mövzu/Dövr:"),
            actionButton("doc_generate", "📄 Yarat", class = "btn-primary")
          ),
          box(title = "Nəticə", width = 6, solidHeader = TRUE,
            verbatimTextOutput("doc_result")
          )
        )
      ),
      
      # ── Kommunikasiya ─────────────────────────────
      tabItem(tabName = "communication",
        fluidRow(
          box(title = "Mesaj Göndər", width = 6, solidHeader = TRUE,
            selectInput("msg_type", "Mesaj tipi:", choices = c("Valideyn hesabatı" = "parent_report", "Xəbərdarlıq" = "alert", "Tərif" = "praise", "Motivasiya" = "motivation")),
            selectInput("msg_student", "Şagird:", choices = NULL),
            textAreaInput("msg_custom", "Əlavə qeyd:", rows = 3),
            actionButton("msg_send", "📨 Göndər", class = "btn-success")
          ),
          box(title = "Nəticə", width = 6, solidHeader = TRUE,
            verbatimTextOutput("msg_result")
          )
        )
      ),
      
      # ── Statistika ────────────────────────────────
      tabItem(tabName = "statistics",
        fluidRow(
          box(title = "Məktəb Dashboard", width = 12, solidHeader = TRUE, status = "primary",
            fluidRow(
              column(4, plotlyOutput("stat_grade_dist")),
              column(4, plotlyOutput("stat_subject_perf")),
              column(4, plotlyOutput("stat_attendance"))
            )
          )
        )
      )
    )
  )
)

# ═══════════════════════════════════════════════════════════
# SERVER
# ═══════════════════════════════════════════════════════════
server <- function(input, output, session) {
  
  # ── Reactive: DB connection ──
  con <- reactive({
    get_db_connection()
  })
  
  # ── Home page stats ──
  output$plan_count <- renderText({
    db <- con()
    if (is.null(db)) return("N/A")
    tryCatch({
      res <- dbGetQuery(db, "SELECT COUNT(*) as n FROM lesson_plans")
      res$n
    }, error = function(e) "N/A")
  })
  
  output$test_count <- renderText({
    db <- con()
    if (is.null(db)) return("N/A")
    tryCatch({
      res <- dbGetQuery(db, "SELECT COUNT(*) as n FROM assessments")
      res$n
    }, error = function(e) "N/A")
  })
  
  output$student_count <- renderText({
    db <- con()
    if (is.null(db)) return("N/A")
    tryCatch({
      res <- dbGetQuery(db, "SELECT COUNT(*) as n FROM students WHERE is_active = true")
      res$n
    }, error = function(e) "N/A")
  })
  
  output$alert_count <- renderText({
    db <- con()
    if (is.null(db)) return("N/A")
    tryCatch({
      res <- dbGetQuery(db, "SELECT COUNT(*) as n FROM risk_alerts WHERE is_resolved = false")
      res$n
    }, error = function(e) "0")
  })
  
  # ── Standards table ──
  observeEvent(input$st_load, {
    db <- con()
    if (is.null(db)) return()
    tryCatch({
      standards <- dbGetQuery(db, sprintf(
        "SELECT cs.standard_code, cs.standard_text_az, cs.content_area, cs.bloom_level, cs.dok_level, cs.hours_allocated
         FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id
         WHERE s.code = '%s' AND cs.grade = %d ORDER BY cs.standard_code",
        input$st_subject, input$st_grade
      ))
      output$standards_table <- renderDT({
        datatable(standards, options = list(pageLength = 20, language = list(url = "//cdn.datatables.net/plug-ins/1.10.11/i18n/Azerbaijani.json")),
                  colnames = c("Kod", "Standart", "Məzmun", "Bloom", "DOK", "Saat"))
      })
    }, error = function(e) {
      showNotification(paste("Xəta:", e$message), type = "error")
    })
  })
  
  # ── Charts (placeholder with sample data) ──
  output$class_performance_chart <- renderPlotly({
    plot_ly(x = c("5A", "5B", "6A", "6B", "7A"), y = c(72, 68, 75, 80, 65),
            type = "bar", marker = list(color = c("#3c8dbc", "#00a65a", "#f39c12", "#dd4b39", "#605ca8"))) %>%
      layout(title = "", xaxis = list(title = "Sinif"), yaxis = list(title = "Orta bal"))
  })
  
  output$subject_scores_chart <- renderPlotly({
    plot_ly(labels = c("Riyaziyyat", "Azərbaycan dili", "Fizika", "Kimya", "Biologiya"),
            values = c(72, 78, 65, 70, 74), type = "pie",
            marker = list(colors = c("#3c8dbc", "#00a65a", "#f39c12", "#dd4b39", "#605ca8"))) %>%
      layout(title = "")
  })
  
  output$level_distribution_chart <- renderPlotly({
    plot_ly(x = c("Zəif", "Orta", "Yüksək", "Əla"), y = c(15, 45, 30, 10),
            type = "bar", marker = list(color = c("#dd4b39", "#f39c12", "#00a65a", "#3c8dbc"))) %>%
      layout(title = "", xaxis = list(title = "Səviyyə"), yaxis = list(title = "Şagird sayı"))
  })
  
  # ── Cleanup ──
  session$onSessionEnded(function() {
    db <- con()
    if (!is.null(db)) tryCatch(dbDisconnect(db), error = function(e) {})
  })
}

# ─── Run App ─────────────────────────────────────────────
shinyApp(
  ui = ui,
  server = server,
  options = list(
    host = Sys.getenv("SHINY_HOST", "0.0.0.0"),
    port = as.integer(Sys.getenv("SHINY_PORT", "3838"))
  )
)
