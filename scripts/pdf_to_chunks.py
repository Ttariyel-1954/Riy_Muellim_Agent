#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
  📐 Riy_Muellim_Agent — PDF Dərslik Emal Pipeline
  
  Bu skript PDF dərsliklərdən mətn çıxarır, mövzu-mövzu
  parçalayır və Claude Code-un istifadə edəcəyi formata
  çevirir.
  
  İstifadə: python3 scripts/pdf_to_chunks.py
═══════════════════════════════════════════════════════════════
"""

import os
import re
import json
import sys

try:
    import pdfplumber
except ImportError:
    print("❌ pdfplumber quraşdırılmayıb. Quraşdırın:")
    print("   pip3 install pdfplumber")
    sys.exit(1)

# ─── KONFİQURASİYA ───
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PDF_DIR = os.path.join(BASE_DIR, "derslikler", "pdf")
CHUNKS_DIR = os.path.join(BASE_DIR, "derslikler", "chunks")
INDEX_FILE = os.path.join(BASE_DIR, "derslikler", "derslik_index.json")

# Papkaları yarat
os.makedirs(CHUNKS_DIR, exist_ok=True)

# ─── BÖLMƏ/MÖVZU AYIRICI PATTERN-LƏR ───
# Dərsliklərdə bölmə başlıqları adətən belə olur:
BOLME_PATTERNS = [
    r'(?:^|\n)\s*(\d+[\-\.]\s*(?:ci|cü|cı|cu)\s+BÖLMƏ[.:]\s*.+)',
    r'(?:^|\n)\s*(\d+[\-\.]\s*(?:Bölmə|BÖLMƏ)\s*[.:]\s*.+)',
    r'(?:^|\n)\s*((?:I|II|III|IV|V|VI|VII|VIII|IX|X)+\s+BÖLMƏ[.:]\s*.+)',
    r'(?:^|\n)\s*(\d+\.\s+[A-ZƏÜÖŞÇĞIİ][A-ZƏÜÖŞÇĞIİ\s]{5,})',  # ALL CAPS başlıq
]

MOVZU_PATTERNS = [
    r'(?:^|\n)\s*(\d+\.\d+[\.\s]+[A-ZƏÜÖŞÇĞIİa-zəüöşçğıi].{10,})',
    r'(?:^|\n)\s*(Mövzu\s*\d*[.:]\s*.+)',
    r'(?:^|\n)\s*(Dərs\s*\d*[.:]\s*.+)',
]


def extract_text_from_pdf(pdf_path):
    """PDF-dən bütün mətni çıxar, səhifə nömrələri ilə"""
    pages = []
    print(f"  📖 Oxunur: {os.path.basename(pdf_path)}")
    
    try:
        with pdfplumber.open(pdf_path) as pdf:
            total = len(pdf.pages)
            for i, page in enumerate(pdf.pages):
                text = page.extract_text()
                if text and len(text.strip()) > 20:  # Boş/çox qısa səhifələri atla
                    pages.append({
                        "page_num": i + 1,
                        "text": text.strip()
                    })
                
                # Progress
                if (i + 1) % 20 == 0:
                    print(f"    ... {i+1}/{total} səhifə")
            
            print(f"    ✅ {len(pages)}/{total} səhifə oxundu")
    except Exception as e:
        print(f"    ❌ Xəta: {e}")
        return []
    
    return pages


def detect_chapters(full_text):
    """Mətndə bölmə/fəsil başlıqlarını tap"""
    chapters = []
    
    for pattern in BOLME_PATTERNS:
        matches = re.finditer(pattern, full_text, re.MULTILINE)
        for m in matches:
            title = m.group(1).strip()
            pos = m.start()
            chapters.append({"title": title, "pos": pos, "type": "bolme"})
    
    for pattern in MOVZU_PATTERNS:
        matches = re.finditer(pattern, full_text, re.MULTILINE)
        for m in matches:
            title = m.group(1).strip()
            pos = m.start()
            chapters.append({"title": title, "pos": pos, "type": "movzu"})
    
    # Pozisiyaya görə sırala
    chapters.sort(key=lambda x: x["pos"])
    
    return chapters


def smart_chunk_pages(pages, grade, part=""):
    """Səhifələri ağıllı şəkildə parçala — hər 5-10 səhifə bir chunk"""
    chunks = []
    
    if not pages:
        return chunks
    
    # Bütün mətni birləşdir (bölmə aşkarlaması üçün)
    full_text = "\n\n".join([f"[SƏH.{p['page_num']}]\n{p['text']}" for p in pages])
    
    # Bölmə başlıqlarını tap
    detected = detect_chapters(full_text)
    
    if detected and len(detected) >= 3:
        # Aşkar edilmiş bölmələrə görə parçala
        print(f"    📑 {len(detected)} bölmə/mövzu tapıldı")
        
        for i, ch in enumerate(detected):
            start_pos = ch["pos"]
            end_pos = detected[i+1]["pos"] if i+1 < len(detected) else len(full_text)
            
            chunk_text = full_text[start_pos:end_pos].strip()
            
            if len(chunk_text) > 100:  # Çox qısa olanları atla
                # Səhifə nömrələrini çıxar
                page_nums = re.findall(r'\[SƏH\.(\d+)\]', chunk_text)
                page_range = f"{page_nums[0]}-{page_nums[-1]}" if page_nums else "?"
                
                # Təmiz başlıq
                title = ch["title"]
                title = re.sub(r'[^\w\s\-\.]', '', title).strip()[:80]
                
                chunks.append({
                    "grade": grade,
                    "part": part,
                    "title": title,
                    "type": ch["type"],
                    "pages": page_range,
                    "text": re.sub(r'\[SƏH\.\d+\]\n?', '', chunk_text).strip()
                })
    else:
        # Bölmə tapılmadısa — hər 8 səhifəni bir chunk et
        print(f"    📑 Avtomatik parçalama (hər 8 səhifə)")
        
        chunk_size = 8
        for i in range(0, len(pages), chunk_size):
            batch = pages[i:i+chunk_size]
            page_start = batch[0]["page_num"]
            page_end = batch[-1]["page_num"]
            text = "\n\n".join([p["text"] for p in batch])
            
            # İlk sətirdən başlıq çıxar
            first_line = text.split('\n')[0][:60].strip()
            
            chunks.append({
                "grade": grade,
                "part": part,
                "title": first_line or f"Səhifə {page_start}-{page_end}",
                "type": "auto",
                "pages": f"{page_start}-{page_end}",
                "text": text
            })
    
    return chunks


def save_chunk(chunk, chunk_num, grade, part):
    """Chunk-ı markdown faylı kimi saxla"""
    
    # Fayl adı üçün təmiz başlıq
    safe_title = chunk["title"].lower()
    safe_title = re.sub(r'[əƏ]', 'e', safe_title)
    safe_title = re.sub(r'[üÜ]', 'u', safe_title)
    safe_title = re.sub(r'[öÖ]', 'o', safe_title)
    safe_title = re.sub(r'[şŞ]', 's', safe_title)
    safe_title = re.sub(r'[çÇ]', 'c', safe_title)
    safe_title = re.sub(r'[ğĞ]', 'g', safe_title)
    safe_title = re.sub(r'[ıİ]', 'i', safe_title)
    safe_title = re.sub(r'[^\w\s\-]', '', safe_title)
    safe_title = re.sub(r'\s+', '_', safe_title.strip())[:50]
    
    part_str = f"_{part}" if part else ""
    filename = f"sinif{grade}{part_str}_chunk{chunk_num:02d}_{safe_title}.md"
    filepath = os.path.join(CHUNKS_DIR, filename)
    
    content = f"""---
sinif: {grade}
hisse: {part or 'tam'}
movzu: {chunk['title']}
sehifeler: {chunk['pages']}
tip: {chunk['type']}
---

# Sinif {grade} — {chunk['title']}
**Səhifələr: {chunk['pages']}**

{chunk['text']}
"""
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return filename


def parse_filename(filename):
    """Fayl adından sinif və hissə məlumatını çıxar"""
    name = filename.lower().replace('.pdf', '')
    
    grade = None
    part = ""
    
    # Sinif nömrəsini tap
    # riyaziyyat_6_I_hisse, riyaziyyat_7, etc.
    grade_match = re.search(r'(\d{1,2})', name)
    if grade_match:
        grade = int(grade_match.group(1))
    
    # Hissəni tap
    if 'i_hisse' in name or '1_hisse' in name or 'i hisse' in name:
        if 'ii_hisse' in name or '2_hisse' in name or 'ii hisse' in name:
            part = "II"
        else:
            part = "I"
    elif 'ii_hisse' in name or '2_hisse' in name or 'ii hisse' in name:
        part = "II"
    
    return grade, part


def process_all_pdfs():
    """Bütün PDF-ləri emal et"""
    
    print("═" * 60)
    print("  📐 Riy_Muellim_Agent — PDF Emal Pipeline")
    print("═" * 60)
    print()
    
    # PDF fayllarını tap
    if not os.path.exists(PDF_DIR):
        print(f"❌ PDF papkası tapılmadı: {PDF_DIR}")
        print(f"   Dərslik PDF-lərini bura qoyun: derslikler/pdf/")
        return
    
    pdf_files = sorted([f for f in os.listdir(PDF_DIR) if f.endswith('.pdf')])
    
    if not pdf_files:
        print(f"❌ PDF fayl tapılmadı: {PDF_DIR}")
        print(f"   Dərslik PDF-lərini bura qoyun: derslikler/pdf/")
        return
    
    print(f"📚 {len(pdf_files)} PDF tapıldı:")
    for f in pdf_files:
        print(f"   • {f}")
    print()
    
    # İndeks
    index = {
        "total_pdfs": len(pdf_files),
        "total_chunks": 0,
        "books": []
    }
    
    all_chunks_count = 0
    
    for pdf_file in pdf_files:
        pdf_path = os.path.join(PDF_DIR, pdf_file)
        grade, part = parse_filename(pdf_file)
        
        if grade is None:
            print(f"⚠️  Sinif müəyyən edilmədi: {pdf_file}, atlanır...")
            continue
        
        print(f"\n{'─'*60}")
        print(f"  📗 Sinif {grade} {'(' + part + ' hissə)' if part else ''}")
        print(f"{'─'*60}")
        
        # 1. Mətn çıxar
        pages = extract_text_from_pdf(pdf_path)
        
        if not pages:
            print(f"    ⚠️  Mətn çıxarıla bilmədi (skan edilmiş PDF ola bilər)")
            continue
        
        # 2. Parçala
        chunks = smart_chunk_pages(pages, grade, part)
        
        # 3. Saxla
        book_chunks = []
        for i, chunk in enumerate(chunks, 1):
            filename = save_chunk(chunk, i, grade, part)
            book_chunks.append({
                "file": filename,
                "title": chunk["title"],
                "pages": chunk["pages"],
                "type": chunk["type"],
                "text_length": len(chunk["text"])
            })
            all_chunks_count += 1
        
        print(f"    💾 {len(chunks)} chunk saxlandı → derslikler/chunks/")
        
        # İndeksə əlavə et
        index["books"].append({
            "pdf": pdf_file,
            "grade": grade,
            "part": part,
            "total_pages": len(pages),
            "total_chunks": len(chunks),
            "chunks": book_chunks
        })
    
    # İndeksi saxla
    index["total_chunks"] = all_chunks_count
    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    
    print(f"\n{'═'*60}")
    print(f"  ✅ TAMAMLANDI!")
    print(f"  📚 {len(pdf_files)} PDF emal edildi")
    print(f"  📑 {all_chunks_count} chunk yaradıldı")
    print(f"  📋 İndeks: derslikler/derslik_index.json")
    print(f"{'═'*60}")
    
    # Xülasə cədvəli
    print(f"\n  ┌{'─'*8}┬{'─'*12}┬{'─'*10}┬{'─'*10}┐")
    print(f"  │{'Sinif':^8}│{'Hissə':^12}│{'Səhifə':^10}│{'Chunk':^10}│")
    print(f"  ├{'─'*8}┼{'─'*12}┼{'─'*10}┼{'─'*10}┤")
    for book in index["books"]:
        p = book['part'] if book['part'] else 'tam'
        print(f"  │{book['grade']:^8}│{p:^12}│{book['total_pages']:^10}│{book['total_chunks']:^10}│")
    print(f"  └{'─'*8}┴{'─'*12}┴{'─'*10}┴{'─'*10}┘")


# ─── ƏLAVƏ: Chunk Axtarışı (Claude Code istifadə edəcək) ───

def search_chunks(grade, keyword):
    """Müəyyən sinif və açar söz üzrə chunk-ları axtar"""
    results = []
    
    if not os.path.exists(CHUNKS_DIR):
        return results
    
    keyword_lower = keyword.lower()
    
    for filename in sorted(os.listdir(CHUNKS_DIR)):
        if not filename.endswith('.md'):
            continue
        
        # Sinif filteri
        if f"sinif{grade}" not in filename:
            continue
        
        filepath = os.path.join(CHUNKS_DIR, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Açar söz axtarışı
        if keyword_lower in content.lower():
            # İlk 500 simvol
            results.append({
                "file": filename,
                "preview": content[:500],
                "full_path": filepath
            })
    
    return results


def search_and_print(grade, keyword):
    """Axtarış nəticələrini göstər"""
    results = search_chunks(grade, keyword)
    
    if not results:
        print(f"❌ Tapılmadı: sinif {grade}, '{keyword}'")
        return
    
    print(f"\n🔍 Tapıldı: {len(results)} chunk (sinif {grade}, '{keyword}')")
    print("─" * 60)
    
    for r in results:
        print(f"\n📄 {r['file']}")
        print(r['preview'][:300] + "...")
        print()


# ─── MAIN ───

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "search" and len(sys.argv) >= 4:
            # python3 scripts/pdf_to_chunks.py search 6 faiz
            grade = int(sys.argv[2])
            keyword = " ".join(sys.argv[3:])
            search_and_print(grade, keyword)
        else:
            print("İstifadə:")
            print("  python3 scripts/pdf_to_chunks.py          # Bütün PDF-ləri emal et")
            print("  python3 scripts/pdf_to_chunks.py search 6 faiz  # Chunk-larda axtar")
    else:
        process_all_pdfs()
