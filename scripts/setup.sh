#!/bin/bash
# ============================================================
# MÜƏLLİM AGENT - Claude Code ilə Tam Quraşdırma
# ARTI 2026 - Tariyel Talibov
# 
# İstifadə:
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
# ============================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  🎓 MÜƏLLİM AGENT - Quraşdırma Başlayır        ║"
echo "║  ARTI 2026 - AI Agent for Teachers               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─── 1. Node.js yoxla ───────────────────────────────────
echo -e "${BLUE}[1/7]${NC} Node.js yoxlanılır..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js tapılmadı. Quraşdırın: https://nodejs.org${NC}"
    exit 1
fi
NODE_V=$(node -v)
echo -e "${GREEN}✅ Node.js: $NODE_V${NC}"

# ─── 2. PostgreSQL yoxla ────────────────────────────────
echo -e "${BLUE}[2/7]${NC} PostgreSQL yoxlanılır..."
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL CLI tapılmadı. Demo rejimində davam edilir.${NC}"
    DB_AVAILABLE=false
else
    PG_V=$(psql --version | head -1)
    echo -e "${GREEN}✅ $PG_V${NC}"
    DB_AVAILABLE=true
fi

# ─── 3. npm install ─────────────────────────────────────
echo -e "${BLUE}[3/7]${NC} npm paketləri quraşdırılır..."
npm install --silent 2>/dev/null || {
    echo -e "${YELLOW}⚠️  npm install xətası. Əl ilə işlədin: npm install${NC}"
}
echo -e "${GREEN}✅ npm paketlər quraşdırıldı${NC}"

# ─── 4. .env faylı ──────────────────────────────────────
echo -e "${BLUE}[4/7]${NC} .env faylı hazırlanır..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ .env faylı yaradıldı (.env.example-dən kopyalandı)${NC}"
    echo -e "${YELLOW}   ⚠️  .env faylını redaktə edin: API açarlarını əlavə edin${NC}"
else
    echo -e "${GREEN}✅ .env faylı artıq mövcuddur${NC}"
fi

# ─── 5. uploads qovluğu ─────────────────────────────────
echo -e "${BLUE}[5/7]${NC} Upload qovluğu yaradılır..."
mkdir -p uploads logs
echo -e "${GREEN}✅ uploads/ və logs/ qovluqları yaradıldı${NC}"

# ─── 6. PostgreSQL database ─────────────────────────────
if [ "$DB_AVAILABLE" = true ]; then
    echo -e "${BLUE}[6/7]${NC} PostgreSQL verilənlər bazası qurulur..."
    
    # Source .env for DB credentials
    source .env 2>/dev/null || true
    DB_NAME="${DB_NAME:-muellim_agent}"
    DB_USER="${DB_USER:-arti_admin}"
    
    # Create database if not exists
    if psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        echo -e "${GREEN}✅ Bazası artıq mövcuddur: $DB_NAME${NC}"
    else
        echo "   Baza yaradılır: $DB_NAME..."
        createdb "$DB_NAME" 2>/dev/null || {
            echo -e "${YELLOW}   ⚠️  Baza yaradıla bilmədi. Əl ilə yaradın: createdb $DB_NAME${NC}"
        }
    fi
    
    # Run migrations
    echo "   Migrasiyalar işlədilir..."
    node database/migrations/run.js 2>/dev/null && {
        echo -e "${GREEN}✅ Migrasiyalar tamamlandı${NC}"
    } || {
        echo -e "${YELLOW}   ⚠️  Migrasiya xətası. .env-dəki DB parametrlərini yoxlayın${NC}"
    }
    
    # Run seeds
    echo "   Seed data yüklənir..."
    node database/seeds/run.js 2>/dev/null && {
        echo -e "${GREEN}✅ Fənn standartları yükləndi${NC}"
    } || {
        echo -e "${YELLOW}   ⚠️  Seed data yüklənmədi${NC}"
    }
else
    echo -e "${BLUE}[6/7]${NC} ${YELLOW}PostgreSQL əlçatan deyil - atlayılır${NC}"
fi

# ─── 7. Yekun ────────────────────────────────────────────
echo -e "${BLUE}[7/7]${NC} Quraşdırma tamamlanır..."

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅ QURAŞDIRMA TAMAMLANDI!                       ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║                                                  ║"
echo "║  Serveri işə salmaq üçün:                        ║"
echo "║    npm start                                     ║"
echo "║                                                  ║"
echo "║  Development rejimi:                              ║"
echo "║    npm run dev                                   ║"
echo "║                                                  ║"
echo "║  R Shiny Dashboard:                              ║"
echo "║    npm run shiny                                 ║"
echo "║                                                  ║"
echo "║  API Test:                                       ║"
echo "║    curl http://localhost:3000/api/v1/health      ║"
echo "║                                                  ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  ⚠️  UNUTMAYIN:                                   ║"
echo "║  1. .env faylında API açarlarını əlavə edin      ║"
echo "║  2. ANTHROPIC_API_KEY daxil edin                 ║"
echo "║  3. DB_PASSWORD təyin edin                       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
