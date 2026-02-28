# ╔══════════════════════════════════════════════════════════════════╗
# ║  📐 Riy_Muellim_Agent — AI Riyaziyyat Müəllim Paneli           ║
# ║  ARTI 2026 © Tariyel Talibov                                    ║
# ║                                                                  ║
# ║  Xüsusiyyətlər:                                                 ║
# ║  • Dərslikdən sinif/mövzu seçimi (JSON chunk-lardan)            ║
# ║  • Claude AI ilə tapşırıq/test/dərs planı generasiyası         ║
# ║  • Bloom taksonomiyası + DOK səviyyələri                        ║
# ║  • PISA/TIMSS/Sinqapur beynəlxalq standartlar                  ║
# ║  • Nəfis HTML5 çıxış formatı                                    ║
# ╚══════════════════════════════════════════════════════════════════╝

library(shiny)
library(jsonlite)
library(httr)

# ─── KONFİQURASİYA ────────────────────────────────────────────
APP_DIR    <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), "..",".."), mustWork = FALSE)
if (!dir.exists(file.path(APP_DIR, "derslikler"))) {
  APP_DIR <- normalizePath("~/Desktop/Riy_Muellim_Agent", mustWork = FALSE)
}
CHUNKS_DIR <- file.path(APP_DIR, "derslikler", "chunks")

# Claude API konfiqurasiyası
# .env fayldan API acarlari oxu
env_file <- file.path(APP_DIR, ".env")
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) > 0 && !startsWith(line, "#") && grepl("=", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  message("OK: .env yuklendi: ", env_file)
}
CLAUDE_API_KEY  <- Sys.getenv("ANTHROPIC_API_KEY", "")
CLAUDE_MODEL    <- "claude-sonnet-4-5-20250514"
CLAUDE_ENDPOINT <- "https://api.anthropic.com/v1/messages"

# ─── STANDARTLAR ──────────────────────────────────────────────
STANDARDS <- list(
  "1" = list(
    "Ədədlər və əməllər" = "R1.1 — Natural ədədləri 100 daxilində tanıyır, sayır, müqayisə edir, toplama-çıxma",
    "Həndəsə" = "R1.3 — Sadə həndəsi fiqurları (dairə, üçbucaq, düzbucaqlı, kvadrat) tanıyır",
    "Ölçmə" = "R1.5 — Uzunluğu qeyri-standart vahidlərlə ölçür, müqayisə edir"
  ),
  "2" = list(
    "Ədədlər və əməllər" = "R2.1 — Natural ədədləri 1000 daxilində tanıyır, toplama-çıxma əməlləri aparır",
    "Həndəsə" = "R2.3 — Həndəsi fiqurların xassələrini müqayisə edir, simmetriya",
    "Ölçmə" = "R2.5 — Uzunluq (sm, m), kütlə (kq, q) vahidlərini bilir"
  ),
  "3" = list(
    "Ədədlər və əməllər" = "R3.1 — Çoxrəqəmli ədədlərlə toplama, çıxma; vurma cədvəli, sadə bölmə",
    "Həndəsə" = "R3.3 — Perimetri hesablayır, simmetriya oxu tapır",
    "Ölçmə" = "R3.5 — Zaman (saat, dəq, san), pul (manat, qəpik) vahidləri ilə əməllər"
  ),
  "4" = list(
    "Ədədlər və əməllər" = "R4.1 — Çoxrəqəmli ədədlərlə vurma, bölmə; sadə kəsrlər, onluq kəsrlərə giriş",
    "Həndəsə" = "R4.3 — Düzbucaqlı və kvadratın sahəsini hesablayır, bucaq ölçür",
    "Ölçmə" = "R4.5 — Həcm, tutum vahidləri (litr, ml), çevirmələr"
  ),
  "5" = list(
    "Ədədlər və əməllər" = "R5.1 — Onluq kəsrlər, adi kəsrlər, əməllər, müqayisə, yuvarlaqlaşdırma",
    "Cəbr" = "R5.2 — Sadə tənliklər, bərabərsizliklər, dəyişən anlayışı",
    "Həndəsə" = "R5.3 — Üçbucaq və dördbucaqlıların perimetri, sahəsi; çevrə uzunluğu",
    "Statistika" = "R5.4 — Sütunlu və dairəvi diaqramlar, orta ədəd hesablanması"
  ),
  "6" = list(
    "Ədədlər və əməllər" = "R6.1 — Müsbət/mənfi ədədlər, rasional ədədlər, faiz, nisbət, tənasüb",
    "Cəbr" = "R6.2 — Cəbri ifadələr, xətti tənliklər, bərabərsizliklər",
    "Həndəsə" = "R6.3 — Bucaqlar, paralel xətlər, üçbucaq xassələri, simmetriya",
    "Statistika" = "R6.4 — Statistik verilənlər, median, moda, orta hesabi"
  ),
  "7" = list(
    "Ədədlər və əməllər" = "R7.1 — Nisbət, tənasüb, düz/tərs mütənasiblik, faiz hesablamaları",
    "Cəbr" = "R7.2 — Xətti funksiya, qrafik qurmaq, tənliklər sistemi",
    "Həndəsə" = "R7.3 — Çevrə, dairə sahəsi, Pifaqor teoreminə giriş",
    "Statistika" = "R7.4 — Ehtimal anlayışı, klassik ehtimal, kombinatorika əsasları"
  ),
  "8" = list(
    "Cəbr" = "R8.1 — Kvadrat köklər, irrasional ədədlər, çoxhədlilər, vuruqlara ayırma",
    "Həndəsə" = "R8.2 — Pifaqor teoremi, oxşar üçbucaqlar, vektor anlayışı",
    "Statistika" = "R8.3 — Ehtimal, statistik yayılma göstəriciləri"
  ),
  "9" = list(
    "Cəbr" = "R9.1 — Kvadrat tənliklər, diskriminant, Vyet teoremi, tənliklər sistemi",
    "Həndəsə" = "R9.2 — Triqonometriya (sin, cos, tg), vektor əməlləri, koordinat metodu",
    "Statistika" = "R9.3 — Kombinatorika (yerləşdirmə, birləşmə), ehtimal nəzəriyyəsi"
  ),
  "10" = list(
    "Cəbr" = "R10.1 — Triqonometrik, göstərici, loqarifmik funksiyalar və tənliklər",
    "Həndəsə" = "R10.2 — Fəza həndəsəsi: prizma, piramida, həcm və sahə",
    "Statistika" = "R10.3 — Statistik paylanmalar, standart kənarlaşma, reqressiya"
  ),
  "11" = list(
    "Cəbr" = "R11.1 — Limit, törəmə, inteqral, tətbiqləri",
    "Həndəsə" = "R11.2 — Silindr, konus, kürə; fırlanma cisimləri, həcm",
    "Statistika" = "R11.3 — Ehtimal nəzəriyyəsi, böyük ədədlər qanunu, normal paylanma"
  )
)

# ─── CHUNK OXUMA FUNKSİYALARI ────────────────────────────────

load_chunks_for_grade <- function(grade) {
  pattern <- sprintf("sinif%d_.*_chunks\\.json$", grade)
  files <- list.files(CHUNKS_DIR, pattern = pattern, full.names = TRUE)
  all_chunks <- list()
  for (f in files) {
    tryCatch({
      chunks <- fromJSON(f, simplifyVector = FALSE)
      all_chunks <- c(all_chunks, chunks)
    }, error = function(e) {
      message("Chunk oxuma xətası: ", f, " — ", e$message)
    })
  }
  all_chunks
}

get_topics_for_grade <- function(grade) {
  chunks <- load_chunks_for_grade(grade)
  topics <- unique(sapply(chunks, function(c) {
    ch <- c$chapter
    if (!is.null(ch) && nchar(ch) > 0) ch else c$topic
  }))
  topics <- topics[!is.na(topics) & nchar(topics) > 0]
  topics <- topics[order(topics)]
  if (length(topics) == 0) topics <- c("Mövzu tapılmadı")
  topics
}

search_chunks <- function(grade, topic, max_results = 3) {
  chunks <- load_chunks_for_grade(grade)
  if (length(chunks) == 0) return(list())
  
  topic_lower <- tolower(topic)
  topic_words <- strsplit(topic_lower, "\\s+")[[1]]
  topic_words <- topic_words[nchar(topic_words) >= 3]
  
  scored <- list()
  for (ch in chunks) {
    score <- 0
    searchable <- tolower(paste(
      ch$text %||% "", ch$topic %||% "", ch$chapter %||% "",
      paste(ch$keywords %||% character(0), collapse = " ")
    ))
    if (grepl(topic_lower, searchable, fixed = TRUE)) score <- score + 10
    for (w in topic_words) {
      score <- score + min(length(gregexpr(w, searchable, fixed = TRUE)[[1]]), 5)
    }
    ch_title <- tolower(ch$chapter %||% "")
    if (nchar(ch_title) > 0 && grepl(topic_lower, ch_title, fixed = TRUE)) score <- score + 15
    if (score > 0) scored <- c(scored, list(list(score = score, chunk = ch)))
  }
  
  scored <- scored[order(-sapply(scored, function(x) x$score))]
  lapply(head(scored, max_results), function(x) x$chunk)
}

build_context <- function(grade, topic) {
  results <- search_chunks(grade, topic)
  if (length(results) == 0) return(sprintf("[Sinif %d, '%s' mövzusu üçün dərslik konteksti tapılmadı]", grade, topic))
  
  parts <- character(0)
  for (ch in results) {
    text <- ch$text %||% ""
    if (nchar(text) > 4000) text <- paste0(substr(text, 1, 4000), "\n... [davamı dərslikdə]")
    parts <- c(parts, sprintf(
      "\n━━━ Dərslik: %s, səh. %d-%d ━━━\nFəsil: %s\nAçar sözlər: %s\n\n%s\n",
      ch$source_file %||% "?", ch$page_start, ch$page_end,
      ch$chapter %||% "—",
      paste(head(ch$keywords %||% character(0), 10), collapse = ", "),
      text
    ))
  }
  paste(parts, collapse = "\n")
}

# ─── CLAUDE API ───────────────────────────────────────────────

call_claude <- function(prompt, api_key) {
  if (nchar(api_key) < 10) {
    return(list(success = FALSE, error = "API açar daxil edilməyib. Yuxarıdakı sahəyə ANTHROPIC_API_KEY yazın."))
  }
  
  tryCatch({
    resp <- POST(
      url = CLAUDE_ENDPOINT,
      add_headers(
        `x-api-key` = api_key,
        `anthropic-version` = "2023-06-01",
        `content-type` = "application/json"
      ),
      body = toJSON(list(
        model = CLAUDE_MODEL,
        max_tokens = 8000,
        messages = list(list(role = "user", content = prompt))
      ), auto_unbox = TRUE),
      encode = "raw",
      timeout(120)
    )
    
    result <- content(resp, "parsed", encoding = "UTF-8")
    
    if (resp$status_code == 200) {
      text <- result$content[[1]]$text
      list(success = TRUE, text = text)
    } else {
      err_msg <- result$error$message %||% paste("HTTP", resp$status_code)
      list(success = FALSE, error = err_msg)
    }
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

# ─── PROMPT BUİLDERLƏR ───────────────────────────────────────

build_test_prompt <- function(grade, topic, standard, context, count, blooms, dok, difficulty) {
  bloom_str <- paste(blooms, collapse = ", ")
  
  sprintf('Sən Azərbaycan Riyaziyyat müəllimlər üçün dünya standartlarında test tapşırıqları yaradan ekspert AI-san.

SİNİF: %d-ci sinif
MÖVZU: %s
STANDART: %s
TAPŞIRIQ SAYI: %d
BLOOM SEVİYYƏLƏRİ: %s
DOK SEVİYYƏSİ: %d
ÇƏTİNLİK: %s

═══ DƏRSLİKDƏN KONTEKST ═══
%s

═══ TƏLİMAT ═══

%d tapşırıq yarat. NƏTİCƏNİ TAM HTML FORMATINDA VER. Aşağıdakı HTML şablonuna uyğun yaz.
Cavabın YÜZ FАİZ HTML olsun, heç bir markdown olmasın.

QAYDALAR:
1. Dərslikdəki TERMİNOLOGİYANI istifadə et
2. Dərslik SƏHİFƏ NÖMRƏSİNƏ istinad et
3. Real həyat konteksti: Bakı, manat, Xəzər, metro, ASAN xidmət
4. Hər tapşırığın cavab açarı + həlli olsun
5. Açıq cavablarda rubrika (0-1-2-3 bal)
6. Distraktor analizi (çoxseçimli suallarda)

HTML FORMATI:

<div class="test-header">
  <h1>📐 Riyaziyyat Test Tapşırıqları</h1>
  <div class="meta-grid">
    <div class="meta-item"><span class="label">Sinif:</span> %d-ci sinif</div>
    <div class="meta-item"><span class="label">Mövzu:</span> %s</div>
    <div class="meta-item"><span class="label">Standart:</span> %s</div>
    <div class="meta-item"><span class="label">Tapşırıq sayı:</span> %d</div>
  </div>
</div>

Hər tapşırıq üçün:
<div class="question-block bloom-[səviyyə]">
  <div class="question-header">
    <span class="bloom-badge">[EMOJI] BLOOM: [SƏVİYYƏ]</span>
    <span class="dok-badge">DOK-[N]</span>
  </div>
  <div class="question-text">
    <strong>[N].</strong> [Tapşırıq mətni]
  </div>
  <div class="options"> (çoxseçimli üçün)
    <div class="option">A) ...</div>
    <div class="option">B) ...</div>
    <div class="option">C) ...</div>
    <div class="option">D) ...</div>
  </div>
  <div class="answer-box">
    <div class="answer">✅ Cavab: [X]</div>
    <div class="solution">📝 Həll: [addım-addım]</div>
    <div class="textbook-ref">📖 Dərslik: səh. XX</div>
    <div class="difficulty">📊 Çətinlik: [asan/orta/çətin] │ ⏱️ [X] dəq │ 🎯 [X] bal</div>
  </div>
</div>

Sonda statistika:
<div class="stats-block">
  <h3>📊 Test Statistikası</h3>
  <div class="stat-row">Bloom paylanması: ...</div>
  <div class="stat-row">DOK paylanması: ...</div>
  <div class="stat-row">🌍 PISA ✅ TIMSS ✅ Sinqapur ✅ Finlandiya ✅</div>
</div>

Bloom emoji-ləri: 🟤Xatırlama, 🟢Anlama, 🔵Tətbiqetmə, 🟡Təhlil, 🟠Qiymətləndirmə, 🔴Yaratma',
    grade, topic, standard, count, bloom_str, dok, difficulty,
    context, count, grade, topic, standard, count
  )
}

build_lesson_prompt <- function(grade, topic, standard, context, duration, blooms, dok) {
  bloom_str <- paste(blooms, collapse = ", ")
  
  sprintf('Sən Finlandiya+Sinqapur modelində dünya standartlarında dərs planları hazırlayan metodist AI-san.

SİNİF: %d-ci sinif
MÖVZU: %s
STANDART: %s
MÜDDƏT: %d dəqiqə
BLOOM: %s
DOK: %d

═══ DƏRSLİKDƏN KONTEKST ═══
%s

═══ TƏLİMAT ═══

%d dəqiqəlik dərs planı yarat. NƏTİCƏNİ TAM HTML FORMATINDA VER.
Cavabın YÜZ FАİZ HTML olsun, heç bir markdown olmasın.

QAYDALAR:
1. Dərslikdəki terminologiya, tapşırıq nömrələri, səhifə istinadları
2. Sinqapur CPA: Konkret → Təsviri → Mücərrəd
3. Diferensiasiya: 🟢Baza / 🟡Orta / 🔴Yüksək
4. Hər mərhələdə: müəllim + şagird fəaliyyəti + vaxt + qiymətləndirmə

HTML FORMATI:

<div class="lesson-header">
  <h1>📐 Dərs Planı</h1>
  <div class="meta-grid">
    <div class="meta-item"><span class="label">Sinif:</span> %d-ci sinif</div>
    <div class="meta-item"><span class="label">Mövzu:</span> %s</div>
    <div class="meta-item"><span class="label">Müddət:</span> %d dəqiqə</div>
    <div class="meta-item"><span class="label">Standart:</span> %s</div>
  </div>
  <div class="objectives">
    <h3>🎯 Təlim Nəticələri</h3>
    <ul>
      <li>[Bilik — Bloom: Xatırlama]</li>
      <li>[Bacarıq — Bloom: Tətbiqetmə]</li>
      <li>[Tətbiq — Bloom: Təhlil]</li>
    </ul>
  </div>
</div>

5 mərhələ, hər biri <div class="phase"> içində:

<div class="phase phase-1">
  <div class="phase-header">
    <span class="phase-icon">📍</span>
    <h3>MƏRHƏLƏ 1: MOTİVASİYA</h3>
    <span class="phase-time">⏱️ %d dəq</span>
  </div>
  <div class="phase-content">
    <div class="teacher-activity">👨‍🏫 Müəllim: ...</div>
    <div class="student-activity">👨‍🎓 Şagird: ...</div>
    <div class="textbook-ref">📖 Dərslik: səh. XX</div>
    <div class="assessment">📊 Qiymətləndirmə: diaqnostik</div>
  </div>
</div>

Mərhələlər:
1. Motivasiya (10%% — %d dəq) — dərslikdən "Araşdır", real həyat sualı
2. Yeni bilik (30%% — %d dəq) — Sinqapur CPA, kəşf, qrup işi, lövhə yazısı
3. Birgə tətbiq (25%% — %d dəq) — Mən→Biz→Sən, dərslikdən tapşırıqlar
4. Müstəqil tətbiq (25%% — %d dəq) — 🟢Baza/🟡Orta/🔴Yüksək, PISA tipli
5. Yekunlaşdırma (10%% — %d dəq) — çıxış bileti, ev tapşırığı

Sonda analiz bloku:
<div class="analysis-block">
  <h3>📊 Dərs Analizi</h3>
  <div class="stat-row">Bloom paylanması: ...</div>
  <div class="stat-row">Zaman: Müəllim 30%% │ Şagird 50%% │ Müzakirə 20%%</div>
  <div class="stat-row">📖 Dərslik istinadları: səh. ...</div>
  <div class="stat-row">🌍 PISA ✅ TIMSS ✅ Sinqapur CPA ✅ Finlandiya ✅</div>
</div>',
    grade, topic, standard, duration, bloom_str, dok,
    context, duration,
    grade, topic, duration, standard,
    as.integer(duration * 0.10),
    as.integer(duration * 0.10),
    as.integer(duration * 0.30),
    as.integer(duration * 0.25),
    as.integer(duration * 0.25),
    as.integer(duration * 0.10)
  )
}

# ─── HTML5 STIL ───────────────────────────────────────────────

HTML5_CSS <- '
<style>
@import url("https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&family=JetBrains+Mono&display=swap");

.ai-output {
  font-family: "Noto Sans", sans-serif;
  color: #1a1a2e;
  line-height: 1.7;
  padding: 30px;
  max-width: 900px;
  margin: 0 auto;
}

/* HEADER */
.test-header, .lesson-header {
  background: linear-gradient(135deg, #0a1628 0%, #1a365d 50%, #2d3748 100%);
  color: #fff;
  padding: 32px;
  border-radius: 16px;
  margin-bottom: 28px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.18);
  position: relative;
  overflow: hidden;
}
.test-header::before, .lesson-header::before {
  content: "";
  position: absolute;
  top: -50%; right: -20%;
  width: 400px; height: 400px;
  background: radial-gradient(circle, rgba(59,130,246,0.15) 0%, transparent 70%);
  border-radius: 50%;
}
.test-header h1, .lesson-header h1 {
  font-size: 1.8em;
  font-weight: 700;
  margin: 0 0 20px 0;
  letter-spacing: -0.5px;
}
.meta-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
}
.meta-item {
  background: rgba(255,255,255,0.08);
  padding: 10px 16px;
  border-radius: 8px;
  border-left: 3px solid #3b82f6;
  font-size: 0.95em;
}
.meta-item .label {
  font-weight: 700;
  color: #93c5fd;
}

/* OBJECTIVES */
.objectives {
  margin-top: 20px;
  background: rgba(255,255,255,0.06);
  padding: 16px 20px;
  border-radius: 10px;
}
.objectives h3 { margin: 0 0 10px; color: #fbbf24; }
.objectives ul { margin: 0; padding-left: 20px; }
.objectives li { margin-bottom: 6px; color: #e2e8f0; }

/* QUESTION BLOCKS */
.question-block {
  background: #fff;
  border-radius: 14px;
  padding: 24px;
  margin-bottom: 20px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
  border-left: 5px solid #94a3b8;
  transition: transform 0.2s, box-shadow 0.2s;
}
.question-block:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 24px rgba(0,0,0,0.10);
}
.bloom-xatirlama, .bloom-xatırlama { border-left-color: #78350f; }
.bloom-anlama { border-left-color: #15803d; }
.bloom-tetbiqetme, .bloom-tətbiqetmə { border-left-color: #1d4ed8; }
.bloom-tehlil, .bloom-təhlil { border-left-color: #a16207; }
.bloom-qiymetlendirme, .bloom-qiymətləndirmə { border-left-color: #c2410c; }
.bloom-yaratma { border-left-color: #dc2626; }

.question-header {
  display: flex;
  gap: 10px;
  margin-bottom: 14px;
  flex-wrap: wrap;
}
.bloom-badge, .dok-badge {
  display: inline-block;
  padding: 4px 14px;
  border-radius: 20px;
  font-size: 0.82em;
  font-weight: 700;
  letter-spacing: 0.5px;
}
.bloom-badge { background: #f0f4ff; color: #1e40af; }
.dok-badge { background: #fef3c7; color: #92400e; }

.question-text {
  font-size: 1.05em;
  margin-bottom: 16px;
  line-height: 1.8;
}
.options {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  margin-bottom: 16px;
}
.option {
  background: #f8fafc;
  padding: 10px 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 0.95em;
}

/* ANSWER BOX */
.answer-box {
  background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%);
  border: 1px solid #86efac;
  border-radius: 10px;
  padding: 16px;
}
.answer-box .answer { font-weight: 700; color: #15803d; font-size: 1.05em; margin-bottom: 8px; }
.answer-box .solution { color: #374151; margin-bottom: 6px; white-space: pre-wrap; }
.answer-box .textbook-ref { color: #1d4ed8; font-weight: 600; margin-bottom: 4px; }
.answer-box .difficulty { color: #6b7280; font-size: 0.9em; }
.answer-box .rubric { margin-top: 8px; padding: 10px; background: #fffbeb; border-radius: 6px; border: 1px solid #fde68a; }

/* PHASES */
.phase {
  background: #fff;
  border-radius: 14px;
  padding: 24px;
  margin-bottom: 18px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
  border-left: 5px solid #3b82f6;
}
.phase-1 { border-left-color: #f59e0b; }
.phase-2 { border-left-color: #3b82f6; }
.phase-3 { border-left-color: #10b981; }
.phase-4 { border-left-color: #8b5cf6; }
.phase-5 { border-left-color: #ef4444; }

.phase-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}
.phase-header h3 { margin: 0; font-size: 1.1em; flex-grow: 1; }
.phase-icon { font-size: 1.4em; }
.phase-time {
  background: #f1f5f9;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 0.85em;
  font-weight: 600;
  color: #475569;
}

.teacher-activity, .student-activity, .textbook-ref, .assessment {
  padding: 8px 14px;
  margin-bottom: 8px;
  border-radius: 8px;
  font-size: 0.95em;
}
.teacher-activity { background: #eff6ff; border-left: 3px solid #3b82f6; }
.student-activity { background: #f0fdf4; border-left: 3px solid #22c55e; }
.textbook-ref { background: #fefce8; border-left: 3px solid #eab308; color: #854d0e; font-weight: 600; }
.assessment { background: #faf5ff; border-left: 3px solid #a855f7; }

.differentiation {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin: 12px 0;
}
.diff-level {
  padding: 14px;
  border-radius: 10px;
  font-size: 0.92em;
}
.diff-base { background: #f0fdf4; border: 1px solid #86efac; }
.diff-mid { background: #fffbeb; border: 1px solid #fde68a; }
.diff-high { background: #fef2f2; border: 1px solid #fca5a5; }

/* STATS */
.stats-block, .analysis-block {
  background: linear-gradient(135deg, #0a1628, #1e293b);
  color: #e2e8f0;
  padding: 24px;
  border-radius: 14px;
  margin-top: 24px;
}
.stats-block h3, .analysis-block h3 { margin: 0 0 16px; color: #fbbf24; }
.stat-row {
  padding: 8px 0;
  border-bottom: 1px solid rgba(255,255,255,0.08);
  font-size: 0.95em;
}
.stat-row:last-child { border-bottom: none; }

/* FOOTER */
.arti-footer {
  text-align: center;
  margin-top: 30px;
  padding: 16px;
  color: #94a3b8;
  font-size: 0.85em;
  border-top: 2px solid #e2e8f0;
}

/* PRINT */
@media print {
  .answer-box { page-break-inside: avoid; }
  .question-block { page-break-inside: avoid; }
  .phase { page-break-inside: avoid; }
}
</style>
'

# ─── NULL OPERATOR ────────────────────────────────────────────
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (is.character(x) && nchar(x) == 0)) y else x

# ═══════════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════════
ui <- fluidPage(
  
  tags$head(
    tags$style(HTML('
      @import url("https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&display=swap");
      body { font-family: "Noto Sans", sans-serif; background: #f1f5f9; }
      
      .navbar { background: linear-gradient(135deg, #0a1628, #1a365d) !important; border: none; }
      .navbar-brand { color: #fff !important; font-weight: 700; font-size: 1.3em !important; }
      .navbar-nav > li > a { color: #cbd5e1 !important; font-weight: 600; }
      .navbar-nav > li.active > a { color: #fff !important; background: rgba(59,130,246,0.3) !important; border-radius: 8px; }
      
      .well { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
      .btn-primary { background: #2563eb; border: none; border-radius: 10px; font-weight: 700; padding: 12px 28px; font-size: 1.05em; }
      .btn-primary:hover { background: #1d4ed8; transform: translateY(-1px); }
      .btn-success { background: #16a34a; border: none; border-radius: 10px; font-weight: 700; padding: 12px 28px; }
      .btn-warning { background: #d97706; border: none; border-radius: 10px; font-weight: 700; padding: 12px 28px; color:#fff; }
      
      .form-group label { font-weight: 600; color: #334155; }
      .form-control, .selectize-input { border-radius: 8px !important; border: 2px solid #e2e8f0 !important; }
      .form-control:focus, .selectize-input.focus { border-color: #3b82f6 !important; box-shadow: 0 0 0 3px rgba(59,130,246,0.15) !important; }
      
      .section-title { font-size: 1.5em; font-weight: 700; color: #0f172a; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 3px solid #3b82f6; }
      
      .api-key-box { background: #fffbeb; border: 2px solid #f59e0b; border-radius: 12px; padding: 16px; margin-bottom: 20px; }
      
      .loading-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(15,23,42,0.7); z-index: 9999; display: flex; align-items: center; justify-content: center; }
      .loading-spinner { background: #fff; padding: 40px; border-radius: 16px; text-align: center; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
      .spinner { width: 50px; height: 50px; border: 4px solid #e2e8f0; border-top-color: #3b82f6; border-radius: 50%; animation: spin 0.8s linear infinite; margin: 0 auto 16px; }
      @keyframes spin { to { transform: rotate(360deg); } }
      
      .output-container { background: #fff; border-radius: 16px; padding: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
      
      .tab-content { padding-top: 20px; }
      .footer { text-align: center; padding: 20px; color: #94a3b8; font-size: 0.9em; margin-top: 40px; }
    '))
  ),
  
  navbarPage(
    title = "📐 Riyaziyyat Müəllim Agent",
    id = "main_nav",
    
    # ── TAB 1: TEST TAPŞIRIQLARI ────────────────────
    tabPanel("🎯 Test Tapşırıqları",
      fluidRow(
        column(12,
          div(class = "api-key-box",
            fluidRow(
              column(8, passwordInput("api_key", "🔑 ANTHROPIC_API_KEY:", value = CLAUDE_API_KEY, width = "100%")),
              column(4, tags$p(style="margin-top:25px; color:#92400e;", "API açarınızı console.anthropic.com saytından alın"))
            )
          )
        )
      ),
      
      fluidRow(
        column(3, wellPanel(
          h4("📚 Sinif və Mövzu", style="margin-top:0"),
          selectInput("test_grade", "Sinif:", choices = as.character(1:11), selected = "6"),
          uiOutput("test_standard_ui"),
          uiOutput("test_topic_ui"),
          hr(),
          h4("⚙️ Parametrlər"),
          numericInput("test_count", "Tapşırıq sayı:", value = 12, min = 5, max = 30),
          checkboxGroupInput("test_bloom", "Bloom səviyyələri:",
            choices = c("Xatırlama" = "Xatırlama", "Anlama" = "Anlama", "Tətbiqetmə" = "Tətbiqetmə",
                        "Təhlil" = "Təhlil", "Qiymətləndirmə" = "Qiymətləndirmə", "Yaratma" = "Yaratma"),
            selected = c("Xatırlama","Anlama","Tətbiqetmə","Təhlil","Qiymətləndirmə")
          ),
          sliderInput("test_dok", "DOK Səviyyəsi:", min = 1, max = 4, value = 3),
          selectInput("test_diff", "Çətinlik:", choices = c("Asan-Orta" = "asan-orta", "Qarışıq (PISA)" = "qarisiq", "Orta-Çətin" = "orta-cetin")),
          hr(),
          actionButton("test_generate", "🤖 Test Yarat", class = "btn-primary btn-block", style = "font-size:1.1em; padding:14px;")
        )),
        
        column(9,
          div(class = "output-container", uiOutput("test_output"))
        )
      )
    ),
    
    # ── TAB 2: DƏRS PLANI ───────────────────────────
    tabPanel("📋 Dərs Planı",
      fluidRow(
        column(3, wellPanel(
          h4("📚 Sinif və Mövzu", style="margin-top:0"),
          selectInput("lesson_grade", "Sinif:", choices = as.character(1:11), selected = "6"),
          uiOutput("lesson_standard_ui"),
          uiOutput("lesson_topic_ui"),
          hr(),
          h4("⚙️ Parametrlər"),
          numericInput("lesson_duration", "Müddət (dəqiqə):", value = 45, min = 30, max = 120, step = 15),
          checkboxGroupInput("lesson_bloom", "Bloom:",
            choices = c("Xatırlama","Anlama","Tətbiqetmə","Təhlil","Qiymətləndirmə","Yaratma"),
            selected = c("Anlama","Tətbiqetmə","Təhlil")
          ),
          sliderInput("lesson_dok", "DOK:", min = 1, max = 4, value = 2),
          hr(),
          actionButton("lesson_generate", "🤖 Dərs Planı Yarat", class = "btn-success btn-block", style = "font-size:1.1em; padding:14px;")
        )),
        
        column(9,
          div(class = "output-container", uiOutput("lesson_output"))
        )
      )
    ),
    
    # ── TAB 3: DƏRSLİK ──────────────────────────────
    tabPanel("📖 Dərslik Məzmunu",
      fluidRow(
        column(3, wellPanel(
          selectInput("book_grade", "Sinif:", choices = as.character(1:11), selected = "6"),
          uiOutput("book_topic_ui"),
          actionButton("book_search", "🔍 Axtar", class = "btn-warning btn-block")
        )),
        column(9,
          div(class = "output-container", style = "padding:20px;", uiOutput("book_output"))
        )
      )
    )
  ),
  
  tags$div(class = "footer", "📐 ARTI 2026 — Qiymətləndirmə, Analiz və Monitorinq │ Tariyel Talibov │ Riyaziyyat Müəllim Agent v2.0")
)

# ═══════════════════════════════════════════════════════════════
# SERVER
# ═══════════════════════════════════════════════════════════════
server <- function(input, output, session) {

  # ── Reactive: standartlar ──
  get_standards <- function(grade) {
    STANDARDS[[as.character(grade)]] %||% list("Standart tapılmadı" = "—")
  }
  
  # ── TEST: Standart seçimi ──
  output$test_standard_ui <- renderUI({
    stds <- get_standards(input$test_grade)
    selectInput("test_standard", "Standart:", choices = names(stds))
  })
  
  # ── TEST: Mövzu seçimi (dərslikdən) ──
  output$test_topic_ui <- renderUI({
    grade <- as.integer(input$test_grade)
    topics <- get_topics_for_grade(grade)
    selectizeInput("test_topic", "Dərslik mövzusu:", choices = topics,
                   options = list(placeholder = "Mövzu seçin və ya yazın", create = TRUE))
  })
  
  # ── LESSON: Standart ──
  output$lesson_standard_ui <- renderUI({
    stds <- get_standards(input$lesson_grade)
    selectInput("lesson_standard", "Standart:", choices = names(stds))
  })
  
  # ── LESSON: Mövzu ──
  output$lesson_topic_ui <- renderUI({
    grade <- as.integer(input$lesson_grade)
    topics <- get_topics_for_grade(grade)
    selectizeInput("lesson_topic", "Dərslik mövzusu:", choices = topics,
                   options = list(placeholder = "Mövzu seçin və ya yazın", create = TRUE))
  })
  
  # ── BOOK: Mövzu ──
  output$book_topic_ui <- renderUI({
    grade <- as.integer(input$book_grade)
    topics <- get_topics_for_grade(grade)
    selectizeInput("book_topic", "Mövzu:", choices = topics,
                   options = list(placeholder = "Mövzu seçin", create = TRUE))
  })
  
  # ══════════════════════════════════════════════════
  # TEST GENERASİYASI
  # ══════════════════════════════════════════════════
  observeEvent(input$test_generate, {
    req(input$test_grade, input$test_topic, input$test_standard)
    
    grade   <- as.integer(input$test_grade)
    topic   <- input$test_topic
    std_key <- input$test_standard
    std_val <- get_standards(grade)[[std_key]] %||% std_key
    count   <- input$test_count
    blooms  <- input$test_bloom
    dok     <- input$test_dok
    diff    <- input$test_diff
    api_key <- input$api_key
    
    # Dərslikdən kontekst
    context <- build_context(grade, topic)
    
    # Prompt
    prompt <- build_test_prompt(grade, topic, std_val, context, count, blooms, dok, diff)
    
    output$test_output <- renderUI({
      tagList(
        tags$div(class = "loading-spinner-inline", style = "text-align:center; padding:60px;",
          tags$div(class = "spinner", style = "width:50px; height:50px; border:4px solid #e2e8f0; border-top-color:#3b82f6; border-radius:50%; animation:spin 0.8s linear infinite; margin: 0 auto 16px;"),
          tags$p(style = "font-size:1.1em; color:#475569;", "🤖 AI test tapşırıqlarını yaradır..."),
          tags$p(style = "color:#94a3b8;", sprintf("Sinif %d │ %s │ %d tapşırıq", grade, topic, count))
        )
      )
    })
    
    # API çağırışı
    result <- call_claude(prompt, api_key)
    
    if (result$success) {
      html_content <- result$text
      
      output$test_output <- renderUI({
        tagList(
          HTML(HTML5_CSS),
          tags$div(class = "ai-output", HTML(html_content)),
          tags$div(class = "arti-footer",
            sprintf("📐 ARTI 2026 │ Sinif %d │ %s │ %s │ %d tapşırıq", grade, topic, std_val, count)
          )
        )
      })
    } else {
      output$test_output <- renderUI({
        tags$div(style = "padding:40px; text-align:center;",
          tags$h3("❌ Xəta", style = "color:#dc2626;"),
          tags$p(result$error),
          tags$p(style = "color:#6b7280;", "API açarını yoxlayın. console.anthropic.com → API Keys")
        )
      })
    }
  })
  
  # ══════════════════════════════════════════════════
  # DƏRS PLANI GENERASİYASI
  # ══════════════════════════════════════════════════
  observeEvent(input$lesson_generate, {
    req(input$lesson_grade, input$lesson_topic, input$lesson_standard)
    
    grade    <- as.integer(input$lesson_grade)
    topic    <- input$lesson_topic
    std_key  <- input$lesson_standard
    std_val  <- get_standards(grade)[[std_key]] %||% std_key
    duration <- input$lesson_duration
    blooms   <- input$lesson_bloom
    dok      <- input$lesson_dok
    api_key  <- input$api_key
    
    context <- build_context(grade, topic)
    prompt  <- build_lesson_prompt(grade, topic, std_val, context, duration, blooms, dok)
    
    output$lesson_output <- renderUI({
      tagList(
        tags$div(style = "text-align:center; padding:60px;",
          tags$div(class = "spinner", style = "width:50px; height:50px; border:4px solid #e2e8f0; border-top-color:#16a34a; border-radius:50%; animation:spin 0.8s linear infinite; margin: 0 auto 16px;"),
          tags$p(style = "font-size:1.1em; color:#475569;", "🤖 AI dərs planı yaradır..."),
          tags$p(style = "color:#94a3b8;", sprintf("Sinif %d │ %s │ %d dəqiqə", grade, topic, duration))
        )
      )
    })
    
    result <- call_claude(prompt, api_key)
    
    if (result$success) {
      output$lesson_output <- renderUI({
        tagList(
          HTML(HTML5_CSS),
          tags$div(class = "ai-output", HTML(result$text)),
          tags$div(class = "arti-footer",
            sprintf("📐 ARTI 2026 │ Sinif %d │ %s │ %d dəqiqə │ %s", grade, topic, duration, std_val)
          )
        )
      })
    } else {
      output$lesson_output <- renderUI({
        tags$div(style = "padding:40px; text-align:center;",
          tags$h3("❌ Xəta", style = "color:#dc2626;"),
          tags$p(result$error)
        )
      })
    }
  })
  
  # ══════════════════════════════════════════════════
  # DƏRSLİK AXTARIŞI
  # ══════════════════════════════════════════════════
  observeEvent(input$book_search, {
    req(input$book_grade, input$book_topic)
    
    grade <- as.integer(input$book_grade)
    topic <- input$book_topic
    results <- search_chunks(grade, topic, max_results = 5)
    
    if (length(results) == 0) {
      output$book_output <- renderUI({
        tags$div(style = "text-align:center; padding:40px;",
          tags$h3("🔍 Nəticə tapılmadı"),
          tags$p(sprintf("Sinif %d, mövzu: '%s'", grade, topic))
        )
      })
      return()
    }
    
    output$book_output <- renderUI({
      chunk_divs <- lapply(results, function(ch) {
        text_preview <- substr(ch$text %||% "", 1, 2000)
        keywords <- paste(head(ch$keywords %||% character(0), 10), collapse = ", ")
        
        tags$div(style = "background:#fff; border-radius:12px; padding:20px; margin-bottom:16px; border-left:4px solid #2563eb; box-shadow: 0 2px 8px rgba(0,0,0,0.05);",
          tags$div(style = "display:flex; gap:12px; margin-bottom:12px; flex-wrap:wrap;",
            tags$span(style = "background:#eff6ff; color:#1d4ed8; padding:4px 12px; border-radius:16px; font-weight:700; font-size:0.85em;",
              sprintf("📄 səh. %d-%d", ch$page_start, ch$page_end)),
            tags$span(style = "background:#fef3c7; color:#92400e; padding:4px 12px; border-radius:16px; font-size:0.85em;",
              ch$source_file %||% "?")
          ),
          if (!is.null(ch$chapter) && nchar(ch$chapter) > 0) tags$h4(style = "margin:0 0 8px; color:#0f172a;", ch$chapter),
          if (nchar(keywords) > 0) tags$p(style = "color:#6b7280; font-size:0.9em;", paste("🔑", keywords)),
          tags$pre(style = "background:#f8fafc; padding:16px; border-radius:8px; white-space:pre-wrap; font-size:0.9em; max-height:400px; overflow-y:auto; font-family:'Noto Sans',sans-serif; line-height:1.6;",
            text_preview
          )
        )
      })
      
      tagList(
        tags$h3(style = "color:#0f172a; margin-bottom:16px;",
          sprintf("📚 Sinif %d — '%s' — %d nəticə", grade, topic, length(results))),
        chunk_divs
      )
    })
  })
}

# ─── RUN ──────────────────────────────────────────────────────
shinyApp(ui = ui, server = server, options = list(
  host = "127.0.0.1",
  port = as.integer(Sys.getenv("SHINY_PORT", "4040")),
  launch.browser = TRUE
))
