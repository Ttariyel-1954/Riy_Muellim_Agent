# Riy_Muellim_Agent v3.0 — Token/Vaxt + Fayl Saxlama
# ARTI 2026 (c) Tariyel Talibov

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(httr)
library(jsonlite)

APP_DIR <- normalizePath("~/Desktop/Riy_Muellim_Agent", mustWork=FALSE)
env_file <- file.path(APP_DIR, ".env")
if(file.exists(env_file)) for(line in readLines(env_file,warn=FALSE)){
  line<-trimws(line); if(nchar(line)>0&&!startsWith(line,"#")&&grepl("=",line)){
    p<-strsplit(line,"=",fixed=TRUE)[[1]]; do.call(Sys.setenv,setNames(list(trimws(paste(p[-1],collapse="="))),trimws(p[1])))}}

CHUNKS_DIR <- file.path(APP_DIR,"derslikler","chunks")
CLAUDE_MODEL <- Sys.getenv("DEFAULT_AI_MODEL", "claude-3-haiku-20240307")
CLAUDE_ENDPOINT <- "https://api.anthropic.com/v1/messages"
DERS_DIR <- file.path(APP_DIR,"Ders_planlari")
TEST_DIR <- file.path(APP_DIR,"Testler")
dir.create(DERS_DIR, showWarnings=FALSE, recursive=TRUE)
dir.create(TEST_DIR, showWarnings=FALSE, recursive=TRUE)

`%||%` <- function(x,y) if(is.null(x)||length(x)==0||(is.character(x)&&all(nchar(x)==0))) y else x

# === STANDARDS ===
ALL_STANDARDS <- tryCatch(fromJSON(file.path(APP_DIR,"derslikler","standards.json"),simplifyVector=FALSE),error=function(e) list())
get_standards_dropdown <- function(grade){
  stds <- ALL_STANDARDS[[as.character(grade)]]
  if(is.null(stds)||length(stds)==0) return(c("---"="---"))
  ch <- character(0)
  for(s in stds){label<-sprintf("%s [%s] %s",s$kod%||%"?",s$sahe%||%"?",s$metn%||%"?");val<-sprintf("%s - %s",s$kod%||%"?",s$metn%||%"?");ch<-c(ch,setNames(val,label))}
  ch
}

# === TOPICS ===
ALL_TOPICS <- tryCatch(fromJSON(file.path(APP_DIR,"derslikler","topics.json"),simplifyVector=FALSE),error=function(e) list())
get_topics_for_grade <- function(grade){
  gd <- ALL_TOPICS[[as.character(grade)]]
  if(is.null(gd)) return(c("---"="---"))
  ch <- character(0)
  for(b in gd$bolmeler){bn<-b$bolme%||%"?"
    for(m in b$movzular){label<-sprintf("[%s] %s (seh. %s)",bn,m$ad%||%"?",m$seh%||%"?");ch<-c(ch,setNames(m$ad%||%"?",label))}}
  if(length(ch)==0) return(c("---"="---"))
  ch
}

# === CHUNKS ===
load_chunks_for_grade <- function(gr){
  fs<-list.files(CHUNKS_DIR,pattern=sprintf("sinif%d_.*\\.json$",gr),full.names=TRUE)
  out<-list(); for(f in fs) tryCatch({out<-c(out,fromJSON(f,simplifyVector=FALSE))},error=function(e){}); out
}
search_chunks <- function(gr,topic,mx=3){
  chs<-load_chunks_for_grade(gr); if(length(chs)==0) return(list())
  tl<-tolower(topic);tw<-strsplit(tl,"\\s+")[[1]];tw<-tw[nchar(tw)>=3]
  sc<-list()
  for(c in chs){s<-0;bl<-tolower(paste(c$text%||%"",c$topic%||%"",c$chapter%||%"",paste(c$keywords%||%character(0),collapse=" ")))
    if(grepl(tl,bl,fixed=TRUE)) s<-s+10; for(w in tw) s<-s+min(length(gregexpr(w,bl,fixed=TRUE)[[1]]),5)
    if(nchar(c$chapter%||%"")>0&&grepl(tl,tolower(c$chapter),fixed=TRUE)) s<-s+15
    if(s>0) sc<-c(sc,list(list(score=s,chunk=c)))}
  sc<-sc[order(-sapply(sc,function(x) x$score))]; lapply(head(sc,mx),function(x) x$chunk)
}
build_context <- function(gr,topic){
  res<-search_chunks(gr,topic); if(length(res)==0) return(sprintf("[Sinif %d, '%s' - kontekst yoxdur]",gr,topic))
  pts<-character(0)
  for(c in res){tx<-c$text%||%"";if(nchar(tx)>4000)tx<-paste0(substr(tx,1,4000),"\n...")
    pts<-c(pts,sprintf("\n--- Derslik: %s, seh. %s-%s ---\nFesil: %s\nAcar: %s\n\n%s\n",
      c$source_file%||%"?",c$page_start%||%"?",c$page_end%||%"?",c$chapter%||%"-",paste(head(c$keywords%||%character(0),10),collapse=", "),tx))}
  paste(pts,collapse="\n")
}

# =============================================
# CLAUDE API — TOKEN + VAXT TRACKING
# =============================================
call_claude <- function(prompt){
  key<-Sys.getenv("ANTHROPIC_API_KEY","")
  if(nchar(key)<10) return(list(success=FALSE,error="ANTHROPIC_API_KEY .env-de yoxdur!",time_sec=0,input_tokens=0,output_tokens=0))
  t0 <- proc.time()["elapsed"]
  tryCatch({
    r<-POST(CLAUDE_ENDPOINT,
      add_headers(`x-api-key`=key,`anthropic-version`="2023-06-01",`content-type`="application/json"),
      body=toJSON(list(model=CLAUDE_MODEL,max_tokens=4096,
        messages=list(list(role="user",content=prompt))),auto_unbox=TRUE),
      encode="raw",timeout(180))
    elapsed <- round(as.numeric(proc.time()["elapsed"] - t0), 1)
    res<-content(r,"parsed",encoding="UTF-8")
    inp_tok <- res$usage$input_tokens %||% 0
    out_tok <- res$usage$output_tokens %||% 0
    if(r$status_code==200) list(success=TRUE, text=res$content[[1]]$text,
      time_sec=elapsed, input_tokens=inp_tok, output_tokens=out_tok)
    else list(success=FALSE, error=res$error$message%||%paste("HTTP",r$status_code),
      time_sec=elapsed, input_tokens=inp_tok, output_tokens=out_tok)
  },error=function(e){
    elapsed <- round(as.numeric(proc.time()["elapsed"] - t0), 1)
    list(success=FALSE,error=e$message,time_sec=elapsed,input_tokens=0,output_tokens=0)
  })
}

# =============================================
# FAYL SAXLAMA: HTML + DOCX
# =============================================
save_result <- function(html_content, folder, grade, topic, type_label) {
  ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
  safe_topic <- gsub("[^a-zA-Z0-9_-]", "_", iconv(topic, to="ASCII//TRANSLIT"))
  safe_topic <- substr(safe_topic, 1, 40)
  base_name <- sprintf("sinif%d_%s_%s_%s", grade, safe_topic, type_label, ts)

  full_html <- paste0('<!DOCTYPE html><html lang="az"><head><meta charset="UTF-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '<title>ARTI 2026 - Sinif ', grade, ' - ', topic, '</title>',
    HTML5_CSS, '</head><body><div class="ai-output">', html_content,
    '</div><div class="arti-footer">ARTI 2026 | ', base_name, '</div></body></html>')

  # HTML saxla
  html_path <- file.path(folder, paste0(base_name, ".html"))
  writeLines(full_html, html_path, useBytes=TRUE)
  message("HTML saxlandi: ", html_path)

  # DOCX (pandoc ile)
  docx_path <- file.path(folder, paste0(base_name, ".docx"))
  tryCatch({
    tmp_html <- tempfile(fileext=".html")
    writeLines(full_html, tmp_html, useBytes=TRUE)
    pandoc <- Sys.which("pandoc")
    if(nchar(pandoc) == 0) pandoc <- file.path(Sys.getenv("RSTUDIO_PANDOC",""), "pandoc")
    if(nchar(pandoc) > 0 && file.exists(pandoc)) {
      system2(pandoc, c("-f","html","-t","docx","-o",docx_path,tmp_html), stderr=FALSE, stdout=FALSE)
      if(file.exists(docx_path)) message("DOCX saxlandi: ", docx_path)
      else message("DOCX yaradila bilmedi")
    } else {
      # pandoc yoxdursa rmarkdown-dan istifade et
      tryCatch({
        pandoc2 <- rmarkdown::find_pandoc()$dir
        if(!is.null(pandoc2)) {
          system2(file.path(pandoc2,"pandoc"), c("-f","html","-t","docx","-o",docx_path,tmp_html), stderr=FALSE, stdout=FALSE)
          if(file.exists(docx_path)) message("DOCX saxlandi (rmarkdown pandoc): ", docx_path)
        }
      }, error=function(e2) message("DOCX: pandoc tapilmadi, yalniz HTML saxlandi"))
    }
    unlink(tmp_html)
  }, error=function(e) message("DOCX xetasi: ", e$message))

  list(html=html_path, docx=if(file.exists(docx_path)) docx_path else NA)
}

# =============================================
# STATS BAR HTML (token + vaxt + fayl)
# =============================================
make_stats_bar <- function(time_sec, input_tokens, output_tokens, html_path, docx_path) {
  total_tok <- input_tokens + output_tokens
  # Approximate cost: Sonnet input=$3/M, output=$15/M
  cost_usd <- round((input_tokens * 3 + output_tokens * 15) / 1000000, 4)

  docx_info <- if(!is.na(docx_path) && file.exists(docx_path)) {
    sprintf('<span style="margin-left:20px;">&#128196; DOCX: %s</span>', basename(docx_path))
  } else ""

  sprintf('<div style="background:linear-gradient(135deg,#1e293b,#334155);color:#e2e8f0;padding:16px 24px;border-radius:12px;margin-top:20px;font-size:1.1em;display:flex;flex-wrap:wrap;gap:20px;align-items:center;">
    <span>&#9201; <strong>Vaxt:</strong> %.1f san</span>
    <span>&#128229; <strong>Giri&#351;:</strong> %s token</span>
    <span>&#128228; <strong>&#199;&#305;x&#305;&#351;:</strong> %s token</span>
    <span>&#128202; <strong>C&#601;mi:</strong> %s token</span>
    <span>&#128176; <strong>T&#601;xmini:</strong> $%s</span>
    <span style="margin-left:auto;">&#128196; HTML: %s</span>
    %s
  </div>', time_sec,
    formatC(input_tokens, format="d", big.mark=","),
    formatC(output_tokens, format="d", big.mark=","),
    formatC(total_tok, format="d", big.mark=","),
    cost_usd, basename(html_path), docx_info)
}

# === HTML5 CSS (30% BOYUK) ===
HTML5_CSS <- '<style>
@import url("https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&family=JetBrains+Mono&display=swap");
.ai-output{font-family:"Noto Sans",sans-serif;color:#1a1a2e;font-size:1.30em;line-height:1.90}
.test-header,.lesson-header{background:linear-gradient(135deg,#0a1628,#1a365d,#2d3748);color:#fff;padding:32px;border-radius:14px;margin-bottom:28px;box-shadow:0 8px 32px rgba(0,0,0,.18);position:relative;overflow:hidden}
.test-header::before,.lesson-header::before{content:"";position:absolute;top:-50%;right:-20%;width:400px;height:400px;background:radial-gradient(circle,rgba(59,130,246,.15) 0%,transparent 70%);border-radius:50%}
.test-header h1,.lesson-header h1{font-size:2.10em;font-weight:700;margin:0 0 18px}
.meta-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px}
.meta-item{background:rgba(255,255,255,.08);padding:10px 16px;border-radius:8px;border-left:3px solid #3b82f6;font-size:1.17em}
.meta-item .label{font-weight:700;color:#93c5fd}
.objectives{margin-top:18px;background:rgba(255,255,255,.06);padding:16px 20px;border-radius:10px}
.objectives h3{margin:0 0 10px;color:#fbbf24;font-size:1.37em}
.objectives li{margin-bottom:6px;color:#e2e8f0;font-size:1.17em}
.question-block{background:#fff;border-radius:14px;padding:24px;margin-bottom:20px;box-shadow:0 2px 12px rgba(0,0,0,.06);border-left:5px solid #94a3b8;transition:transform .2s}
.question-block:hover{transform:translateY(-2px);box-shadow:0 6px 24px rgba(0,0,0,.10)}
.bloom-xatirlama{border-left-color:#78350f}.bloom-anlama{border-left-color:#15803d}.bloom-tetbiqetme{border-left-color:#1d4ed8}
.bloom-tehlil{border-left-color:#a16207}.bloom-qiymetlendirme{border-left-color:#c2410c}.bloom-yaratma{border-left-color:#dc2626}
.question-header{display:flex;gap:10px;margin-bottom:14px;flex-wrap:wrap}
.bloom-badge,.dok-badge{display:inline-block;padding:5px 14px;border-radius:18px;font-size:1.04em;font-weight:700}
.bloom-badge{background:#eff6ff;color:#1e40af}.dok-badge{background:#fef3c7;color:#92400e}
.question-text{font-size:1.33em;margin-bottom:16px;line-height:1.95}
.options{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px}
.option{background:#f8fafc;padding:12px 18px;border-radius:8px;border:1px solid #e2e8f0;font-size:1.24em}
.answer-box{background:linear-gradient(135deg,#f0fdf4,#ecfdf5);border:1px solid #86efac;border-radius:10px;padding:18px}
.answer-box .answer{font-weight:700;color:#15803d;font-size:1.30em;margin-bottom:8px}
.answer-box .solution{color:#374151;margin-bottom:6px;white-space:pre-wrap;font-size:1.20em}
.answer-box .textbook-ref{color:#1d4ed8;font-weight:600;font-size:1.17em}
.answer-box .difficulty{color:#6b7280;font-size:1.10em}
.phase{background:#fff;border-radius:14px;padding:24px;margin-bottom:18px;box-shadow:0 2px 12px rgba(0,0,0,.06);border-left:5px solid #3b82f6}
.phase-1{border-left-color:#f59e0b}.phase-2{border-left-color:#3b82f6}.phase-3{border-left-color:#10b981}.phase-4{border-left-color:#8b5cf6}.phase-5{border-left-color:#ef4444}
.phase-header{display:flex;align-items:center;gap:12px;margin-bottom:16px}
.phase-header h3{margin:0;font-size:1.43em;flex-grow:1}
.phase-time{background:#f1f5f9;padding:5px 14px;border-radius:16px;font-size:1.07em;font-weight:600;color:#475569}
.teacher-activity,.student-activity,.phase .textbook-ref,.assessment{padding:10px 16px;margin-bottom:8px;border-radius:8px;font-size:1.20em}
.teacher-activity{background:#eff6ff;border-left:3px solid #3b82f6}
.student-activity{background:#f0fdf4;border-left:3px solid #22c55e}
.phase .textbook-ref{background:#fefce8;border-left:3px solid #eab308;color:#854d0e;font-weight:600}
.assessment{background:#faf5ff;border-left:3px solid #a855f7}
.differentiation{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin:12px 0}
.diff-level{padding:14px;border-radius:10px;font-size:1.17em}
.diff-base{background:#f0fdf4;border:1px solid #86efac}.diff-mid{background:#fffbeb;border:1px solid #fde68a}.diff-high{background:#fef2f2;border:1px solid #fca5a5}
.stats-block,.analysis-block{background:linear-gradient(135deg,#0a1628,#1e293b);color:#e2e8f0;padding:24px;border-radius:14px;margin-top:24px}
.stats-block h3,.analysis-block h3{margin:0 0 16px;color:#fbbf24;font-size:1.43em}
.stat-row{padding:8px 0;border-bottom:1px solid rgba(255,255,255,.08);font-size:1.17em}
.stat-row:last-child{border-bottom:none}
.arti-footer{text-align:center;margin-top:30px;padding:16px;color:#94a3b8;font-size:1.04em;border-top:2px solid #e2e8f0}
@media print{.answer-box,.question-block,.phase{page-break-inside:avoid}.ai-output{font-size:12pt}}
</style>'

# === PROMPT BUILDERS ===
build_test_prompt <- function(grade,topic,standard,context,count,blooms,dok){paste0(
'Sen Azerbaijan Riyaziyyat muellimler ucun test tapshiriqlari yaradan ekspert AI-san.
SINIF: ',grade,' | MOVZU: ',topic,' | STANDART: ',standard,' | SAY: ',count,' | BLOOM: ',paste(blooms,collapse=", "),' | DOK: ',dok,'
DERSLIKDEN KONTEKST:\n',context,'
TELIMATLAR: ',count,' tapshiriq yarat. NETICENI TAM HTML FORMATINDA VER (markdown yox).
QAYDALAR: 1)Derslik terminologiyasi 2)Sehife istinadi 3)Real heyat:Baki,manat,Xezer 4)Cavab+hell 5)Rubrika(aciq) 6)Distraktor analizi
HTML: <div class="test-header"><h1>Riyaziyyat Test</h1><div class="meta-grid">
<div class="meta-item"><span class="label">Sinif:</span> ',grade,'-ci</div>
<div class="meta-item"><span class="label">Movzu:</span> ',topic,'</div>
<div class="meta-item"><span class="label">Standart:</span> ',standard,'</div>
<div class="meta-item"><span class="label">Say:</span> ',count,'</div></div></div>
Her tapshiriq: <div class="question-block bloom-[seviyye]">
<div class="question-header"><span class="bloom-badge">[BLOOM]</span><span class="dok-badge">DOK-[N]</span></div>
<div class="question-text"><strong>[N].</strong> [metn]</div>
<div class="options"><div class="option">A)...</div>...</div>
<div class="answer-box"><div class="answer">Cavab: [X]</div><div class="solution">Hell: ...</div>
<div class="textbook-ref">Derslik: seh. XX</div><div class="difficulty">Cetinlik: ... | deq | bal</div></div></div>
Sonda: <div class="stats-block"><h3>Statistika</h3><div class="stat-row">Bloom...</div><div class="stat-row">DOK...</div></div>')}

build_lesson_prompt <- function(grade,topic,standard,context,duration,blooms,dok){
  m1<-as.integer(duration*.10);m2<-as.integer(duration*.30);m3<-as.integer(duration*.25);m4<-as.integer(duration*.25);m5<-as.integer(duration*.10)
  paste0('Sen Finlandiya+Sinqapur modelinde ders planlari hazirlayan metodist AI-san.
SINIF: ',grade,' | MOVZU: ',topic,' | STANDART: ',standard,' | MUDDET: ',duration,' deq | BLOOM: ',paste(blooms,collapse=", "),' | DOK: ',dok,'
DERSLIKDEN KONTEKST:\n',context,'
TELIMATLAR: ',duration,' deqiqelik ders plani yarat. TAM HTML FORMATINDA VER.
QAYDALAR: 1)Derslik terminologiya+tapshiriq nomreleri 2)Sinqapur CPA 3)Diferensiasiya:Baza/Orta/Yuksek
HTML: <div class="lesson-header"><h1>Ders Plani</h1><div class="meta-grid">
<div class="meta-item"><span class="label">Sinif:</span> ',grade,'-ci</div>
<div class="meta-item"><span class="label">Movzu:</span> ',topic,'</div>
<div class="meta-item"><span class="label">Muddet:</span> ',duration,' deq</div>
<div class="meta-item"><span class="label">Standart:</span> ',standard,'</div></div>
<div class="objectives"><h3>Telim Neticeleri</h3><ul><li>[Bilik]</li><li>[Bacariq]</li><li>[Tetbiq]</li></ul></div></div>
5 merhele: 1.Motivasiya(',m1,'deq) 2.Yeni bilik(',m2,'deq)-CPA 3.Birge(',m3,'deq) 4.Musteqil(',m4,'deq)-diferensiasiya 5.Yekun(',m5,'deq)
Her merhele: <div class="phase phase-N"><div class="phase-header"><h3>MERHELE N: [AD]</h3><span class="phase-time">[X] deq</span></div>
<div class="teacher-activity">Muellim: ...</div><div class="student-activity">Shagird: ...</div>
<div class="textbook-ref">Derslik: seh. XX</div><div class="assessment">Qiymetlendirme: ...</div></div>
Sonda: <div class="analysis-block"><h3>Ders Analizi</h3><div class="stat-row">Bloom...</div><div class="stat-row">Zaman...</div></div>')}

# ====================================================================
# UI
# ====================================================================
ui <- dashboardPage(skin="blue",
  dashboardHeader(title=span(icon("graduation-cap")," Muellim Agent v3"),titleWidth=300),
  dashboardSidebar(width=280,sidebarMenu(id="tabs",
    menuItem("Ana Sehife",tabName="home",icon=icon("home")),
    menuItem("Ders Planlari",icon=icon("book"),menuSubItem("Yeni Plan",tabName="lesson_new"),menuSubItem("Planlarim",tabName="lesson_list")),
    menuItem("Qiymetlendirme",icon=icon("clipboard-check"),menuSubItem("Test Yarat",tabName="test_create"),menuSubItem("CAT Test",tabName="cat_test"),menuSubItem("Netice Analizi",tabName="analysis")),
    menuItem("Shagird Analizi",icon=icon("users"),menuSubItem("Profiller",tabName="student_profiles"),menuSubItem("Risk Qruplari",tabName="risk_groups"),menuSubItem("Inklyuziv",tabName="inclusive")),
    menuItem("Senedler",tabName="documents",icon=icon("file-alt")),
    menuItem("Kommunikasiya",tabName="communication",icon=icon("comments")),
    menuItem("Standartlar",tabName="standards",icon=icon("list-check")),
    menuItem("Statistika",tabName="statistics",icon=icon("chart-bar")),
    hr(),div(p(style="padding:10px;color:#b8c7ce;font-size:11px;","ARTI 2026 (c) Tariyel Talibov"))
  )),
  dashboardBody(tags$head(tags$style(HTML("
    .content-wrapper{background:#f4f6f9}.box{border-top:3px solid #3c8dbc}
    .skin-blue .main-header .navbar{background:#003366}.skin-blue .main-header .logo{background:#002244}
    .btn-generate{font-size:1.1em!important;padding:12px 24px!important;font-weight:700!important}
    .ai-loading{text-align:center;padding:50px}
    .ai-loading .spinner{width:50px;height:50px;border:4px solid #e2e8f0;border-top-color:#3b82f6;border-radius:50%;animation:spin .8s linear infinite;margin:0 auto 16px}
    @keyframes spin{to{transform:rotate(360deg)}}
    .selectize-dropdown{max-height:400px!important}.selectize-dropdown-content{max-height:380px!important}
    .timer-display{font-size:1.3em;color:#3b82f6;font-weight:700;padding:10px;text-align:center}
  "))),
  tabItems(
    tabItem(tabName="home",
      fluidRow(infoBox("Ders Planlari",textOutput("plan_count"),icon=icon("book"),color="blue",width=3),
        infoBox("Testler",textOutput("test_count"),icon=icon("clipboard"),color="green",width=3),
        infoBox("Shagirdler",textOutput("student_count"),icon=icon("users"),color="yellow",width=3),
        infoBox("Risk",textOutput("alert_count"),icon=icon("exclamation-triangle"),color="red",width=3)),
      fluidRow(box(title="Sinif Performansi",width=6,solidHeader=TRUE,status="info",plotlyOutput("class_perf",height="300px")),
        box(title="Seviyye Paylamasi",width=6,solidHeader=TRUE,plotlyOutput("level_dist",height="300px")))),
    # --- LESSON ---
    tabItem(tabName="lesson_new",fluidRow(box(title="AI ile Ders Plani",width=12,solidHeader=TRUE,status="primary",
      fluidRow(column(2,selectInput("lp_grade","Sinif:",choices=as.character(1:11),selected="6")),
        column(5,uiOutput("lp_standard_ui")),column(3,uiOutput("lp_topic_ui")),
        column(2,numericInput("lp_duration","Muddet:",value=45))),
      fluidRow(column(3,checkboxGroupInput("lp_bloom","Bloom:",choices=c("Xatirlama","Anlama","Tetbiqetme","Tehlil","Qiymetlendirme","Yaratma"),selected=c("Anlama","Tetbiqetme","Tehlil"))),
        column(2,sliderInput("lp_dok","DOK:",min=1,max=4,value=2)),
        column(3,checkboxInput("lp_inclusive","Inklyuziv",FALSE)),
        column(2,actionButton("lp_generate","AI ile Yarat",class="btn-primary btn-lg btn-generate",style="margin-top:25px;")),
        column(2,uiOutput("lp_timer_ui"))),
      hr(),uiOutput("lp_result")))),
    # --- TEST ---
    tabItem(tabName="test_create",fluidRow(box(title="AI Test Generatoru",width=12,solidHeader=TRUE,status="success",
      fluidRow(column(2,selectInput("tc_grade","Sinif:",choices=as.character(1:11),selected="6")),
        column(5,uiOutput("tc_standard_ui")),column(3,uiOutput("tc_topic_ui")),
        column(2,numericInput("tc_count","Say:",value=12,min=5,max=30))),
      fluidRow(column(3,checkboxGroupInput("tc_bloom","Bloom:",choices=c("Xatirlama","Anlama","Tetbiqetme","Tehlil","Qiymetlendirme","Yaratma"),
        selected=c("Xatirlama","Anlama","Tetbiqetme","Tehlil","Qiymetlendirme"))),
        column(2,sliderInput("tc_dok","DOK:",min=1,max=4,value=3)),
        column(3,sliderInput("tc_diff","Cetinlik:",min=0.1,max=1.0,value=c(0.3,0.8),step=0.1)),
        column(2,actionButton("tc_generate","Test Yarat",class="btn-success btn-lg btn-generate",style="margin-top:25px;")),
        column(2,uiOutput("tc_timer_ui"))),
      hr(),uiOutput("tc_result")))),
    # --- OTHER TABS (minimal) ---
    tabItem(tabName="analysis",fluidRow(box(title="Psixometrik Analiz",width=12,solidHeader=TRUE,status="warning",p("Analiz modulu hazirlanir...")))),
    tabItem(tabName="student_profiles",fluidRow(box(title="Shagird Profilleri",width=12,solidHeader=TRUE,p("Profil modulu hazirlanir...")))),
    tabItem(tabName="risk_groups",fluidRow(box(title="Risk Qruplari",width=12,solidHeader=TRUE,status="danger",p("Risk modulu hazirlanir...")))),
    tabItem(tabName="standards",fluidRow(box(title="Standartlar",width=12,solidHeader=TRUE,
      fluidRow(column(4,selectInput("st_grade2","Sinif:",choices=as.character(1:11),selected="6")),column(4,actionButton("st_load2","Yukle",class="btn-primary",style="margin-top:25px;"))),hr(),DTOutput("stds_table2")))),
    tabItem(tabName="documents",fluidRow(box(title="Sened Generatoru",width=12,solidHeader=TRUE,p("Sened modulu hazirlanir...")))),
    tabItem(tabName="communication",fluidRow(box(title="Kommunikasiya",width=12,solidHeader=TRUE,p("Mesaj modulu hazirlanir...")))),
    tabItem(tabName="statistics",fluidRow(box(title="Mekteb Dashboard",width=12,solidHeader=TRUE,status="primary",
      fluidRow(column(6,plotlyOutput("class_perf2",height="300px")),column(6,plotlyOutput("level_dist2",height="300px"))))))
  ))
)

# ====================================================================
# SERVER
# ====================================================================
server <- function(input,output,session){
  output$lp_standard_ui <- renderUI(selectInput("lp_standard","Standart:",choices=get_standards_dropdown(input$lp_grade),width="100%"))
  output$tc_standard_ui <- renderUI(selectInput("tc_standard","Standart:",choices=get_standards_dropdown(input$tc_grade),width="100%"))
  output$lp_topic_ui <- renderUI(selectizeInput("lp_topic","Movzu:",choices=get_topics_for_grade(input$lp_grade),width="100%",options=list(placeholder="Movzu secin...",create=TRUE)))
  output$tc_topic_ui <- renderUI(selectizeInput("tc_topic","Movzu:",choices=get_topics_for_grade(input$tc_grade),width="100%",options=list(placeholder="Movzu secin...",create=TRUE)))

  # Reactive timer values
  lp_start <- reactiveVal(NULL)
  tc_start <- reactiveVal(NULL)

  # === LESSON GENERATE ===
  observeEvent(input$lp_generate,{
    req(input$lp_grade,input$lp_topic,input$lp_standard)
    gr<-as.integer(input$lp_grade);tp<-input$lp_topic;st<-input$lp_standard;dur<-input$lp_duration;bl<-input$lp_bloom;dk<-input$lp_dok
    lp_start(proc.time()["elapsed"])
    output$lp_timer_ui <- renderUI(tags$div(class="timer-display","⏳ Yaradilir..."))
    output$lp_result <- renderUI(tags$div(class="ai-loading",tags$div(class="spinner"),
      tags$p(style="font-size:1.2em;","AI ders plani yaradir..."),
      tags$p(style="color:#94a3b8;",sprintf("Sinif %d | %s | %d deq",gr,tp,dur))))
    ctx<-build_context(gr,tp); pr<-build_lesson_prompt(gr,tp,st,ctx,dur,bl,dk); res<-call_claude(pr)
    if(res$success){
      saved <- save_result(res$text, DERS_DIR, gr, tp, "ders_plani")
      stats_html <- make_stats_bar(res$time_sec, res$input_tokens, res$output_tokens, saved$html, saved$docx%||%"")
      output$lp_timer_ui <- renderUI(tags$div(style="font-size:1.1em;color:#10b981;font-weight:700;padding:10px;",
        sprintf("✅ %.1f san | %s token", res$time_sec, formatC(res$input_tokens+res$output_tokens,format="d",big.mark=","))))
      output$lp_result <- renderUI(tagList(HTML(HTML5_CSS),tags$div(class="ai-output",HTML(res$text)),HTML(stats_html),
        tags$div(class="arti-footer",sprintf("ARTI 2026 | Sinif %d | %s | %d deq",gr,tp,dur))))
    } else {
      output$lp_timer_ui <- renderUI(tags$div(style="color:#dc2626;font-weight:700;padding:10px;",sprintf("❌ %.1f san",res$time_sec)))
      output$lp_result <- renderUI(tags$div(style="padding:30px;color:#dc2626;",tags$h3("Xeta"),tags$p(res$error)))
    }
  })

  # === TEST GENERATE ===
  observeEvent(input$tc_generate,{
    req(input$tc_grade,input$tc_topic,input$tc_standard)
    gr<-as.integer(input$tc_grade);tp<-input$tc_topic;st<-input$tc_standard;cnt<-input$tc_count;bl<-input$tc_bloom;dk<-input$tc_dok
    tc_start(proc.time()["elapsed"])
    output$tc_timer_ui <- renderUI(tags$div(class="timer-display","⏳ Yaradilir..."))
    output$tc_result <- renderUI(tags$div(class="ai-loading",tags$div(class="spinner"),
      tags$p(style="font-size:1.2em;","AI test yaradir..."),
      tags$p(style="color:#94a3b8;",sprintf("Sinif %d | %s | %d tapshiriq",gr,tp,cnt))))
    ctx<-build_context(gr,tp); pr<-build_test_prompt(gr,tp,st,ctx,cnt,bl,dk); res<-call_claude(pr)
    if(res$success){
      saved <- save_result(res$text, TEST_DIR, gr, tp, "test")
      stats_html <- make_stats_bar(res$time_sec, res$input_tokens, res$output_tokens, saved$html, saved$docx%||%"")
      output$tc_timer_ui <- renderUI(tags$div(style="font-size:1.1em;color:#10b981;font-weight:700;padding:10px;",
        sprintf("✅ %.1f san | %s token", res$time_sec, formatC(res$input_tokens+res$output_tokens,format="d",big.mark=","))))
      output$tc_result <- renderUI(tagList(HTML(HTML5_CSS),tags$div(class="ai-output",HTML(res$text)),HTML(stats_html),
        tags$div(class="arti-footer",sprintf("ARTI 2026 | Sinif %d | %s | %d tapshiriq",gr,tp,cnt))))
    } else {
      output$tc_timer_ui <- renderUI(tags$div(style="color:#dc2626;font-weight:700;padding:10px;",sprintf("❌ %.1f san",res$time_sec)))
      output$tc_result <- renderUI(tags$div(style="padding:30px;color:#dc2626;",tags$h3("Xeta"),tags$p(res$error)))
    }
  })

  # === STANDARDS TABLE ===
  observeEvent(input$st_load2,{
    stds <- ALL_STANDARDS[[as.character(input$st_grade2)]]
    if(!is.null(stds)&&length(stds)>0){
      df <- do.call(rbind, lapply(stds, function(s) data.frame(Kod=s$kod,Sahe=s$sahe,Standart=s$metn,Bloom=s$bloom,DOK=s$dok,stringsAsFactors=FALSE)))
      output$stds_table2 <- renderDT(datatable(df,options=list(pageLength=20),colnames=c("Kod","Sahe","Standart","Bloom","DOK")))
    }
  })

  # === HOME ===
  output$plan_count <- renderText(length(list.files(DERS_DIR,pattern="\\.html$")))
  output$test_count <- renderText(length(list.files(TEST_DIR,pattern="\\.html$")))
  output$student_count <- renderText("--")
  output$alert_count <- renderText("0")
  output$class_perf <- renderPlotly(plot_ly(x=c("5A","5B","6A","6B","7A"),y=c(72,68,75,80,65),type="bar",marker=list(color=c("#3c8dbc","#00a65a","#f39c12","#dd4b39","#605ca8")))%>%layout(xaxis=list(title="Sinif"),yaxis=list(title="Bal")))
  output$level_dist <- renderPlotly(plot_ly(x=c("Zeif","Orta","Yuksek","Ela"),y=c(15,45,30,10),type="bar",marker=list(color=c("#dd4b39","#f39c12","#00a65a","#3c8dbc")))%>%layout(xaxis=list(title="Seviyye"),yaxis=list(title="Say")))
  output$class_perf2 <- renderPlotly(plot_ly(x=c("5A","5B","6A","6B","7A"),y=c(72,68,75,80,65),type="bar")%>%layout(title="Sinif Performansi"))
  output$level_dist2 <- renderPlotly(plot_ly(x=c("Zeif","Orta","Yuksek","Ela"),y=c(15,45,30,10),type="bar")%>%layout(title="Seviyye"))
}

shinyApp(ui=ui,server=server,options=list(host="127.0.0.1",port=as.integer(Sys.getenv("SHINY_PORT","4040")),launch.browser=TRUE))