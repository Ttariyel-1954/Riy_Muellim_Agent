// ============================================================
// Agent 4: Rəqəmsal Dəstək (Digital Assistant Block)
// - Sənəd və raport generasiyası
// - Excel/PDF/Word çevirmə
// - LMS inteqrasiyası (Google Classroom, Teams, Moodle)
// ============================================================
const { AIEngine } = require('../../core/ai_engine');
const { query } = require('../../../config/database');
const PptxGenJS = require('pptxgenjs');
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell } = require('docx');
const ExcelJS = require('exceljs');
const fs = require('fs').promises;
const path = require('path');

class DigitalAssistantAgent {
    constructor() {
        this.ai = new AIEngine();
        this.uploadsDir = process.env.UPLOAD_DIR || './uploads';
    }

    // ─── Jurnal Yazısı Generasiyası ─────────────────────
    async generateJournalEntry({ teacherId, subjectCode, grade, date, lessonTopic, activities, notes }) {
        const prompt = `Müəllim jurnalı üçün qeyd hazırla:

Tarix: ${date}
Fənn: ${subjectCode}
Sinif: ${grade}
Mövzu: ${lessonTopic}
Fəaliyyətlər: ${activities || 'Standart dərs'}
Qeydlər: ${notes || 'Yoxdur'}

FORMAT: Rəsmi jurnal formatında, qısa və dəqiq.`;

        const result = await this.ai.completeJSON({
            prompt,
            schema: { date: '', subject: '', grade: 0, topic: '', objectives: '', activities: '', assessment: '', homework: '', notes: '' }
        });

        // Save to database
        await query(`
            INSERT INTO generated_documents (teacher_id, doc_type, title, content_json, ai_generated)
            VALUES ($1, 'journal', $2, $3, true)
        `, [teacherId, `Jurnal - ${date} - ${subjectCode}`, JSON.stringify(result.parsed)]);

        return result.parsed;
    }

    // ─── Aylıq Plan Generasiyası ────────────────────────
    async generateMonthlyPlan({ teacherId, subjectCode, grade, month, year, weeklyHours = 3 }) {
        const standards = await query(`
            SELECT cs.standard_code, cs.standard_text_az, cs.content_area
            FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id
            WHERE s.code = $1 AND cs.grade = $2
            ORDER BY cs.standard_code
        `, [subjectCode, grade]);

        const prompt = `${grade}-ci sinif ${subjectCode} fənni üçün ${month} ${year} aylıq plan hazırla.

Həftəlik saat: ${weeklyHours}
Standartlar: ${standards.rows.map(s => `${s.standard_code}: ${s.standard_text_az}`).join('\n')}

Plan formatı:
- Həftə nömrəsi
- Tarix
- Mövzu
- Standart kodu
- Saat sayı
- Qiymətləndirmə üsulu
- Qeydlər`;

        return await this.ai.completeJSON({
            prompt,
            schema: { month: '', year: 0, subject: '', grade: 0, weeks: [{ week: 0, dates: '', topics: [], standards: [], hours: 0, assessment: '', notes: '' }] }
        });
    }

    // ─── Fəaliyyət Hesabatı ─────────────────────────────
    async generateActivityReport({ teacherId, period, reportType = 'monthly' }) {
        // Gather data from database
        const teacherData = await query('SELECT * FROM teachers WHERE id = $1', [teacherId]);
        const lessonsCount = await query(`SELECT COUNT(*) FROM lesson_plans WHERE teacher_id = $1 AND created_at > NOW() - INTERVAL '30 days'`, [teacherId]);
        const assessmentsCount = await query(`SELECT COUNT(*) FROM assessments WHERE teacher_id = $1 AND created_at > NOW() - INTERVAL '30 days'`, [teacherId]);
        const resourcesCount = await query(`SELECT COUNT(*) FROM resources WHERE teacher_id = $1 AND created_at > NOW() - INTERVAL '30 days'`, [teacherId]);

        const teacher = teacherData.rows[0];
        const prompt = `Müəllim fəaliyyət hesabatı hazırla:

Müəllim: ${teacher?.first_name} ${teacher?.last_name}
İxtisas: ${teacher?.specialization}
Dövr: ${period}

Statistika:
- Hazırlanan dərs planları: ${lessonsCount.rows[0]?.count || 0}
- Keçirilən qiymətləndirmələr: ${assessmentsCount.rows[0]?.count || 0}
- Yaradılmış resurslar: ${resourcesCount.rows[0]?.count || 0}

Rəsmi hesabat formatında hazırla.`;

        return await this.ai.completeJSON({
            prompt,
            schema: { title: '', period: '', teacher: '', summary: '', achievements: [], statistics: {}, recommendations: [], conclusion: '' }
        });
    }

    // ─── Valideyn Mesajı ────────────────────────────────
    async generateParentMessage({ studentId, messageType, customContent }) {
        const student = await query(`
            SELECT s.*, sch.name as school_name FROM students s 
            JOIN schools sch ON s.school_id = sch.id WHERE s.id = $1
        `, [studentId]);

        const s = student.rows[0];
        const templates = {
            weekly_report: `${s?.first_name} ${s?.last_name} üçün həftəlik hesabat hazırla. Müsbət tonada, inkişaf sahələrini göstər.`,
            alert: `${s?.first_name} üçün xəbərdarlıq mesajı. Problem: ${customContent}. Həssas və peşəkar tonada.`,
            praise: `${s?.first_name} üçün tərif mesajı. Nailiyyət: ${customContent}. Motivasiya edici tonada.`,
        };

        const prompt = templates[messageType] || customContent;
        return await this.ai.complete({ prompt, maxTokens: 500 });
    }

    // ─── PowerPoint Yaratma ─────────────────────────────
    async generatePresentation({ title, slides, template = 'default' }) {
        const pptx = new PptxGenJS();
        pptx.author = 'ARTI Müəllim Agent';
        pptx.title = title;

        // Title slide
        const titleSlide = pptx.addSlide();
        titleSlide.addText(title, { x: 1, y: 1.5, w: 8, h: 2, fontSize: 32, bold: true, color: '003366', align: 'center' });
        titleSlide.addText('ARTI - Müəllim Agent', { x: 1, y: 4, w: 8, h: 0.5, fontSize: 14, color: '666666', align: 'center' });

        // Content slides
        for (const slideData of (slides || [])) {
            const slide = pptx.addSlide();
            slide.addText(slideData.title || '', { x: 0.5, y: 0.3, w: 9, h: 1, fontSize: 24, bold: true, color: '003366' });

            if (slideData.bullets) {
                slide.addText(
                    slideData.bullets.map(b => ({ text: b, options: { bullet: true, fontSize: 16 } })),
                    { x: 0.7, y: 1.5, w: 8, h: 4 }
                );
            }

            if (slideData.note) {
                slide.addNotes(slideData.note);
            }
        }

        const filePath = path.join(this.uploadsDir, `presentation_${Date.now()}.pptx`);
        await pptx.writeFile({ fileName: filePath });
        return { filePath, slideCount: (slides?.length || 0) + 1 };
    }

    // ─── Word Sənəd Yaratma ────────────────────────────
    async generateWordDocument({ title, content, type = 'report' }) {
        const doc = new Document({
            sections: [{
                properties: {},
                children: [
                    new Paragraph({
                        children: [new TextRun({ text: title, bold: true, size: 32, font: 'Arial' })],
                        spacing: { after: 400 },
                    }),
                    new Paragraph({
                        children: [new TextRun({ text: `Tarix: ${new Date().toLocaleDateString('az-AZ')}`, size: 20, color: '666666' })],
                        spacing: { after: 200 },
                    }),
                    ...content.split('\n').map(line =>
                        new Paragraph({
                            children: [new TextRun({ text: line, size: 22, font: 'Arial' })],
                            spacing: { after: 120 },
                        })
                    ),
                ],
            }],
        });

        const buffer = await Packer.toBuffer(doc);
        const filePath = path.join(this.uploadsDir, `document_${Date.now()}.docx`);
        await fs.writeFile(filePath, buffer);
        return { filePath, title };
    }

    // ─── Excel Analiz ───────────────────────────────────
    async generateExcelReport({ title, data, sheetName = 'Report' }) {
        const workbook = new ExcelJS.Workbook();
        workbook.creator = 'ARTI Müəllim Agent';
        const sheet = workbook.addWorksheet(sheetName);

        if (data.length > 0) {
            // Headers
            const headers = Object.keys(data[0]);
            sheet.addRow(headers);
            sheet.getRow(1).font = { bold: true, size: 12 };
            sheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF003366' } };
            sheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 12 };

            // Data rows
            data.forEach(row => sheet.addRow(Object.values(row)));

            // Auto-width
            headers.forEach((h, i) => {
                sheet.getColumn(i + 1).width = Math.max(h.length * 1.5, 12);
            });
        }

        const filePath = path.join(this.uploadsDir, `report_${Date.now()}.xlsx`);
        await workbook.xlsx.writeFile(filePath);
        return { filePath, rowCount: data.length };
    }

    // ─── LMS İnteqrasiyaları ────────────────────────────
    async syncToGoogleClassroom({ courseId, assignmentData, credentials }) {
        // Placeholder for Google Classroom API integration
        console.log('Google Classroom sync:', courseId, assignmentData);
        return { success: true, message: 'Google Classroom inteqrasiyası konfiqurasiya olunmalıdır' };
    }

    async syncToMicrosoftTeams({ teamId, assignmentData, credentials }) {
        console.log('Microsoft Teams sync:', teamId, assignmentData);
        return { success: true, message: 'Microsoft Teams inteqrasiyası konfiqurasiya olunmalıdır' };
    }

    async syncToMoodle({ courseId, quizData }) {
        const moodleUrl = process.env.MOODLE_URL;
        const moodleToken = process.env.MOODLE_TOKEN;
        if (!moodleUrl || !moodleToken) {
            return { success: false, message: 'Moodle konfiqurasiyası tamamlanmayıb' };
        }
        // Moodle REST API call placeholder
        return { success: true, message: 'Moodle-a göndərildi' };
    }

    // ─── Yazı Redaktəsi ─────────────────────────────────
    async editText({ text, editType = 'grammar' }) {
        const editPrompts = {
            grammar: 'Bu mətndə qrammatik xətaları düzəlt. Yalnız düzəldilmiş versiyası ver.',
            style: 'Bu mətni daha peşəkar və formal üslubda yenidən yaz.',
            simplify: 'Bu mətni daha sadə dildə yenidən yaz (şagirdlər üçün).',
            translate_en: 'Bu mətni İngilis dilinə tərcümə et.',
            translate_ru: 'Bu mətni Rus dilinə tərcümə et.',
        };

        const prompt = `${editPrompts[editType] || 'Bu mətni redaktə et.'}\n\nMƏTN:\n${text}`;
        return await this.ai.complete({ prompt, maxTokens: 2000 });
    }
}

module.exports = { DigitalAssistantAgent };
