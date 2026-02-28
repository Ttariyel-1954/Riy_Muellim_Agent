# 🎓 MÜƏLLİM AGENT - Claude Code ilə İşləmə Təlimatı

## ARTI 2026 - Tariyel Talibov

---

## 📦 1. Claude Code Quraşdırılması

Claude Code-u quraşdırmaq üçün Mac terminalda:

```bash
# Node.js lazımdır (v18+)
node -v

# Claude Code quraşdır
npm install -g @anthropic-ai/claude-code

# API açarını təyin et
export ANTHROPIC_API_KEY="sk-ant-api03-SİZİN_AÇARINIZ"

# Yoxla
claude --version
```

> 📖 Tam sənədləşdirmə: https://docs.claude.com/en/docs/claude-code/overview

---

## 🚀 2. Layihəni Claude Code ilə Başlatmaq

```bash
# Desktop-da layihə qovluğuna keçin
cd ~/Desktop/Muellim_agent

# Claude Code-u bu layihədə işə salın
claude

# Claude Code açılacaq və CLAUDE.md faylını avtomatik oxuyacaq
```

---

## 📋 3. Claude Code-da Əsas Əmrlər

Claude Code interaktiv terminaldır. Aşağıdakı sorğuları yazın:

### 🔧 İlkin Quraşdırma
```
> npm install quraşdır və setup.sh skriptini işlət
```

```
> PostgreSQL bazası yarat: muellim_agent adında, sonra migrasiyaları işlət
```

```
> .env faylını mənim Anthropic API açarımla konfiqurasiya et
```

### 📊 Verilənlər Bazası
```
> database/migrations/001_schema.sql faylını PostgreSQL-də işlət
```

```
> database/seeds/001_standards_seed.sql faylını işlədərək fənn standartlarını yüklə
```

```
> Yeni fənn standartı əlavə et: 8-ci sinif Riyaziyyat, mövzu "Kvadrat tənliklər"
```

### 🤖 Agent-ləri Test Etmək
```
> Serveri işə sal: npm start
```

```
> curl ilə /api/v1/health endpoint-ini yoxla
```

```
> 6-cı sinif Riyaziyyat, "Faizlər" mövzusu üçün dərs planı yaradan test sorğusu göndər
```

### 📝 Yeni Funksionallıq Əlavə Etmək
```
> Assessment agent-ə MST (Multi-Stage Testing) modulu əlavə et
```

```
> Student Progress agent-ə davamiyyət xəbərdarlıq sistemi əlavə et - 
  3 gün ardıcıl gəlməyən şagirdlər üçün avtomatik alert
```

```
> R Shiny dashboard-a yeni tab əlavə et: "Müqayisəli Analiz" - 
  məktəblər arası nəticə müqayisəsi
```

---

## 🎯 4. Konkret Tapşırıqlar üçün Claude Code Sorğuları

### Agent 1: Tədris Planlaşdırılması
```
> src/agents/lesson_planning/index.js faylını aç və generateLessonPlan 
  funksiyasına STEAM metodu dəstəyi əlavə et
```

```
> Yeni endpoint yarat: POST /api/v1/lessons/annual-plan - 
  illik tədris planı generasiyası
```

### Agent 2: Qiymətləndirmə
```
> CAT (Computer Adaptive Testing) modulu üçün unit test yaz
```

```
> IRT 3PL model parametrlərinin kalibrasiyası üçün yeni funksiya əlavə et
```

```
> Rubrik əsaslı Azərbaycan dili esse qiymətləndirmə modulunu genişləndir
```

### Agent 3: Pedaqoji Dəstək
```
> Yeni metod əlavə et: Flipped Classroom (Tərsinə sinif) strategiyası
```

### Agent 4: Rəqəmsal Köməkçi
```
> Google Classroom API inteqrasiyasını tamamla - 
  OAuth2 authentication və assignment sync
```

```
> PowerPoint generasiyasına template sistemi əlavə et - 
  ARTI brendinq ilə
```

### Agent 5: Şagird Analizi
```
> Risk detection alqoritmini təkmilləşdir: 
  maşın öyrənməsi ilə erkən xəbərdarlıq sistemi
```

```
> Şagird profilinin PDF raport kimi export edilməsi
```

### Agent 6: Kommunikasiya
```
> WhatsApp Business API inteqrasiyası əlavə et
```

```
> SMS göndərmə modulu yarat (Azərbaycan operatorları üçün)
```

---

## 🔄 5. Claude Code ilə Database İdarəsi

```
> Yeni migrasiya faylı yarat: homework_tracking cədvəli əlavə et - 
  şagird, fənn, tapşırıq, status, vaxt sütunları ilə
```

```
> Seeds faylına 8-ci sinif Kimya standartlarını əlavə et
```

```
> v_student_dashboard view-unu genişləndir: 
  ev tapşırığı tamamlama faizi əlavə et
```

```
> PostgreSQL-də performance analiz et: yavaş sorğuları tap və index əlavə et
```

---

## 📊 6. R Shiny Dashboard Genişləndirmə

```
> R Shiny app-a yeni modul əlavə et: Müəllim Performans Analizi - 
  dərs planları, test nəticələri, resurs paylaşımı statistikası
```

```
> Dashboard-a real-time notification sistemi əlavə et
```

```
> Plotly qrafikləri Azərbaycan dilində lokalizasiya et
```

---

## 🧪 7. Test və Debug

```
> Jest ilə bütün agent-lər üçün unit test yaz
```

```
> API endpoint-ləri üçün integration test yarat
```

```
> Serveri debug rejimində işlət və /api/v1/lessons/generate endpoint-ini test et
```

---

## 🚢 8. Deploy (DigitalOcean)

```
> Dockerfile yarat: Node.js serveri, PostgreSQL, R Shiny üçün 
  docker-compose.yml hazırla
```

```
> DigitalOcean droplet-ə deploy etmək üçün 
  CI/CD pipeline (GitHub Actions) qur
```

```
> SSL sertifikat üçün nginx reverse proxy konfiqurasiyası yaz
```

---

## 💡 9. Faydalı Claude Code Shortcut-ları

| Əmr | Təsvir |
|------|--------|
| `/help` | Kömək menyusu |
| `/clear` | Ekranı təmizlə |
| `/cost` | Token istifadəsi |
| `/compact` | Konteksti sıxlaşdır |
| `Ctrl+C` | Cari əməliyyatı dayandır |
| `Ctrl+D` | Claude Code-dan çıx |

---

## ⚙️ 10. Konfiqurasiya (.claude/settings.json)

Claude Code-un layihə səviyyəsində konfiqurasiyası:

```json
{
  "permissions": {
    "allow": [
      "bash(npm *)",
      "bash(node *)",
      "bash(psql *)",
      "bash(curl *)",
      "bash(mkdir *)",
      "bash(cat *)",
      "read(**)",
      "write(src/**)",
      "write(database/**)",
      "write(r_shiny/**)",
      "write(scripts/**)",
      "write(tests/**)"
    ]
  }
}
```

---

## 📞 Əlaqə

- **Layihə:** ARTI 2026 - Müəllim Agent
- **Müəllif:** Talıbov Tariyel İsmayıl oğlu
- **Vəzifə:** ARTI Qiymətləndirmə Departamenti Direktor Müavini
- **GitHub:** Ttariyel-1954
- **Web:** ttariyel.tech
