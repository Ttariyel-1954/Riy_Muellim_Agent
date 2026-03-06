# ══════════════════════════════════════════════════════════
# Riy_Muellim_Agent v3.2 — Tam Yenidən Yazılmış
# ARTI 2026 (c) Tariyel Talibov
# ══════════════════════════════════════════════════════════

library(shiny)
library(shinydashboard)
library(DT)
library(httr)
library(jsonlite)

PLOTLY_OK <- tryCatch({ library(plotly); TRUE }, error = function(e) {
  message("plotly yuklenmedi: ", e$message); FALSE })

LOCAL_DIR <- normalizePath("~/Desktop/Riy_Muellim_Agent", mustWork = FALSE)
APP_DIR   <- if (dir.exists(LOCAL_DIR)) LOCAL_DIR else getwd()

env_file <- file.path(APP_DIR, ".env")
if (file.exists(env_file)) {
  for (line in readLines(env_file, warn = FALSE)) {
    line <- trimws(line)
    if (nchar(line) > 0 && !startsWith(line, "#") && grepl("=", line)) {
      p <- strsplit(line, "=", fixed = TRUE)[[1]]
      do.call(Sys.setenv, setNames(list(trimws(paste(p[-1], collapse = "="))), trimws(p[1])))
    }
  }
}

DATA_DIR       <- file.path(APP_DIR, "derslikler")
CHUNKS_DIR     <- file.path(DATA_DIR, "chunks")
CLAUDE_MODEL   <- Sys.getenv("DEFAULT_AI_MODEL", "claude-sonnet-4-20250514")
CLAUDE_ENDPOINT <- "https://api.anthropic.com/v1/messages"
DERS_DIR <- file.path(APP_DIR, "Ders_planlari")
TEST_DIR <- file.path(APP_DIR, "Testler")
MSG_DIR  <- file.path(APP_DIR, "Mesajlar")
dir.create(DERS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TEST_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(MSG_DIR,  showWarnings = FALSE, recursive = TRUE)

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (is.character(x) && all(nchar(x) == 0))) y else x

# ═══════════════ STANDARTLAR ═══════════════
ALL_STANDARDS <- tryCatch(
  fromJSON(file.path(DATA_DIR, "standards.json"), simplifyVector = FALSE),
  error = function(e) { message("standards.json: ", e$message); list() })

get_standards_dropdown <- function(grade) {
  stds <- ALL_STANDARDS[[as.character(grade)]]
  if (is.null(stds) || length(stds) == 0) return(c("Standart tapilmadi" = "---"))
  ch <- character(0)
  for (s in stds) {
    kod <- s$kod %||% "?"; sahe <- s$sahe %||% "?"; metn <- s$metn %||% "?"
    label <- paste0(kod, "  [", sahe, "]  ", metn)
    val <- paste0(kod, " - ", metn)
    ch <- c(ch, setNames(val, label))
  }
  ch
}

# ═══════════════ MOVZULAR ═══════════════
ALL_TOPICS <- tryCatch(
  fromJSON(file.path(DATA_DIR, "topics.json"), simplifyVector = FALSE),
  error = function(e) { message("topics.json: ", e$message); list() })

get_topics_for_grade <- function(grade) {
  gd <- ALL_TOPICS[[as.character(grade)]]
  if (is.null(gd)) return(c("Movzu tapilmadi" = "---"))
  ch <- character(0)
  for (b in gd$bolmeler) {
    bn <- b$bolme %||% "?"
    for (m in b$movzular) {
      ad <- m$ad %||% "?"; seh <- m$seh %||% "?"
      label <- paste0("[", bn, "]  ", ad, "  (seh. ", seh, ")")
      ch <- c(ch, setNames(ad, label))
    }
  }
  if (length(ch) == 0) return(c("Movzu tapilmadi" = "---"))
  ch
}

# ═══════════════ CHUNK FUNCTIONS ═══════════════
load_chunks_for_grade <- function(gr) {
  fs <- list.files(CHUNKS_DIR, pattern = sprintf("sinif%d_.*\\.json$", gr), full.names = TRUE)
  out <- list()
  for (f in fs) tryCatch({ out <- c(out, fromJSON(f, simplifyVector = FALSE)) }, error = function(e) {})
  out
}

search_chunks <- function(gr, topic, mx = 3) {
  chs <- load_chunks_for_grade(gr)
  if (length(chs) == 0) return(list())
  tl <- tolower(topic); tw <- strsplit(tl, "\\s+")[[1]]; tw <- tw[nchar(tw) >= 3]
  sc <- list()
  for (ch in chs) {
    s <- 0
    bl <- tolower(paste(ch$text %||% "", ch$topic %||% "", ch$chapter %||% "",
                        paste(ch$keywords %||% character(0), collapse = " ")))
    if (grepl(tl, bl, fixed = TRUE)) s <- s + 10
    for (w in tw) s <- s + min(length(gregexpr(w, bl, fixed = TRUE)[[1]]), 5)
    if (nchar(ch$chapter %||% "") > 0 && grepl(tl, tolower(ch$chapter), fixed = TRUE)) s <- s + 15
    if (s > 0) sc <- c(sc, list(list(score = s, chunk = ch)))
  }
  sc <- sc[order(-sapply(sc, function(x) x$score))]
  lapply(head(sc, mx), function(x) x$chunk)
}

build_context <- function(gr, topic) {
  res <- search_chunks(gr, topic)
  if (length(res) == 0) return(sprintf("[Sinif %d, '%s' - kontekst yoxdur]", gr, topic))
  pts <- character(0)
  for (ch in res) {
    tx <- ch$text %||% ""
    if (nchar(tx) > 4000) tx <- paste0(substr(tx, 1, 4000), "\n...")
    pts <- c(pts, sprintf("\n--- Derslik: %s, seh. %s-%s ---\nFesil: %s\nAcar: %s\n\n%s\n",
      ch$source_file %||% "?", ch$page_start %||% "?", ch$page_end %||% "?",
      ch$chapter %||% "-", paste(head(ch$keywords %||% character(0), 10), collapse = ", "), tx))
  }
  paste(pts, collapse = "\n")
}

# ══════════════════════════════════════════════
# CLAUDE API
# ══════════════════════════════════════════════
call_claude <- function(prompt) {
  key <- Sys.getenv("ANTHROPIC_API_KEY", "")
  if (nchar(key) < 10) return(list(success = FALSE, error = "ANTHROPIC_API_KEY .env faylinda tapilmadi!",
                                    time_sec = 0, input_tokens = 0, output_tokens = 0))
  t0 <- proc.time()["elapsed"]
  tryCatch({
    resp <- POST(CLAUDE_ENDPOINT,
      add_headers(`x-api-key` = key, `anthropic-version` = "2023-06-01", `content-type` = "application/json"),
      body = toJSON(list(model = CLAUDE_MODEL, max_tokens = if (grepl("haiku", CLAUDE_MODEL)) 4096L else 16384L,
                         messages = list(list(role = "user", content = prompt))), auto_unbox = TRUE),
      encode = "raw", timeout(300))
    elapsed <- round(as.numeric(proc.time()["elapsed"] - t0), 1)
    res <- content(resp, "parsed", encoding = "UTF-8")
    inp_tok <- as.integer(res$usage$input_tokens %||% 0)
    out_tok <- as.integer(res$usage$output_tokens %||% 0)
    if (resp$status_code == 200) {
      txt <- if (length(res$content) > 0) res$content[[1]]$text %||% "" else ""
      list(success = TRUE, text = txt, time_sec = elapsed, input_tokens = inp_tok, output_tokens = out_tok)
    } else {
      err_msg <- if (!is.null(res$error)) res$error$message %||% paste("HTTP", resp$status_code) else "Bilinmeyen xeta"
      list(success = FALSE, error = err_msg, time_sec = elapsed, input_tokens = inp_tok, output_tokens = out_tok)
    }
  }, error = function(e) {
    elapsed <- round(as.numeric(proc.time()["elapsed"] - t0), 1)
    list(success = FALSE, error = e$message, time_sec = elapsed, input_tokens = 0, output_tokens = 0)
  })
}

# ══════════════════════════════════════════════
# FAYL SAXLAMA
# ══════════════════════════════════════════════
save_result <- function(html_body, css_text, folder, grade, topic, type_label) {
  ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
  safe_topic <- substr(gsub("[^a-zA-Z0-9_-]", "_", topic), 1, 40)
  base_name <- sprintf("sinif%d_%s_%s_%s", grade, safe_topic, type_label, ts)
  full_html <- paste0('<!DOCTYPE html>\n<html lang="az"><head><meta charset="UTF-8">\n',
    '<meta name="viewport" content="width=device-width,initial-scale=1.0">\n',
    '<title>ARTI 2026 | Sinif ', grade, ' | ', topic, '</title>\n',
    css_text, '\n</head><body>\n<div class="ai-output">\n', html_body, '\n</div>\n',
    '<div class="arti-footer">ARTI 2026 | ', format(Sys.time(), "%d.%m.%Y %H:%M"), ' | ', base_name, '</div>\n',
    '</body></html>')
  html_path <- file.path(folder, paste0(base_name, ".html"))
  writeLines(full_html, html_path, useBytes = TRUE)
  docx_path <- file.path(folder, paste0(base_name, ".docx"))
  docx_ok <- FALSE
  tryCatch({
    tmp <- tempfile(fileext = ".html")
    writeLines(full_html, tmp, useBytes = TRUE)
    pan <- Sys.which("pandoc")
    if (nchar(pan) == 0) { rsp <- Sys.getenv("RSTUDIO_PANDOC", ""); if (nchar(rsp) > 0) pan <- file.path(rsp, "pandoc") }
    if (nchar(pan) == 0) tryCatch({ pd <- rmarkdown::find_pandoc(); if (!is.null(pd$dir)) pan <- file.path(pd$dir, "pandoc") }, error = function(e) {})
    if (nchar(pan) > 0 && file.exists(pan)) {
      system2(pan, c("-f", "html", "-t", "docx", "-o", docx_path, tmp), stderr = FALSE, stdout = FALSE)
      if (file.exists(docx_path)) docx_ok <- TRUE
    }
    unlink(tmp)
  }, error = function(e) {})
  list(html = html_path, docx = if (docx_ok) docx_path else NA_character_)
}

# ══════════════════════════════════════════════
# STATS BAR
# ══════════════════════════════════════════════
make_stats_bar <- function(time_sec, input_tokens, output_tokens, saved_files) {
  total <- input_tokens + output_tokens
  cost <- round((input_tokens * 3 + output_tokens * 15) / 1e6, 4)
  html_name <- basename(saved_files$html)
  docx_part <- if (!is.na(saved_files$docx)) paste0(
    '<div style="background:rgba(255,255,255,0.08);padding:8px 16px;border-radius:8px;border-left:3px solid #a78bfa;">',
    'DOCX: ', basename(saved_files$docx), '</div>') else ""
  paste0(
    '<div style="background:linear-gradient(135deg,#0f172a,#1e293b);color:#e2e8f0;padding:20px 28px;border-radius:14px;margin-top:24px;box-shadow:0 4px 20px rgba(0,0,0,0.2);">',
    '<div style="font-size:1.3em;font-weight:700;margin-bottom:14px;color:#fbbf24;">Generasiya Statistikasi</div>',
    '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin-bottom:16px;">',
    '<div style="background:rgba(255,255,255,0.06);padding:12px 16px;border-radius:10px;border-left:3px solid #3b82f6;"><div style="font-size:0.85em;color:#94a3b8;">Vaxt</div><div style="font-size:1.4em;font-weight:700;color:#60a5fa;">', sprintf("%.1f", time_sec), ' san</div></div>',
    '<div style="background:rgba(255,255,255,0.06);padding:12px 16px;border-radius:10px;border-left:3px solid #22c55e;"><div style="font-size:0.85em;color:#94a3b8;">Giris token</div><div style="font-size:1.4em;font-weight:700;color:#4ade80;">', formatC(input_tokens, format = "d", big.mark = ","), '</div></div>',
    '<div style="background:rgba(255,255,255,0.06);padding:12px 16px;border-radius:10px;border-left:3px solid #f59e0b;"><div style="font-size:0.85em;color:#94a3b8;">Cixis token</div><div style="font-size:1.4em;font-weight:700;color:#fbbf24;">', formatC(output_tokens, format = "d", big.mark = ","), '</div></div>',
    '<div style="background:rgba(255,255,255,0.06);padding:12px 16px;border-radius:10px;border-left:3px solid #ef4444;"><div style="font-size:0.85em;color:#94a3b8;">Cemi token</div><div style="font-size:1.4em;font-weight:700;color:#f87171;">', formatC(total, format = "d", big.mark = ","), '</div></div>',
    '<div style="background:rgba(255,255,255,0.06);padding:12px 16px;border-radius:10px;border-left:3px solid #a78bfa;"><div style="font-size:0.85em;color:#94a3b8;">Texmini qiymet</div><div style="font-size:1.4em;font-weight:700;color:#c4b5fd;">$', sprintf("%.4f", cost), '</div></div>',
    '</div><div style="display:flex;flex-wrap:wrap;gap:12px;">',
    '<div style="background:rgba(255,255,255,0.08);padding:8px 16px;border-radius:8px;border-left:3px solid #3b82f6;">HTML: ', html_name, '</div>', docx_part, '</div></div>')
}

# ══════════════════════════════════════════════
# HTML5 CSS
# ══════════════════════════════════════════════
HTML5_CSS <- '<style>
@import url("https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&family=JetBrains+Mono:wght@400;600&display=swap");
.ai-output{font-family:"Noto Sans","Segoe UI",sans-serif;color:#1a1a2e;font-size:1.30em;line-height:1.90;max-width:1100px;margin:0 auto}
.test-header,.lesson-header{background:linear-gradient(135deg,#0a1628,#1a365d,#2d3748);color:#fff;padding:36px;border-radius:16px;margin-bottom:30px;box-shadow:0 8px 32px rgba(0,0,0,.18);position:relative;overflow:hidden}
.test-header::before,.lesson-header::before{content:"";position:absolute;top:-50%;right:-20%;width:400px;height:400px;background:radial-gradient(circle,rgba(59,130,246,.15) 0%,transparent 70%);border-radius:50%}
.test-header h1,.lesson-header h1{font-size:2.10em;font-weight:700;margin:0 0 20px;position:relative}
.meta-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px;position:relative}
.meta-item{background:rgba(255,255,255,.08);padding:12px 18px;border-radius:10px;border-left:3px solid #3b82f6;font-size:1.17em}
.meta-item .label{font-weight:700;color:#93c5fd;margin-right:8px}
.objectives{margin-top:20px;background:rgba(255,255,255,.06);padding:18px 24px;border-radius:12px;border:1px solid rgba(255,255,255,.1)}
.objectives h3{margin:0 0 12px;color:#fbbf24;font-size:1.37em}
.objectives ul{margin:0;padding-left:24px}
.objectives li{margin-bottom:8px;color:#e2e8f0;font-size:1.17em;line-height:1.6}
.question-block{background:#fff;border-radius:16px;padding:28px;margin-bottom:22px;box-shadow:0 2px 16px rgba(0,0,0,.06);border-left:5px solid #94a3b8;transition:all .25s ease}
.question-block:hover{transform:translateY(-3px);box-shadow:0 8px 30px rgba(0,0,0,.12)}
.bloom-xatirlama{border-left-color:#92400e!important}.bloom-anlama{border-left-color:#15803d!important}
.bloom-tetbiqetme{border-left-color:#1d4ed8!important}.bloom-tehlil{border-left-color:#a16207!important}
.bloom-qiymetlendirme{border-left-color:#c2410c!important}.bloom-yaratma{border-left-color:#dc2626!important}
.question-header{display:flex;gap:12px;margin-bottom:16px;flex-wrap:wrap;align-items:center}
.bloom-badge,.dok-badge{display:inline-flex;align-items:center;padding:6px 16px;border-radius:20px;font-size:1.0em;font-weight:700}
.bloom-badge{background:#eff6ff;color:#1e40af;border:1px solid #bfdbfe}
.dok-badge{background:#fef3c7;color:#92400e;border:1px solid #fde68a}
.question-text{font-size:1.33em;margin-bottom:18px;line-height:1.95;color:#1e293b}
.options{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:18px}
.option{background:#f8fafc;padding:14px 20px;border-radius:10px;border:1px solid #e2e8f0;font-size:1.24em;transition:all .2s}
.option:hover{background:#eff6ff;border-color:#93c5fd}
.answer-box{background:linear-gradient(135deg,#f0fdf4,#ecfdf5);border:1px solid #86efac;border-radius:12px;padding:20px;margin-top:12px}
.answer-box .answer{font-weight:700;color:#15803d;font-size:1.30em;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #bbf7d0}
.answer-box .solution{color:#374151;margin-bottom:8px;white-space:pre-wrap;font-size:1.20em;line-height:1.7}
.answer-box .textbook-ref{color:#1d4ed8;font-weight:600;font-size:1.17em;padding:6px 0}
.answer-box .difficulty{color:#6b7280;font-size:1.10em;margin-top:6px}
.answer-box .rubric{margin-top:12px;padding:14px;background:#fffbeb;border-radius:10px;border:1px solid #fde68a;font-size:1.14em}
.answer-box .distractors{margin-top:10px;padding:14px;background:#faf5ff;border-radius:10px;border:1px solid #d8b4fe;font-size:1.10em}
.phase{background:#fff;border-radius:16px;padding:28px;margin-bottom:20px;box-shadow:0 2px 16px rgba(0,0,0,.06);border-left:5px solid #3b82f6;transition:all .25s ease}
.phase:hover{box-shadow:0 6px 24px rgba(0,0,0,.10)}
.phase-1{border-left-color:#f59e0b}.phase-2{border-left-color:#3b82f6}.phase-3{border-left-color:#10b981}
.phase-4{border-left-color:#8b5cf6}.phase-5{border-left-color:#ef4444}
.phase-header{display:flex;align-items:center;gap:14px;margin-bottom:18px}
.phase-header h3{margin:0;font-size:1.43em;flex-grow:1;color:#1e293b}
.phase-icon{font-size:1.8em}
.phase-time{background:linear-gradient(135deg,#eff6ff,#dbeafe);padding:6px 18px;border-radius:20px;font-size:1.07em;font-weight:700;color:#1d4ed8;border:1px solid #bfdbfe}
.teacher-activity,.student-activity,.phase .textbook-ref,.assessment{padding:12px 18px;margin-bottom:10px;border-radius:10px;font-size:1.20em;line-height:1.7}
.teacher-activity{background:linear-gradient(135deg,#eff6ff,#f0f7ff);border-left:4px solid #3b82f6}
.student-activity{background:linear-gradient(135deg,#f0fdf4,#f0fff4);border-left:4px solid #22c55e}
.phase .textbook-ref{background:linear-gradient(135deg,#fefce8,#fffde4);border-left:4px solid #eab308;color:#854d0e;font-weight:600}
.assessment{background:linear-gradient(135deg,#faf5ff,#f8f0ff);border-left:4px solid #a855f7}
.differentiation{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin:14px 0}
.diff-level{padding:16px;border-radius:12px;font-size:1.14em}
.diff-base{background:#f0fdf4;border:1px solid #86efac}.diff-mid{background:#fffbeb;border:1px solid #fde68a}
.diff-high{background:#fef2f2;border:1px solid #fca5a5}
.stats-block,.analysis-block{background:linear-gradient(135deg,#0f172a,#1e293b);color:#e2e8f0;padding:28px;border-radius:16px;margin-top:28px;box-shadow:0 4px 20px rgba(0,0,0,.2)}
.stats-block h3,.analysis-block h3{margin:0 0 18px;color:#fbbf24;font-size:1.43em}
.stat-row{padding:10px 0;border-bottom:1px solid rgba(255,255,255,.08);font-size:1.17em;line-height:1.6}
.stat-row:last-child{border-bottom:none}
.lang-section{margin-top:36px;padding:24px 0;border-top:4px solid #3b82f6}
.lang-section h2{background:linear-gradient(135deg,#1e40af,#3b82f6);color:#fff;padding:16px 28px;border-radius:12px;font-size:1.5em;display:inline-block;margin:0 0 20px}
.arti-footer{text-align:center;margin-top:36px;padding:18px;color:#94a3b8;font-size:1.04em;border-top:2px solid #e2e8f0}
@media print{.answer-box,.question-block,.phase{page-break-inside:avoid}.ai-output{font-size:12pt}}
@media(max-width:768px){.options{grid-template-columns:1fr}.meta-grid{grid-template-columns:1fr}.differentiation{grid-template-columns:1fr}}
</style>'

# ═══════════════ DIL HELPER ═══════════════
build_lang_instruction <- function(langs) {
  if (is.null(langs) || length(langs) == 0) langs <- "az"
  LANG_NAMES <- c(az = "AZERBAYCAN DILI", ru = "RUS DILI", en = "INGILIS DILI")
  LANG_FLAGS <- c(az = "\U0001F1E6\U0001F1FF", ru = "\U0001F1F7\U0001F1FA", en = "\U0001F1EC\U0001F1E7")
  if (length(langs) == 1 && langs == "az") {
    return("\nDIL: Neticeni YALNIZ Azerbaycan dilinde yaz.\nDOLGUNLUQ: Cavabi musefesssel ve tam yaz — her tapshiriqda minimum 4 addimli hell, alternativ yollar, konkret numuneler.\n")
  }
  lang_list <- paste(sapply(seq_along(langs), function(i) {
    paste0(i, ". ", LANG_FLAGS[langs[i]], " ", LANG_NAMES[langs[i]])
  }), collapse = "\n")
  paste0('
═══════════════════════════════════════
DILLER (COX VACIB!):
═══════════════════════════════════════
Neticeni ', length(langs), ' DILDE ver — her dil ayrica bolme sheklinde:
', lang_list, '

Her dil bolmesi bu bashliq ile bashlamalidir:
<div class="lang-section" style="margin-top:36px;padding:24px 0;border-top:4px solid #3b82f6;">
  <h2 style="background:linear-gradient(135deg,#1e40af,#3b82f6);color:#fff;padding:16px 28px;border-radius:12px;font-size:1.5em;display:inline-block;">
    [BAYRAQ_EMOJI] [DIL ADI]
  </h2>
</div>

Her bolmede HERSEY tam shekilde tercume olunmalidir (tapshiriqlar, cavablar, helller, analiz).
Riyazi ifadeler, ededler, formullar EYNI qalir — yalniz metn hissesi tercume olunur.
DOLGUNLUQ: Cavabi musefesssel ve tam yaz — her tapshiriqda minimum 4 addimli hell, alternativ yollar, konkret numuneler.
')
}

# ═══════════════ PROMPTS ═══════════════
build_test_prompt <- function(grade, topic, standard, context, count, blooms, dok, langs = c("az")) {
  lang_inst <- build_lang_instruction(langs)
  paste0(
'Sen dunya tehsilinin aparici olkelerinin (Finlandiya, Sinqapur, Estoniya, Yaponiya, Yeni Zelandiya) qiymetlendirme standartlarina uygun test tapshiriqlari yaradan ekspert psixometr ve riyaziyyat metodist AI-san.
', lang_inst, '
═══════════════════════════════════════
PARAMETRLER:
═══════════════════════════════════════
SINIF: ', grade, '-ci sinif
MOVZU: ', topic, '
STANDART: ', standard, '
TAPSHIRIQ SAYI: ', count, '
BLOOM TAKSONOMIYAS: ', paste(blooms, collapse = ", "), '
BILIK DERINLIYI (DOK): ', dok, '

═══════════════════════════════════════
DERSLIKDEN KONTEKST:
═══════════════════════════════════════
', context, '

═══════════════════════════════════════
BEYNELXALQ STANDARTLAR VE TELEBLER:
═══════════════════════════════════════

1. PISA (Programme for International Student Assessment):
   - Kontekstli meseleler: real heyat situasiyalari (Baki sheherinde tikinti, Xezer denizinde suyu hesablama, ASAN xidmetde novbe, metroda mesafe, Heydar Eliyev Merkezinin geometriyasi)
   - Riyazi savadliliq: formullashdirma > hesablama > sherhtemet > qiymetlendirme
   - 6 ustaliq seviyyesi (Level 1-6) nezere alinmali
   - Metn, cedvel, qrafik, diaqram daxil eden kompleks tapshiriqlar

2. TIMSS (Trends in International Mathematics and Science Study):
   - Mezmun saheleri: Ededler, Cebr, Hendese, Melumatlar ve ehtimal
   - Koqnitiv saheler: Bilik (35%), Tetbiq (40%), Muhakime (25%)
   - Cetinlik balansi: asan 25% | orta 50% | cetin 25%
   - Coxaddimli hell teleb eden tapshiriqlar

3. PIRLS (Progress in International Reading Literacy Study):
   - Metn anlama ve sherhtemet bacarigi (mesele metnleri ucun)
   - Melumat cixarma, birbashe neticelendirme, sherhtemet, qiymetlendirme

4. BLOOM TAKSONOMIYASI (yenilenmish Anderson-Krathwohl):
   - Xatirlama: taniyin, yada salin, siyahi verin (fiiller: adi, taniyi, teyin edi)
   - Anlama: izah edin, temsil edin, tefsir edin (fiiller: izah edir, muqayise edir, temsil edir)
   - Tetbiqetme: icra edin, heyata kecirin (fiiller: hesablayir, hell edir, tetbiq edir, qurur)
   - Tehlil: ferqlendirin, teshkil edin, aid edin (fiiller: tehlil edir, ferqlendirir, mueyyen edir)
   - Qiymetlendirme: yoxlayin, tenkid edin (fiiller: qiymetlendirir, esaslandirir, secim edir)
   - Yaratma: yaradarin, planlasdirin, istehsal edin (fiiller: layihelendirir, modellesdirir, yaradir)

5. DOK - BILIK DERINLIYI (Norman Webb):
   - DOK-1 (Xatirlama): Bir addimli prosedur, fakt, formula tetbiqi. Vaxt: <1 deq
   - DOK-2 (Bacariq/Anlayish): Coxaddimli hell, muqayise, tesniflendirme, sebebini izah. Vaxt: 1-3 deq
   - DOK-3 (Strateji dushunce): Qeyri-standart hell, esaslandirma, planlama, coxlu strategiya. Vaxt: 3-5 deq
   - DOK-4 (Genishlendirilmish dushunce): Layihe, tedqiqat, real heyat modelleshdirmesi. Vaxt: 5+ deq

═══════════════════════════════════════
TAPSHIRIQ YARATMA QAYDALARI:
═══════════════════════════════════════

A) MEZMUN KEYFLYYETI:
   - HER tapshiriqda derslikdeki terminologiyanin deqiq istifadesi
   - HER tapshiriqda derslik sehife nomresine istinad (seh. XX)
   - Real heyat konteksti: Baki shaheri, Azerbaycan manati (AZN), Xezer denizi, Heydar Eliyev Merkezi, Yashil Enerjiya, ASAN xidmet, Baki Metropoliteni
   - Medeni kontekst: Novruz bayrami, Azerbaycan xalcasi, mugam, ashiq seneti
   - Fenn integrasiyasi: fizika, cografiya, iqtisadiyyat ile elaqe
   - Shekiller, cedveller, qrafikler (sozle tesvir et: "asagidaki cedvele bax:")

B) COXSECIMLI SUALLAR (A, B, C, D):
   - Duzgun cavab: aciq ve birmenaali
   - Distraktorlar (sehv variantlar): HER birinin NIYE sehv oldugu izah edilmeli
     * Tipik shagird sehvi (meselen: isare sehvi, ehmal sehvi)
     * Yarimmehsul cavab (mellim addimi atlamaq)
     * Konseptual yanilma (anlayish sehvi)
   - Variantlar arasinda "hech biri" ve ya "hamisi" olmasin
   - Variantlar oxshar uzunluqda olsun

C) ACIQ CAVABLI SUALLAR:
   - Rubrika (0-1-2-3 bal skalasi):
     * 0 bal: Cavab yoxdur ve ya tamamilasehv
     * 1 bal: Bashlangic anlayish, amma helli tamamlaya bilmir
     * 2 bal: Dogru yol, kicik hesablama sehvi
     * 3 bal: Tam duzgun hell, izah ve yekun cavab
   - Numune shagird cavablari (1 bal ve 3 bal ucun)

D) CAVAB ACARI VE HELL:
   - Her tapshiriqin ADDIM-ADDIM helli yazilmali
   - Her addimda istifade olunan qayda/teorem/xassein adi
   - Alternatif hell yolu (varsa)
   - Derslik sehife istinadi: "Bu tipi derslikde seh. XX-de tapshiriq No.YY-ye baxin"
   - Shagirdler ucun ipucu (hint): "Ipucu: evvelce ... tapshiriq edin"

═══════════════════════════════════════
HTML FORMATI (CIDDI RIAYAT):
═══════════════════════════════════════
Neticeni YALNIZ HTML teqleri ile ver. Markdown (**, ##, -) ISTIFADE ETME.

<div class="test-header">
  <h1>Riyaziyyat Test Tapshiriqlari</h1>
  <div class="meta-grid">
    <div class="meta-item"><span class="label">Sinif:</span> ', grade, '-ci sinif</div>
    <div class="meta-item"><span class="label">Movzu:</span> ', topic, '</div>
    <div class="meta-item"><span class="label">Standart:</span> ', standard, '</div>
    <div class="meta-item"><span class="label">Tapshiriq sayi:</span> ', count, '</div>
    <div class="meta-item"><span class="label">Bloom:</span> ', paste(blooms, collapse = ", "), '</div>
    <div class="meta-item"><span class="label">DOK:</span> ', dok, '</div>
    <div class="meta-item"><span class="label">Beynelxalq uygunluq:</span> PISA + TIMSS + Sinqapur</div>
  </div>
</div>

HER TAPSHIRIQ bele olmalidir:
<div class="question-block bloom-[seviyye]">
  <div class="question-header">
    <span class="bloom-badge">BLOOM: [SEVIYYE]</span>
    <span class="dok-badge">DOK-[N]</span>
  </div>
  <div class="question-text"><strong>Tapshiriq [N].</strong> [Sualin tam metni - kontekstli, real heyat situasiyasi, shekil/cedvel tesviri]</div>
  <div class="options">
    <div class="option"><strong>A)</strong> [variant]</div>
    <div class="option"><strong>B)</strong> [variant]</div>
    <div class="option"><strong>C)</strong> [variant]</div>
    <div class="option"><strong>D)</strong> [variant]</div>
  </div>
  <div class="answer-box">
    <div class="answer">Duzgun cavab: [HERF]) [metn]</div>
    <div class="solution"><strong>Addim-addim hell:</strong><br>
    1-ci addim: [izah + istifade olunan qayda]<br>
    2-ci addim: [davami]<br>
    3-cu addim: [yekun hesablama]<br>
    <strong>Neticee:</strong> [yekun cavab]<br>
    <strong>Alternativ yol:</strong> [varsa]</div>
    <div class="textbook-ref">Derslik istinadi: seh. [XX], tapshiriq No.[YY] | Benzer numune: seh. [ZZ]</div>
    <div class="difficulty">Cetinlik: [asan/orta/cetin] | Vaxt: [X] deqiqe | Bal: [X] | PISA seviyyesi: [1-6]</div>
    <div class="distractors"><strong>Distraktor analizi:</strong><br>
    A) [Niye sehv: tipik shagird sehvi tesviri]<br>
    B) [Niye sehv: hansi qaydani sehv tetbiq edir]<br>
    C) [Niye sehv: yarimmehsul cavab]<br>
    D) [Duzgun cavab: niye dogru]</div>
    <div class="rubric"><strong>Ipucu shagirdler ucun:</strong> [Hell strategiyasi haqqinda ipucu, derslikde hara baxmali]</div>
  </div>
</div>

Sonda MUTLEQ bu analiz blokunu elave et:
<div class="stats-block">
  <h3>Test Statistikasi ve Analiz</h3>
  <div class="stat-row"><strong>Bloom paylamasi:</strong> Xatirlama: X% | Anlama: X% | Tetbiqetme: X% | Tehlil: X% | Qiymetlendirme: X% | Yaratma: X%</div>
  <div class="stat-row"><strong>DOK paylamasi:</strong> DOK-1: X tapshiriq | DOK-2: X tapshiriq | DOK-3: X tapshiriq | DOK-4: X tapshiriq</div>
  <div class="stat-row"><strong>Cetinlik balansi:</strong> Asan: X (25%) | Orta: X (50%) | Cetin: X (25%) — TIMSS standartina uygun</div>
  <div class="stat-row"><strong>PISA uygunluqu:</strong> Real heyat konteksti: X tapshiriq | Riyazi savadliliq: X tapshiriq | Muhakime: X tapshiriq</div>
  <div class="stat-row"><strong>TIMSS uygunluqu:</strong> Bilik: X% | Tetbiq: X% | Muhakime: X%</div>
  <div class="stat-row"><strong>Sinqapur CPA:</strong> Konkret: X | Tesviri: X | Mucerred: X</div>
  <div class="stat-row"><strong>Derslik istinadlari:</strong> seh. [butun istifade olunan sehifeler]</div>
  <div class="stat-row"><strong>Texmini vaxt:</strong> Cemi [X] deqiqe | Orta tapshiriq bashi [Y] deqiqe</div>
</div>')
}

build_lesson_prompt <- function(grade, topic, standard, context, duration, blooms, dok, langs = c("az")) {
  lang_inst <- build_lang_instruction(langs)
  m1 <- as.integer(duration * 0.10); m2 <- as.integer(duration * 0.30)
  m3 <- as.integer(duration * 0.25); m4 <- as.integer(duration * 0.25); m5 <- as.integer(duration * 0.10)
  paste0(
'Sen dunya tehsilinin aparici olkelerinin (Finlandiya, Sinqapur, Estoniya, Yaponiya) metodologiyalarina uygun ders planlari hazirlayan ekspert metodist AI-san.
', lang_inst, '
═══════════════════════════════════════
PARAMETRLER:
═══════════════════════════════════════
SINIF: ', grade, '-ci sinif
MOVZU: ', topic, '
STANDART: ', standard, '
MUDDET: ', duration, ' deqiqe
BLOOM: ', paste(blooms, collapse = ", "), '
DOK: ', dok, '

═══════════════════════════════════════
DERSLIKDEN KONTEKST:
═══════════════════════════════════════
', context, '

═══════════════════════════════════════
BEYNELXALQ METODOLOJI TELEBLER:
═══════════════════════════════════════

1. SINQAPUR CPA MODELİ (Concrete-Pictorial-Abstract):
   KONKRET merhele: Eshya, manipulyativ, real obyektlerle ish (pul, kibrit, kagiz qatlama)
   TESVIRI merhele: Shekil, diaqram, eded oxu, model cekmek
   MUCERRED merhele: Simvol, formula, cebri ifade, umumi qayda

2. FINLANDIYA MODELİ:
   - Shagird merkezli, keshf esasli oyrenme
   - Sehvler oyrenme imkanidir — sehvlere musbet munasibat
   - Formativ qiymetlendirme: muellim musahide edir, yonlendirir
   - Az ev tapshirigi, amma keyfiyyetli
   - Qrup ishi ve muzakire: shagirdler bir-birine oyredir

3. YAPONIYA "LESSON STUDY" MODELİ:
   - Dersin mehveri: "Bu gun shagirdler ne oyrenecekhell edecek?"
   - Numunevi meseleler: Muellim bir numune gosterir, shagirdler strateji mueyyen edir
   - Musteqil tedqiqat: Shagirdler oz yollarini tapmaga calishir
   - Neandoji (kiken): Muxtelf hell yollarini cedvelde muqayise etmek

4. BLOOM TAKSONOMIYASI (Anderson-Krathwohl):
   Her merhelede hansi Bloom seviyyesinin hedefe alindigini goster

5. DOK SEVIYYELERİ:
   Her tapshiriqda DOK seviyyesini qeyd et

6. PISA/TIMSS INTEQRASIYA:
   - Real heyat konteksti (PISA): Baki, manat, Xezer, metro, enerji, su, ekoloji
   - Riyazi muhakime (TIMSS): Niye? Esaslandir. Baska yol goster. Ne olar eger?
   - Fenn integrasiyasi: fizika, cografiya, iqtisadiyyat

═══════════════════════════════════════
DERS PLANININ STRUKTURU (5 MERHELE):
═══════════════════════════════════════

MERHELE 1: MOTIVASIYA VE AKTUALLASDIRMA (', m1, ' deq)
  - Gundlik heyatdan problem situasiyasi (PISA tipi)
  - Derslikden "Arasdirma" ve ya "Dusun" bolmesi
  - Evvelki biliklerin aktivleshdirilmesi (2-3 sual)
  - Dersin meqsedinin SHAGIRDLERLE birge mueyyen edilmesi

MERHELE 2: YENI BILIK VE KESHF (', m2, ' deq) — SINQAPUR CPA
  - KONKRET: Real obyektlerle nümayish (ne istifade olunur, nece gosterilir)
  - TESVIRI: Shekil, diaqram, model — shagirdler deftere cekir
  - MUCERRED: Formula/qayda cixarilmasi — shagirdler OZU keshf edir
  - Muellim yonlendirici suallar verir, cavabi DEMHIR
  - Derslikden numune: seh. XX, tapshiriq No.YY

MERHELE 3: BIRGE TETBIQ (', m3, ' deq) — "MEN > BIZ > SEN"
  - MEN: Muellim 1 numune hell edir (sesli dushunme — her addimi izah)
  - BIZ: Cutluklerle 1-2 tapshiriq (derslikden seh. XX)
  - SEN: Ferdi 1 tapshiriq (muellim gezir, yoxlayir)
  - Sehvlerin analizi: 2-3 tipik sehvi levhede goster, muezakire et

MERHELE 4: MUSTEQIL TETBIQ VE DIFERENSIASIYA (', m4, ' deq)
  BAZA seviyye (DOK-1/2): Standart tapshiriqlar, addim-addim gosterish ile
  ORTA seviyye (DOK-2/3): Kontekstli meseleler, oz strategiyasini secmeli
  YUKSEK seviyye (DOK-3/4): PISA tipi aciq meseleler, esaslandirma teleb olunan, layihe elementli
  - Her seviyyede en azi 2 tapshiriq
  - Derslikden: Baza seh.XX No.YY | Orta seh.XX No.YY | Yuksek — muellim yaradir

MERHELE 5: YEKUNLASDIRMA VE REFLEKSIYA (', m5, ' deq)
  - Cixis bileti: 1 sual (bu gun ne oyrendim?)
  - 3-2-1 refleksiya: 3 sey oyrendim, 2 sual var, 1 sey maraqli idi
  - Ev tapshirigi: Derslikden seh. XX No.YY (5-10 deq hecminde, keyfiyyetli)
  - Novbeti dersle elaqe: "Novbeti dersde bu biligi ... ucun istifade edeceyik"

═══════════════════════════════════════
HTML FORMATI (CIDDI RIAYAT):
═══════════════════════════════════════
Neticeni YALNIZ HTML teqleri ile ver. Markdown ISTIFADE ETME.

<div class="lesson-header">
  <h1>Ders Plani</h1>
  <div class="meta-grid">
    <div class="meta-item"><span class="label">Sinif:</span> ', grade, '-ci sinif</div>
    <div class="meta-item"><span class="label">Movzu:</span> ', topic, '</div>
    <div class="meta-item"><span class="label">Muddet:</span> ', duration, ' deqiqe</div>
    <div class="meta-item"><span class="label">Standart:</span> ', standard, '</div>
    <div class="meta-item"><span class="label">Bloom:</span> ', paste(blooms, collapse = ", "), '</div>
    <div class="meta-item"><span class="label">DOK:</span> ', dok, '</div>
    <div class="meta-item"><span class="label">Model:</span> Sinqapur CPA + Finlandiya + PISA/TIMSS</div>
  </div>
  <div class="objectives">
    <h3>Telim Neticeleri (SMART formatda)</h3>
    <ul>
      <li><strong>Bilik (Bloom 1-2):</strong> Shagird ... bilecek/izah ede bilecek</li>
      <li><strong>Bacariq (Bloom 3-4):</strong> Shagird ... hesablaya/tehlil ede bilecek</li>
      <li><strong>Tetbiq (Bloom 5-6):</strong> Shagird ... real heyatda tetbiq ede/yarada bilecek</li>
    </ul>
  </div>
</div>

HER MERHELE bele olmalidir:
<div class="phase phase-[N]">
  <div class="phase-header">
    <span class="phase-icon">[uygun emoji]</span>
    <h3>MERHELE [N]: [AD]</h3>
    <span class="phase-time">[X] deq</span>
  </div>
  <div class="teacher-activity"><strong>Muellim fealiyyeti:</strong> [Deqiq ne deyir, ne gosterir, hansi suallari verir — KONKRET cumleler ile]</div>
  <div class="student-activity"><strong>Shagird fealiyyeti:</strong> [Deqiq ne edir: yazir, hesablayir, muzakire edir, cutlukle ishleyir — KONKRET]</div>
  <div class="textbook-ref"><strong>Derslik istinadi:</strong> seh. [XX], tapshiriq No.[YY] | Elave resurs: [varsa]</div>
  <div class="assessment"><strong>Formativ qiymetlendirme:</strong> [Muellim NECE yoxlayir: musahide, sual-cavab, mini-test, bas barmagile isare]</div>
  [Merhele 4 ucun elave:]
  <div class="differentiation">
    <div class="diff-level diff-base"><strong>BAZA (DOK-1/2):</strong> [2 konkret tapshiriq + derslik istinadi]</div>
    <div class="diff-level diff-mid"><strong>ORTA (DOK-2/3):</strong> [2 konkret tapshiriq + kontekst]</div>
    <div class="diff-level diff-high"><strong>YUKSEK (DOK-3/4):</strong> [2 PISA tipi aciq tapshiriq]</div>
  </div>
</div>

Sonda MUTLEQ bu analiz blokunu yaz:
<div class="analysis-block">
  <h3>Ders Analizi</h3>
  <div class="stat-row"><strong>Bloom paylamasi:</strong> Xatirlama X% | Anlama X% | Tetbiqetme X% | Tehlil X% | Qiymetlendirme X% | Yaratma X%</div>
  <div class="stat-row"><strong>Zaman bolgusu:</strong> Muellim X% | Shagird X% | Muzakire X% — Finlandiya standart: Muellim max 30%</div>
  <div class="stat-row"><strong>CPA balans:</strong> Konkret X% | Tesviri X% | Mucerred X%</div>
  <div class="stat-row"><strong>DOK paylamasi:</strong> DOK-1: X% | DOK-2: X% | DOK-3: X% | DOK-4: X%</div>
  <div class="stat-row"><strong>PISA inteqrasiyasi:</strong> Real heyat konteksti: [hansi tapshiriqlar] | Muhakime: [hansi tapshiriqlar]</div>
  <div class="stat-row"><strong>TIMSS uygunluqu:</strong> Bilik: X% | Tetbiq: X% | Muhakime: X%</div>
  <div class="stat-row"><strong>Derslik istinadlari:</strong> seh. [butun istifade olunan sehifeler ve tapshiriq nomreleri]</div>
  <div class="stat-row"><strong>Ev tapshirigi:</strong> Derslik seh. XX No.YY (texmini 10 deq)</div>
  <div class="stat-row"><strong>Inklyuzivlik:</strong> [gorme/eshitme chetinliyi olan shagirdler ucun uygunlashdirma tovsiyyeleri]</div>
</div>')
}

build_doc_prompt <- function(doc_type, grade, period, extra, official, langs = c("az")) {
  DOC_LABELS <- c(journal="Gundlik jurnal",monthly_plan="Ayliq plan",yearly_plan="Illik plan",
    activity_report="Fealiyyet hesabati",olympiad="Olimpiada plani",parent_meeting="Valideyn toplantisi protokolu",
    open_lesson="Aciq ders plani",self_eval="Oz-ozunu qiymetlendirme")
  label <- DOC_LABELS[doc_type] %||% doc_type
  off_text <- if (official) "\nResmi format: movzu, tarix, imza yeri, mohr yeri elave et." else ""
  lang_inst <- build_lang_instruction(langs)
  paste0('Sen Azerbaijan mekteb muellimi ucun resmi senedler hazirlayan ekspert AI-san.\nSENED TIPI: ', label,
    '\nSINIF: ', grade, '-ci sinif\nDOVR: ', period, '\nELAVE: ', extra, off_text,
    lang_inst,
    '\nNeticeni TAM HTML formatinda ver. Derslik istinadlari.\n',
    'HTML: <div class="lesson-header"><h1>', label, '</h1><div class="meta-grid">',
    '<div class="meta-item"><span class="label">Sinif:</span> ', grade, '-ci</div>',
    '<div class="meta-item"><span class="label">Dovr:</span> ', period, '</div></div></div>')
}

build_msg_prompt <- function(msg_type, cls, student, channel, context, tone, langs = c("az")) {
  MSG_LABELS <- c(parent_report="Valideyn hesabati",praise="Ugur mektubu",warning="Xeberdarliq",
    motivation="Motivasiya mesaji",olympiad_invite="Olimpiada daveti",homework_notice="Ev tapshirigi bildirisi",
    meeting_invite="Toplanti daveti",class_report="Sinif raportu")
  CHANNEL_LABELS <- c(whatsapp="WhatsApp",sms="SMS",email="E-pocht",portal="Mekteb portali")
  label <- MSG_LABELS[msg_type] %||% msg_type
  ch_label <- CHANNEL_LABELS[channel] %||% channel
  tone_az <- c(formal="resmi",friendly="dostane",serious="ciddi",encouraging="ruhlendirici")
  paste0('Sen Azerbaijan mekteb muellimi ucun mesajlar yazan ekspert AI-san.\nMESAJ: ', label,
    '\nSINIF: ', cls, ' | SHAGIRD: ', student, '\nKANAL: ', ch_label, ' | TON: ', tone_az[tone] %||% "resmi",
    '\nKONTEKST: ', context,
    build_lang_instruction(langs),
    '\nNeticeni TAM HTML formatinda ver.\n',
    'HTML: <div class="lesson-header" style="padding:24px;"><h1 style="font-size:1.6em;">', label, '</h1>',
    '<div class="meta-grid"><div class="meta-item"><span class="label">Kanal:</span> ', ch_label, '</div>',
    '<div class="meta-item"><span class="label">Shagird:</span> ', student, '</div></div></div>')
}

# ══════════════════════════════════════════════
# HELPER: plotly output or fallback
# ══════════════════════════════════════════════
plotly_or_msg <- function(outputId, height = "300px") {
  if (PLOTLY_OK) plotlyOutput(outputId, height = height) else tags$p(style = "color:#94a3b8;padding:40px;text-align:center;", "plotly lazimdir")
}

# ═══════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════
ui <- dashboardPage(skin = "blue",
  dashboardHeader(title = span(icon("graduation-cap"), " Muellim Agent v3"), titleWidth = 300),
  dashboardSidebar(width = 280, sidebarMenu(id = "tabs",
    menuItem("Ana Sehife", tabName = "home", icon = icon("home")),
    menuItem("Ders Planlari", icon = icon("book"),
      menuSubItem("Yeni Plan", tabName = "lesson_new"),
      menuSubItem("Planlarim", tabName = "lesson_list")),
    menuItem("Qiymetlendirme", icon = icon("clipboard-check"),
      menuSubItem("Test Yarat", tabName = "test_create"),
      menuSubItem("Netice Analizi", tabName = "analysis")),
    menuItem("Shagird Analizi", icon = icon("users"),
      menuSubItem("Profiller", tabName = "student_profiles"),
      menuSubItem("Risk Qruplari", tabName = "risk_groups")),
    menuItem("Senedler", tabName = "documents", icon = icon("file-alt")),
    menuItem("Kommunikasiya", tabName = "communication", icon = icon("comments")),
    menuItem("Standartlar", tabName = "standards", icon = icon("list-check")),
    menuItem("Statistika", tabName = "statistics", icon = icon("chart-bar")),
    hr(),
    div(p(style = "padding:10px;color:#b8c7ce;font-size:11px;", "ARTI 2026 (c) Tariyel Talibov"))
  )),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper{background:#f4f6f9}.box{border-top:3px solid #3c8dbc}
        .skin-blue .main-header .navbar{background:#003366}
        .skin-blue .main-header .logo{background:#002244;font-size:16px!important}
        .btn-generate{font-size:1.15em!important;padding:14px 28px!important;font-weight:700!important;border-radius:10px!important}
        .ai-loading{text-align:center;padding:60px}
        .ai-loading .spinner{width:56px;height:56px;border:5px solid #e2e8f0;border-top-color:#3b82f6;border-radius:50%;animation:spin .8s linear infinite;margin:0 auto 20px}
        @keyframes spin{to{transform:rotate(360deg)}}
        .selectize-dropdown{max-height:420px!important}.selectize-dropdown-content{max-height:400px!important}
        .token-display{display:inline-flex;align-items:center;gap:8px;font-size:1.15em;font-weight:700;padding:8px 16px;border-radius:10px;margin-top:25px}
        .token-waiting{background:#fef3c7;color:#92400e;border:1px solid #fde68a}
        .token-done{background:#dcfce7;color:#166534;border:1px solid #86efac}
        .token-error{background:#fef2f2;color:#991b1b;border:1px solid #fca5a5}
        .live-timer-panel{background:linear-gradient(135deg,#0f172a,#1e293b);border:2px solid #3b82f6;border-radius:16px;padding:28px 36px;margin:20px 0;text-align:center;box-shadow:0 4px 24px rgba(59,130,246,.15)}
        .live-timer-panel .t-status{font-size:1.15em;color:#94a3b8;margin-bottom:10px}
        .live-timer-panel .t-clock{font-family:'JetBrains Mono',monospace;font-size:3.2em;font-weight:700;color:#60a5fa;letter-spacing:.06em;margin:8px 0}
        .live-timer-panel .t-start{font-size:.95em;color:#64748b;margin-bottom:14px}
        .live-timer-panel .t-details{display:flex;justify-content:center;gap:16px;flex-wrap:wrap}
        .live-timer-panel .t-item{background:rgba(255,255,255,.06);padding:8px 18px;border-radius:10px;font-size:.95em;color:#cbd5e1}
        .pdot{display:inline-block;width:10px;height:10px;background:#22c55e;border-radius:50%;margin-right:8px;animation:pdot 1s infinite}
        @keyframes pdot{0%,100%{opacity:1}50%{opacity:.3}}
        .t-done{border-color:#22c55e!important}.t-err{border-color:#ef4444!important}
      ")),
      tags$script(HTML('
        var _atI=null,_atS=null;
        Shiny.addCustomMessageHandler("ai_timer_start",function(m){
          if(_atI)clearInterval(_atI);_atS=new Date();
          var e=document.getElementById(m.target);if(!e)return;
          var st=_atS.toLocaleTimeString("az-AZ",{hour:"2-digit",minute:"2-digit",second:"2-digit"});
          e.innerHTML="<div class=\\"live-timer-panel\\"><div class=\\"t-status\\"><span class=\\"pdot\\"></span>"+m.status+"</div><div class=\\"t-clock\\" id=\\"_clk_"+m.target+"\\">00:00</div><div class=\\"t-start\\">Baslama: "+st+"</div><div class=\\"t-details\\"><div class=\\"t-item\\">"+m.info1+"</div><div class=\\"t-item\\">"+m.info2+"</div><div class=\\"t-item\\">Claude AI</div></div></div>";
          _atI=setInterval(function(){var d=Math.floor((new Date()-_atS)/1000),mm=Math.floor(d/60),ss=d%60;var t=(mm<10?"0":"")+mm+":"+(ss<10?"0":"")+ss;var c=document.getElementById("_clk_"+m.target);if(c)c.textContent=t},250)
        });
        Shiny.addCustomMessageHandler("ai_timer_stop",function(m){
          if(_atI){clearInterval(_atI);_atI=null}var e=document.getElementById(m.target);if(!e)return;
          var ok=m.ok,cl=ok?"t-done":"t-err",co=ok?"#22c55e":"#ef4444",lb=ok?"Tamamlandi!":"Xeta bas verdi";
          e.innerHTML="<div class=\\"live-timer-panel "+cl+"\\"><div class=\\"t-status\\" style=\\"color:"+co+"\\">"+lb+"</div><div class=\\"t-clock\\" style=\\"color:"+co+"\\">"+m.elapsed+" san</div><div class=\\"t-details\\"><div class=\\"t-item\\">Giris: "+m.inp+"</div><div class=\\"t-item\\">Cixis: "+m.out+"</div><div class=\\"t-item\\">"+m.cost+"</div></div></div>"
        });
      '))
    ),
    tabItems(
      # === HOME ===
      tabItem(tabName = "home",
        fluidRow(
          infoBox("DERS PLANLARI", textOutput("plan_count"), icon = icon("book"), color = "blue", width = 3),
          infoBox("TESTLER", textOutput("test_count"), icon = icon("clipboard"), color = "green", width = 3),
          infoBox("SHAGIRDLER", textOutput("student_count"), icon = icon("users"), color = "yellow", width = 3),
          infoBox("RISK", textOutput("alert_count"), icon = icon("exclamation-triangle"), color = "red", width = 3)
        ),
        fluidRow(
          box(title = "Sinif Performansi", width = 6, solidHeader = TRUE, status = "info", plotly_or_msg("class_perf")),
          box(title = "Seviyye Paylamasi", width = 6, solidHeader = TRUE, plotly_or_msg("level_dist"))
        )
      ),
      # === LESSON ===
      tabItem(tabName = "lesson_new", fluidRow(box(title = "AI ile Ders Plani Yaratma", width = 12, solidHeader = TRUE, status = "primary",
        fluidRow(column(2, selectInput("lp_grade", "Sinif:", choices = as.character(1:11), selected = "6")),
          column(5, uiOutput("lp_standard_ui")), column(3, uiOutput("lp_topic_ui")),
          column(2, numericInput("lp_duration", "Muddet:", value = 45))),
        fluidRow(column(3, checkboxGroupInput("lp_bloom", "Bloom:", choices = c("Xatirlama","Anlama","Tetbiqetme","Tehlil","Qiymetlendirme","Yaratma"), selected = c("Anlama","Tetbiqetme","Tehlil"))),
          column(2, sliderInput("lp_dok", "DOK:", min = 1, max = 4, value = 2)),
          column(3, checkboxGroupInput("lp_lang", "Dil:", choices = c("Azerbaycan"="az","Rus"="ru","Ingilis"="en"), selected = c("az","ru","en"), inline = TRUE)),
          column(2, actionButton("lp_generate", "AI ile Yarat", class = "btn-primary btn-lg btn-generate", style = "margin-top:25px;"))),
        fluidRow(column(12, uiOutput("lp_token_ui"))),
        hr(), tags$div(id = "lp_timer_live"), uiOutput("lp_result")))),
      # === TEST ===
      tabItem(tabName = "test_create", fluidRow(box(title = "AI Test Generatoru", width = 12, solidHeader = TRUE, status = "success",
        fluidRow(column(2, selectInput("tc_grade", "Sinif:", choices = as.character(1:11), selected = "6")),
          column(5, uiOutput("tc_standard_ui")), column(3, uiOutput("tc_topic_ui")),
          column(2, numericInput("tc_count", "Say:", value = 12, min = 5, max = 30))),
        fluidRow(column(3, checkboxGroupInput("tc_bloom", "Bloom:", choices = c("Xatirlama","Anlama","Tetbiqetme","Tehlil","Qiymetlendirme","Yaratma"), selected = c("Xatirlama","Anlama","Tetbiqetme","Tehlil","Qiymetlendirme"))),
          column(2, sliderInput("tc_dok", "DOK:", min = 1, max = 4, value = 3)),
          column(3, checkboxGroupInput("tc_lang", "Dil:", choices = c("Azerbaycan"="az","Rus"="ru","Ingilis"="en"), selected = c("az","ru","en"), inline = TRUE)),
          column(2, actionButton("tc_generate", "Test Yarat", class = "btn-success btn-lg btn-generate", style = "margin-top:25px;"))),
        fluidRow(column(12, uiOutput("tc_token_ui"))),
        hr(), tags$div(id = "tc_timer_live"), uiOutput("tc_result")))),
      # === STANDARTLAR ===
      tabItem(tabName = "standards", fluidRow(box(title = "Kurikulum Standartlari", width = 12, solidHeader = TRUE,
        fluidRow(column(4, selectInput("st_grade2", "Sinif:", choices = as.character(1:11), selected = "6")),
          column(4, actionButton("st_load2", "Yukle", class = "btn-primary", style = "margin-top:25px;"))),
        hr(), DTOutput("stds_table2")))),
      # === LESSON LIST / ANALYSIS ===
      tabItem(tabName = "lesson_list", box(title = "Planlarim", width = 12, solidHeader = TRUE, p("Modul hazirlanir..."))),
      tabItem(tabName = "analysis", box(title = "Netice Analizi", width = 12, solidHeader = TRUE, p("Modul hazirlanir..."))),
      # === STUDENT PROFILES ===
      tabItem(tabName = "student_profiles", fluidRow(box(title = "Shagird Oyrenme Profilleri", width = 12, solidHeader = TRUE, status = "info",
        fluidRow(column(3, selectInput("sp_class", "Sinif:", choices = c("5A","5B","6A","6B","7A","7B","8A","8B","9A","9B","10A","10B","11A"), selected = "6A")),
          column(3, uiOutput("sp_student_ui")),
          column(3, selectInput("sp_period", "Dovr:", choices = c("I yarimil"="h1","II yarimil"="h2","Butun il"="full"), selected = "full")),
          column(3, actionButton("sp_analyze", "Analiz Et", class = "btn-info btn-lg", style = "margin-top:25px;font-weight:700;"))),
        hr(),
        fluidRow(
          column(4, tags$div(style = "background:linear-gradient(135deg,#f0fdf4,#dcfce7);border-radius:14px;padding:20px;min-height:220px;border:1px solid #86efac;",
            tags$h4(style = "color:#15803d;margin:0 0 12px;", icon("trophy"), " Guclu Terefler"), uiOutput("sp_strengths"))),
          column(4, tags$div(style = "background:linear-gradient(135deg,#fef2f2,#fee2e2);border-radius:14px;padding:20px;min-height:220px;border:1px solid #fca5a5;",
            tags$h4(style = "color:#dc2626;margin:0 0 12px;", icon("exclamation-triangle"), " Zeif Terefler"), uiOutput("sp_weaknesses"))),
          column(4, tags$div(style = "background:linear-gradient(135deg,#eff6ff,#dbeafe);border-radius:14px;padding:20px;min-height:220px;border:1px solid #93c5fd;",
            tags$h4(style = "color:#1d4ed8;margin:0 0 12px;", icon("lightbulb"), " Tovsiyyeler"), uiOutput("sp_recommendations")))),
        br(),
        fluidRow(
          column(6, box(title = "Fenler uzre Bal Dinamikasi", width = NULL, solidHeader = TRUE, plotly_or_msg("sp_trend_chart", "320px"))),
          column(6, box(title = "Bloom Seviyyeleri", width = NULL, solidHeader = TRUE, plotly_or_msg("sp_bloom_chart", "320px")))),
        fluidRow(column(12, box(title = "Shagird Qiymetlendirme Tarixcesi", width = NULL, solidHeader = TRUE, DTOutput("sp_history_table"))))))),
      # === RISK GROUPS ===
      tabItem(tabName = "risk_groups", fluidRow(box(title = "Risk Qruplari Analizi", width = 12, solidHeader = TRUE, status = "danger",
        fluidRow(column(3, selectInput("rg_class", "Sinif:", choices = c("Butun mekteb"="all","5A","5B","6A","6B","7A","7B","8A","8B","9A","9B","10A","10B","11A"), selected = "all")),
          column(3, selectInput("rg_subject", "Fenn:", choices = c("Riyaziyyat"="math","Butun fenler"="all"), selected = "math")),
          column(3, selectInput("rg_criteria", "Risk meyari:", choices = c("Bal < 40%"="low_score","Gerilemis"="declining","Davamiyyet"="attendance","Bloom-1 dominant"="low_bloom"), selected = "low_score")),
          column(3, actionButton("rg_detect", "Risk Analizi", class = "btn-danger btn-lg", style = "margin-top:25px;font-weight:700;", icon = icon("search")))),
        hr(),
        fluidRow(
          infoBox("Yuksek Risk", textOutput("rg_high_count"), icon = icon("exclamation-circle"), color = "red", width = 3),
          infoBox("Orta Risk", textOutput("rg_mid_count"), icon = icon("exclamation-triangle"), color = "yellow", width = 3),
          infoBox("Ashagi Risk", textOutput("rg_low_count"), icon = icon("check-circle"), color = "green", width = 3),
          infoBox("Cemi Shagird", textOutput("rg_total_count"), icon = icon("users"), color = "blue", width = 3)),
        fluidRow(
          column(5, box(title = "Risk Paylamasi", width = NULL, solidHeader = TRUE, plotly_or_msg("rg_pie_chart"))),
          column(7, box(title = "Risk Siyahisi", width = NULL, solidHeader = TRUE, status = "danger", DTOutput("rg_table")))),
        fluidRow(column(12, box(title = "AI Tovsiyyeler", width = NULL, solidHeader = TRUE, status = "warning", uiOutput("rg_ai_recs"))))))),
      # === DOCUMENTS ===
      tabItem(tabName = "documents",
        fluidRow(
          box(title = "Sened Generatoru", width = 5, solidHeader = TRUE, status = "primary",
            selectInput("doc_type", "Sened tipi:", choices = c("Gundlik jurnal"="journal","Ayliq plan"="monthly_plan","Illik plan"="yearly_plan",
              "Fealiyyet hesabati"="activity_report","Olimpiada plani"="olympiad","Valideyn toplantisi"="parent_meeting",
              "Aciq ders plani"="open_lesson","Oz-ozunu qiymetlendirme"="self_eval")),
            selectInput("doc_grade", "Sinif:", choices = as.character(1:11), selected = "6"),
            textInput("doc_period", "Dovr/Movzu:", placeholder = "Mes: Mart 2026"),
            textAreaInput("doc_extra", "Elave melumat:", rows = 3, placeholder = "Xususi telebler..."),
            checkboxInput("doc_official", "Resmi format (mohr/imza yeri)", FALSE),
            checkboxGroupInput("doc_lang", "Dil:", choices = c("Azerbaycan"="az","Rus"="ru","Ingilis"="en"), selected = c("az","ru","en"), inline = TRUE),
            actionButton("doc_generate", "Sened Yarat", class = "btn-primary btn-lg", style = "width:100%;font-weight:700;font-size:1.1em;", icon = icon("file-alt")),
            br(), br(), uiOutput("doc_token_ui")),
          box(title = "Netice", width = 7, solidHeader = TRUE, status = "info",
            tags$div(id = "doc_timer_live"), uiOutput("doc_result"))),
        fluidRow(box(title = "Son Yaradilan Senedler", width = 12, solidHeader = TRUE, DTOutput("doc_history_table")))),
      # === COMMUNICATION ===
      tabItem(tabName = "communication",
        fluidRow(
          box(title = "Mesaj Yaratma", width = 5, solidHeader = TRUE, status = "success",
            selectInput("msg_type", "Mesaj tipi:", choices = c("Valideyn hesabati"="parent_report","Ugur mektubu"="praise","Xeberdarliq"="warning",
              "Motivasiya mesaji"="motivation","Olimpiada daveti"="olympiad_invite","Ev tapshirigi"="homework_notice",
              "Toplanti daveti"="meeting_invite","Sinif raportu"="class_report")),
            selectInput("msg_class", "Sinif:", choices = c("5A","5B","6A","6B","7A","7B","8A","8B","9A","9B","10A","10B","11A"), selected = "6A"),
            uiOutput("msg_student_ui"),
            selectInput("msg_channel", "Kanal:", choices = c("WhatsApp"="whatsapp","SMS"="sms","E-pocht"="email","Portal"="portal")),
            textAreaInput("msg_context", "Elave kontekst:", rows = 3, placeholder = "Mes: Son testde 45% aldi..."),
            selectInput("msg_tone", "Ton:", choices = c("Resmi"="formal","Dostane"="friendly","Ciddi"="serious","Ruhlendirici"="encouraging")),
            checkboxGroupInput("msg_lang", "Dil:", choices = c("Azerbaycan"="az","Rus"="ru","Ingilis"="en"), selected = c("az","ru","en"), inline = TRUE),
            actionButton("msg_generate", "Mesaj Yarat", class = "btn-success btn-lg", style = "width:100%;font-weight:700;font-size:1.1em;", icon = icon("paper-plane")),
            br(), br(), uiOutput("msg_token_ui")),
          box(title = "Mesaj Onizleme", width = 7, solidHeader = TRUE, status = "info",
            tags$div(id = "msg_timer_live"), uiOutput("msg_result"), hr(),
            fluidRow(column(4, actionButton("msg_copy", "Kopyala", class = "btn-default btn-block", icon = icon("copy"))),
              column(4, actionButton("msg_edit", "Redeakte", class = "btn-warning btn-block", icon = icon("edit"))),
              column(4, actionButton("msg_save", "Saxla", class = "btn-info btn-block", icon = icon("save")))))),
        fluidRow(box(title = "Mesaj Tarixcesi", width = 12, solidHeader = TRUE, DTOutput("msg_history_table")))),
      # === STATISTICS ===
      tabItem(tabName = "statistics", box(title = "Statistika", width = 12, solidHeader = TRUE, p("Modul hazirlanir...")))
    )
  )
)

# ═══════════════════════════════════════════════
# ASYNC AI CALL HELPER
# ═══════════════════════════════════════════════
run_ai_async <- function(session, output, timer_id, token_output, result_output,
                         info1, info2, status_text, prompt_fn, save_fn, footer_fn) {
  session$sendCustomMessage("ai_timer_start", list(target = timer_id, status = status_text, info1 = info1, info2 = info2))
  output[[token_output]] <- renderUI(tags$div(class = "token-display token-waiting", icon("hourglass-half"), " AI isleyir..."))
  output[[result_output]] <- renderUI(NULL)
  session$onFlushed(function() {
    res <- call_claude(prompt_fn())
    if (res$success) {
      session$sendCustomMessage("ai_timer_stop", list(target = timer_id, ok = TRUE,
        elapsed = sprintf("%.1f", res$time_sec),
        inp = formatC(res$input_tokens, format = "d", big.mark = ","),
        out = formatC(res$output_tokens, format = "d", big.mark = ","),
        cost = sprintf("$%.4f", (res$input_tokens * 3 + res$output_tokens * 15) / 1e6)))
      saved <- save_fn(res$text)
      stats_html <- make_stats_bar(res$time_sec, res$input_tokens, res$output_tokens, saved)
      output[[token_output]] <- renderUI(tags$div(class = "token-display token-done", icon("check-circle"),
        sprintf(" %.1f san | %s token", res$time_sec, formatC(res$input_tokens + res$output_tokens, format = "d", big.mark = ","))))
      output[[result_output]] <- renderUI(tagList(HTML(HTML5_CSS), tags$div(class = "ai-output", HTML(res$text)),
        HTML(stats_html), tags$div(class = "arti-footer", footer_fn())))
    } else {
      session$sendCustomMessage("ai_timer_stop", list(target = timer_id, ok = FALSE,
        elapsed = sprintf("%.1f", res$time_sec), inp = "0", out = "0", cost = "$0"))
      output[[token_output]] <- renderUI(tags$div(class = "token-display token-error", icon("times-circle"), sprintf(" Xeta (%.1f san)", res$time_sec)))
      output[[result_output]] <- renderUI(tags$div(style = "padding:30px;color:#dc2626;", tags$h3("Xeta bas verdi"), tags$p(res$error)))
    }
  }, once = TRUE)
}

# ═══════════════════════════════════════════════
# SERVER
# ═══════════════════════════════════════════════
server <- function(input, output, session) {

  # --- Dropdowns ---
  output$lp_standard_ui <- renderUI(selectInput("lp_standard", "Standart:", choices = get_standards_dropdown(input$lp_grade), width = "100%"))
  output$tc_standard_ui <- renderUI(selectInput("tc_standard", "Standart:", choices = get_standards_dropdown(input$tc_grade), width = "100%"))
  output$lp_topic_ui <- renderUI(selectizeInput("lp_topic", "Movzu:", choices = get_topics_for_grade(input$lp_grade), width = "100%", options = list(placeholder = "Movzu secin...", create = TRUE)))
  output$tc_topic_ui <- renderUI(selectizeInput("tc_topic", "Movzu:", choices = get_topics_for_grade(input$tc_grade), width = "100%", options = list(placeholder = "Movzu secin...", create = TRUE)))

  # === LESSON ===
  observeEvent(input$lp_generate, {
    req(input$lp_grade, input$lp_topic, input$lp_standard)
    gr <- as.integer(input$lp_grade); tp <- input$lp_topic; st <- input$lp_standard
    dur <- input$lp_duration; bl <- input$lp_bloom; dk <- input$lp_dok; ln <- input$lp_lang
    run_ai_async(session, output, "lp_timer_live", "lp_token_ui", "lp_result",
      sprintf("Sinif: %d", gr), tp, "AI ile elaqe quruldu, ders plani yaradilir...",
      function() { ctx <- build_context(gr, tp); build_lesson_prompt(gr, tp, st, ctx, dur, bl, dk, ln) },
      function(text) save_result(text, HTML5_CSS, DERS_DIR, gr, tp, "ders_plani"),
      function() sprintf("ARTI 2026 | Sinif %d | %s | %d deq", gr, tp, dur))
  })

  # === TEST ===
  observeEvent(input$tc_generate, {
    req(input$tc_grade, input$tc_topic, input$tc_standard)
    gr <- as.integer(input$tc_grade); tp <- input$tc_topic; st <- input$tc_standard
    cnt <- input$tc_count; bl <- input$tc_bloom; dk <- input$tc_dok; ln <- input$tc_lang
    run_ai_async(session, output, "tc_timer_live", "tc_token_ui", "tc_result",
      sprintf("Sinif: %d", gr), sprintf("%s (%d tapshiriq)", tp, cnt), "AI ile elaqe quruldu, test yaradilir...",
      function() { ctx <- build_context(gr, tp); build_test_prompt(gr, tp, st, ctx, cnt, bl, dk, ln) },
      function(text) save_result(text, HTML5_CSS, TEST_DIR, gr, tp, "test"),
      function() sprintf("ARTI 2026 | Sinif %d | %s | %d tapshiriq", gr, tp, cnt))
  })

  # === DOCUMENTS ===
  observeEvent(input$doc_generate, {
    req(input$doc_type, input$doc_grade)
    dtype <- input$doc_type; grade <- input$doc_grade
    period <- input$doc_period; extra <- input$doc_extra; official <- input$doc_official; ln <- input$doc_lang
    DOC_LABELS <- c(journal="Gundlik jurnal",monthly_plan="Ayliq plan",yearly_plan="Illik plan",
      activity_report="Fealiyyet hesabati",olympiad="Olimpiada plani",parent_meeting="Valideyn toplantisi",
      open_lesson="Aciq ders plani",self_eval="Oz-ozunu qiymetlendirme")
    label <- DOC_LABELS[dtype] %||% dtype
    run_ai_async(session, output, "doc_timer_live", "doc_token_ui", "doc_result",
      sprintf("Sinif: %s", grade), label, "AI sened yaradir...",
      function() build_doc_prompt(dtype, grade, period, extra, official, ln),
      function(text) save_result(text, HTML5_CSS, DERS_DIR, as.integer(grade), label, "sened"),
      function() sprintf("ARTI 2026 | %s", label))
  })

  # === COMMUNICATION ===
  output$msg_student_ui <- renderUI({
    msg_students <- list("6A"=c("Butun sinif","Aliyev Tural","Hasanova Nigar","Mammadov Elvin"),
      "6B"=c("Butun sinif","Bayramov Rasim","Mirzayeva Lala"),"5A"=c("Butun sinif","Ahmadov Tural","Bayramova Leyla"),
      "7A"=c("Butun sinif","Namazov Eldar","Hajiyeva Sevinc"),"8A"=c("Butun sinif","Mehdiyev Rauf"),
      "9A"=c("Butun sinif","Alasgarov Eldar"))
    studs <- msg_students[[input$msg_class]]
    if (is.null(studs)) studs <- c("Butun sinif", paste0("Shagird_", 1:10))
    selectInput("msg_student", "Shagird:", choices = studs)
  })

  observeEvent(input$msg_generate, {
    req(input$msg_type, input$msg_class)
    mtype <- input$msg_type; cls <- input$msg_class
    student <- input$msg_student %||% "Butun sinif"; channel <- input$msg_channel
    context <- input$msg_context; tone <- input$msg_tone; ln <- input$msg_lang
    MSG_LABELS <- c(parent_report="Valideyn hesabati",praise="Ugur mektubu",warning="Xeberdarliq",
      motivation="Motivasiya",olympiad_invite="Olimpiada daveti",homework_notice="Ev tapshirigi",
      meeting_invite="Toplanti daveti",class_report="Sinif raportu")
    label <- MSG_LABELS[mtype] %||% mtype
    run_ai_async(session, output, "msg_timer_live", "msg_token_ui", "msg_result",
      cls, label, "AI mesaj yaradir...",
      function() build_msg_prompt(mtype, cls, student, channel, context, tone, ln),
      function(text) save_result(text, HTML5_CSS, MSG_DIR, 0, paste0(cls, "_", label), "mesaj"),
      function() sprintf("ARTI 2026 | %s | %s", cls, label))
  })

  observeEvent(input$msg_copy, { showNotification("Mesaj kopyalandi!", type = "message", duration = 3) })
  observeEvent(input$msg_save, { showNotification("Mesaj saxlandi!", type = "message", duration = 3) })

  output$msg_history_table <- renderDT({
    files <- list.files(MSG_DIR, pattern = "\\.html$", full.names = TRUE)
    if (length(files) == 0) return(datatable(data.frame(Mesaj = "Hele mesaj yoxdur"), options = list(dom = "t")))
    df <- data.frame(Fayl = basename(files), Olcu = paste0(round(file.size(files)/1024, 1), " KB"),
      Tarix = format(file.mtime(files), "%d.%m.%Y %H:%M"), stringsAsFactors = FALSE)
    datatable(df[order(df$Tarix, decreasing = TRUE), ], options = list(pageLength = 10, dom = "ftp"))
  })

  output$doc_history_table <- renderDT({
    files <- list.files(DERS_DIR, pattern = "sened.*\\.html$", full.names = TRUE)
    if (length(files) == 0) return(datatable(data.frame(Mesaj = "Hele sened yoxdur"), options = list(dom = "t")))
    df <- data.frame(Fayl = basename(files), Olcu = paste0(round(file.size(files)/1024, 1), " KB"),
      Tarix = format(file.mtime(files), "%d.%m.%Y %H:%M"), stringsAsFactors = FALSE)
    datatable(df[order(df$Tarix, decreasing = TRUE), ], options = list(pageLength = 10, dom = "ftp"))
  })

  # === STANDARDS TABLE ===
  observeEvent(input$st_load2, {
    stds <- ALL_STANDARDS[[as.character(input$st_grade2)]]
    if (!is.null(stds) && length(stds) > 0) {
      df <- do.call(rbind, lapply(stds, function(s) data.frame(
        Kod = s$kod, Sahe = s$sahe, Standart = s$metn, Bloom = s$bloom, DOK = s$dok, stringsAsFactors = FALSE)))
      output$stds_table2 <- renderDT(datatable(df, options = list(pageLength = 25, dom = "ftp"),
        colnames = c("Kod", "Sahe", "Standart", "Bloom", "DOK")))
    }
  })

  # === HOME ===
  output$plan_count <- renderText(as.character(length(list.files(DERS_DIR, pattern = "\\.html$"))))
  output$test_count <- renderText(as.character(length(list.files(TEST_DIR, pattern = "\\.html$"))))
  output$student_count <- renderText("--")
  output$alert_count <- renderText("0")

  if (PLOTLY_OK) {
    output$class_perf <- renderPlotly(plot_ly(x=c("5A","5B","6A","6B","7A"),y=c(72,68,75,80,65),type="bar",marker=list(color=c("#3c8dbc","#00a65a","#f39c12","#dd4b39","#605ca8")))%>%layout(xaxis=list(title="Sinif"),yaxis=list(title="Orta bal")))
    output$level_dist <- renderPlotly(plot_ly(x=c("Zeif","Orta","Yuksek","Ela"),y=c(15,45,30,10),type="bar",marker=list(color=c("#dd4b39","#f39c12","#00a65a","#3c8dbc")))%>%layout(xaxis=list(title="Seviyye"),yaxis=list(title="Say")))
  }

  # === STUDENT PROFILES ===
  sample_students <- list("6A"=c("Aliyev Tural","Hasanova Nigar","Mammadov Elvin","Huseynova Aysel","Ismayilov Kamran","Aliyeva Leyla","Babayev Farid","Guliyeva Samira","Novruzov Orkhan","Karimova Gunel"),
    "6B"=c("Bayramov Rasim","Mirzayeva Lala","Hasanov Vugar","Aliyeva Nisa","Ibrahimov Samir"),
    "5A"=c("Ahmadov Tural","Bayramova Leyla","Garayev Murad","Sadiqova Narmin","Orujov Nihad"),
    "7A"=c("Namazov Eldar","Hajiyeva Sevinc","Karimov Rauf","Asgarova Nigar","Tagiyev Vusal"))

  output$sp_student_ui <- renderUI({
    studs <- sample_students[[input$sp_class]]
    if (is.null(studs)) studs <- paste0("Shagird_", 1:15)
    selectInput("sp_student", "Shagird:", choices = studs)
  })

  observeEvent(input$sp_analyze, {
    req(input$sp_student); stu <- input$sp_student
    set.seed(sum(utf8ToInt(stu)))
    scores <- round(runif(6, 35, 95)); names(scores) <- c("Riyaziyyat","Az.dili","Fizika","Kimya","Biologiya","Tarix")
    best <- names(sort(scores, decreasing = TRUE))[1:2]; worst <- names(sort(scores))[1:2]
    bloom_scores <- round(runif(6, 30, 90)); names(bloom_scores) <- c("Xatirlama","Anlama","Tetbiqetme","Tehlil","Qiymetlendirme","Yaratma")

    output$sp_strengths <- renderUI(tags$ul(style="list-style:none;padding:0;",
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("star",style="color:#f59e0b;"), sprintf(" %s: %d%%", best[1], scores[best[1]])),
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("star",style="color:#f59e0b;"), sprintf(" %s: %d%%", best[2], scores[best[2]])),
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("check-circle",style="color:#22c55e;"), sprintf(" Bloom Tehlil: %d%%", bloom_scores["Tehlil"]))))
    output$sp_weaknesses <- renderUI(tags$ul(style="list-style:none;padding:0;",
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("arrow-down",style="color:#ef4444;"), sprintf(" %s: %d%%", worst[1], scores[worst[1]])),
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("arrow-down",style="color:#ef4444;"), sprintf(" %s: %d%%", worst[2], scores[worst[2]])),
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("exclamation",style="color:#f59e0b;"), sprintf(" Bloom Yaratma: %d%%", bloom_scores["Yaratma"]))))
    output$sp_recommendations <- renderUI(tags$ul(style="list-style:none;padding:0;",
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("lightbulb",style="color:#3b82f6;"), sprintf(" %s: elave tapshiriqlar", worst[1])),
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("lightbulb",style="color:#3b82f6;"), " DOK-3 seviyyeli tapshiriqlar artirmaq"),
      tags$li(style="padding:6px 0;font-size:1.1em;", icon("users",style="color:#8b5cf6;"), " Mentor rolu vermek")))

    if (PLOTLY_OK) {
      output$sp_trend_chart <- renderPlotly({
        months <- c("Sen","Okt","Noy","Dek","Yan","Fev"); set.seed(sum(utf8ToInt(stu))+1)
        math_s <- pmin(pmax(round(cumsum(c(scores["Riyaziyyat"], runif(5,-8,12)))), 20), 100)
        az_s <- pmin(pmax(round(cumsum(c(scores["Az.dili"], runif(5,-6,10)))), 20), 100)
        plot_ly()%>%add_trace(x=months,y=math_s,name="Riyaziyyat",type="scatter",mode="lines+markers",line=list(color="#3b82f6",width=3))%>%
          add_trace(x=months,y=az_s,name="Az.dili",type="scatter",mode="lines+markers",line=list(color="#22c55e",width=3))%>%
          layout(xaxis=list(title=""),yaxis=list(title="Bal",range=c(0,100)),legend=list(orientation="h",y=-0.2))
      })
      output$sp_bloom_chart <- renderPlotly({
        plot_ly(type="scatterpolar",mode="lines+markers",fill="toself",r=c(bloom_scores,bloom_scores[1]),
          theta=c(names(bloom_scores),names(bloom_scores)[1]),line=list(color="#8b5cf6"),fillcolor="rgba(139,92,246,0.2)")%>%
          layout(polar=list(radialaxis=list(visible=TRUE,range=c(0,100))),showlegend=FALSE)
      })
    }
    set.seed(sum(utf8ToInt(stu))+2); n <- 8
    hist_df <- data.frame(Tarix=format(Sys.Date()-sort(sample(1:180,n)),"%d.%m.%Y"),
      Fenn=sample(c("Riyaziyyat","Az.dili","Fizika","Kimya"),n,replace=TRUE),
      Tip=sample(c("Formativ","Summativ","Diaqnostik"),n,replace=TRUE),
      Bal=round(runif(n,30,95)), Bloom=sample(c("Anlama","Tetbiqetme","Tehlil"),n,replace=TRUE),
      DOK=sample(1:3,n,replace=TRUE), stringsAsFactors=FALSE)
    output$sp_history_table <- renderDT(datatable(hist_df,options=list(pageLength=10,dom="ftp"))%>%
      formatStyle("Bal",backgroundColor=styleInterval(c(40,70),c("#fee2e2","#fef3c7","#dcfce7"))))
  })

  # === RISK GROUPS ===
  observeEvent(input$rg_detect, {
    set.seed(as.integer(Sys.time())%%1000)
    all_students <- c(paste0("5A-",c("Ahmadov T.","Bayramova L.","Garayev M.","Sadiqova N.","Orujov N.")),
      paste0("5B-",c("Shirinova L.","Rustamov F.","Aliyeva G.","Hasanli K.","Babayeva S.")),
      paste0("6A-",c("Aliyev T.","Hasanova N.","Mammadov E.","Huseynova A.","Ismayilov K.","Aliyeva L.","Babayev F.","Guliyeva S.","Novruzov O.","Karimova G.")),
      paste0("6B-",c("Bayramov R.","Mirzayeva L.","Hasanov V.","Aliyeva N.","Ibrahimov S.")),
      paste0("7A-",c("Namazov E.","Hajiyeva S.","Karimov R.","Asgarova N.","Tagiyev V.")),
      paste0("8A-",c("Mehdiyev R.","Sultanova A.","Gasimov T.","Huseynli N.","Asadov F.")),
      paste0("9A-",c("Alasgarov E.","Mammadova S.","Ibrahimli K.","Novruzova L.","Rzayev M.")))
    n <- length(all_students)
    scores <- round(runif(n,15,95)); trend <- sample(c("Yukselis","Sabit","Gerilemis"),n,replace=TRUE,prob=c(.4,.35,.25))
    attendance <- round(runif(n,60,100)); bloom_lvl <- sample(c("Xatirlama","Anlama","Tetbiqetme","Tehlil"),n,replace=TRUE,prob=c(.2,.3,.35,.15))
    risk <- rep("Ashagi",n); risk[scores<40] <- "Yuksek"; risk[scores>=40&scores<60] <- "Orta"
    risk[trend=="Gerilemis"&scores<55] <- "Yuksek"; risk[attendance<75] <- ifelse(risk[attendance<75]=="Yuksek","Yuksek","Orta")
    if (input$rg_class != "all") {
      mask <- grepl(paste0("^",input$rg_class,"-"),all_students)
      all_students <- all_students[mask]; scores <- scores[mask]; trend <- trend[mask]
      attendance <- attendance[mask]; bloom_lvl <- bloom_lvl[mask]; risk <- risk[mask]
    }
    df <- data.frame(Shagird=all_students,Bal=scores,Trend=trend,Davamiyyet=paste0(attendance,"%"),Bloom=bloom_lvl,Risk=risk,stringsAsFactors=FALSE)
    df <- df[order(factor(df$Risk,levels=c("Yuksek","Orta","Ashagi"))),]
    output$rg_high_count <- renderText(sum(risk=="Yuksek")); output$rg_mid_count <- renderText(sum(risk=="Orta"))
    output$rg_low_count <- renderText(sum(risk=="Ashagi")); output$rg_total_count <- renderText(length(risk))
    output$rg_table <- renderDT(datatable(df,options=list(pageLength=15,dom="ftp"))%>%
      formatStyle("Risk",backgroundColor=styleEqual(c("Yuksek","Orta","Ashagi"),c("#fee2e2","#fef3c7","#dcfce7")),fontWeight="bold")%>%
      formatStyle("Bal",backgroundColor=styleInterval(c(40,60),c("#fee2e2","#fef3c7","#dcfce7"))))
    if (PLOTLY_OK) {
      output$rg_pie_chart <- renderPlotly(plot_ly(labels=c("Yuksek","Orta","Ashagi"),values=c(sum(risk=="Yuksek"),sum(risk=="Orta"),sum(risk=="Ashagi")),
        type="pie",marker=list(colors=c("#ef4444","#f59e0b","#22c55e")),textinfo="label+value+percent")%>%layout(showlegend=TRUE))
    }
    high_risk <- df[df$Risk=="Yuksek",]
    output$rg_ai_recs <- renderUI({
      if (nrow(high_risk)==0) return(tags$div(style="padding:20px;text-align:center;color:#22c55e;font-size:1.3em;",icon("check-circle")," Yuksek riskli shagird tapilmadi!"))
      rec_items <- lapply(1:min(nrow(high_risk),5), function(i) {
        s <- high_risk[i,]
        tags$div(style="background:#fff;border-radius:12px;padding:16px;margin-bottom:12px;border-left:4px solid #ef4444;box-shadow:0 2px 8px rgba(0,0,0,.06);",
          tags$div(style="font-weight:700;font-size:1.15em;color:#1e293b;margin-bottom:8px;",
            icon("user",style="color:#ef4444;")," ",s$Shagird,tags$span(style="float:right;color:#ef4444;font-weight:700;",sprintf("Bal: %d%%",s$Bal))),
          tags$div(style="color:#475569;font-size:1.05em;line-height:1.6;",
            tags$p(icon("arrow-right",style="color:#3b82f6;"),sprintf(" Trend: %s | Davamiyyet: %s | Bloom: %s",s$Trend,s$Davamiyyet,s$Bloom)),
            tags$p(icon("lightbulb",style="color:#f59e0b;")," Tovsiyye: Ferdi yanasma, DOK-1/2, valideyn gorusu")))
      })
      do.call(tagList, rec_items)
    })
  })
}

shinyApp(ui = ui, server = server, options = list(
  host = "127.0.0.1",
  port = as.integer(Sys.getenv("SHINY_PORT", "4040")),
  launch.browser = TRUE
))
