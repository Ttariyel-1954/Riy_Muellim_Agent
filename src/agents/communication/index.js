// ============================================================
// Agent 6: Kommunikasiya (Communication Agent)
// - Valideyn kommunikasiyası
// - Şagird kommunikasiyası
// - Müəllimlararası əməkdaşlıq
// ============================================================
const { AIEngine } = require('../../core/ai_engine');
const { query } = require('../../../config/database');

class CommunicationAgent {
    constructor() {
        this.ai = new AIEngine();
    }

    // ─── Valideyn Həftəlik Məruzə ──────────────────────
    async generateWeeklyParentReport({ studentId, weekNumber }) {
        const student = await query('SELECT * FROM students WHERE id = $1', [studentId]);
        const s = student.rows[0];

        // Gather week data
        const weekResults = await query(`
            SELECT spl.*, sub.name_az as subject_name
            FROM student_progress_logs spl
            LEFT JOIN subjects sub ON spl.subject_id = sub.id
            WHERE spl.student_id = $1 AND spl.log_date > NOW() - INTERVAL '7 days'
            ORDER BY spl.log_date
        `, [studentId]);

        const attendance = await query(`
            SELECT status, COUNT(*) as count
            FROM attendance WHERE student_id = $1 AND attendance_date > NOW() - INTERVAL '7 days'
            GROUP BY status
        `, [studentId]);

        const prompt = `Valideyn üçün həftəlik qısa məruzə hazırla.

ŞAGİRD: ${s?.first_name} ${s?.last_name} (${s?.grade}-ci sinif, ${s?.class_section} bölmə)
HƏFTƏ: ${weekNumber || 'Bu həftə'}

NƏTİCƏLƏR:
${weekResults.rows.map(r => `- ${r.subject_name}: ${r.title} - ${r.score}/${r.max_score}`).join('\n') || 'Bu həftə qeyd yoxdur'}

DAVAMIYYƏT:
${attendance.rows.map(a => `${a.status}: ${a.count} gün`).join(', ') || 'Məlumat yoxdur'}

FORMAT: Qısa, müsbət, peşəkar. Güclü tərəfləri vurğula. İnkişaf sahələrini həssas şəkildə qeyd et.
DİL: Azərbaycan dili, sadə və anlaşıqlı.
Valideynə konkret ev tapşırığı tövsiyəsi ver.`;

        const result = await this.ai.complete({ prompt, maxTokens: 800 });

        // Save message
        if (result.success) {
            await query(`
                INSERT INTO messages (sender_id, message_type, recipient_type, recipient_id, 
                    subject, body, channel, ai_generated, status)
                VALUES (NULL, 'parent_report', 'parent', $1, $2, $3, 'app', true, 'draft')
            `, [studentId, `Həftəlik hesabat - ${s?.first_name} ${s?.last_name}`, result.content]);
        }

        return result;
    }

    // ─── Valideyn Xəbərdarlıq Mesajı ───────────────────
    async generateAlertMessage({ studentId, alertType, details }) {
        const student = await query('SELECT * FROM students WHERE id = $1', [studentId]);
        const s = student.rows[0];

        const alertTemplates = {
            attendance: `${s?.first_name} son günlərdə davamiyyətdə problem var. ${details}`,
            academic: `${s?.first_name}-in akademik nəticələrində dəyişiklik müşahidə edilir. ${details}`,
            behavior: `${s?.first_name} ilə bağlı davranış qeydi var. ${details}`,
            positive: `${s?.first_name} barəsində müsbət xəbər! ${details}`,
        };

        const prompt = `Valideynə xəbərdarlıq mesajı yaz:

Mesaj növü: ${alertType}
Məzmun: ${alertTemplates[alertType] || details}

QAYDALAR:
- Həssas və hörmətli ton
- Problemi aydın izah et
- Birgə həll yolları təklif et
- Görüşə dəvət et (lazım olarsa)
- Azərbaycan dilində`;

        return await this.ai.complete({ prompt, maxTokens: 500 });
    }

    // ─── Tərif və Motivasiya ────────────────────────────
    async generatePraiseMessage({ studentId, achievement }) {
        const student = await query('SELECT * FROM students WHERE id = $1', [studentId]);
        const s = student.rows[0];

        const prompt = `${s?.first_name} ${s?.last_name} (${s?.grade}-ci sinif) üçün motivasiya mesajı yaz.

NailiyyƏt: ${achievement}

TƏLƏBLƏR:
- Şagirdin yaşına uyğun (${s?.grade}-ci sinif)
- Entuziast və motivasiya edici
- Konkret nailiyyəti vurğula
- Davam etməyə həvəsləndir
- Qısa (3-4 cümlə)`;

        return await this.ai.complete({ prompt, maxTokens: 300 });
    }

    // ─── Şagirdə Motivasiya ────────────────────────────
    async generateStudentMotivation({ studentId, context }) {
        const student = await query('SELECT * FROM students WHERE id = $1', [studentId]);
        const s = student.rows[0];

        const prompt = `${s?.grade}-ci sinif şagirdi ${s?.first_name} üçün motivasiya mesajı:

KONTEKST: ${context || 'Ümumi motivasiya'}

- Yaşa uyğun dil
- Müsbət və dəstəkləyici
- Konkret hədəf göstər
- Qısa və təsirli`;

        return await this.ai.complete({ prompt, maxTokens: 200 });
    }

    // ─── Tapşırıq Xatırlatması ─────────────────────────
    async generateHomeworkReminder({ classId, subjectCode, dueDate, taskDescription }) {
        const prompt = `Şagirdlər üçün ev tapşırığı xatırlatması yaz:

Fənn: ${subjectCode}
Son tarix: ${dueDate}
Tapşırıq: ${taskDescription}

FORMAT: Qısa, dostcanlıq tonunda, xatırladıcı.`;

        return await this.ai.complete({ prompt, maxTokens: 150 });
    }

    // ─── Müəllimlər arası əməkdaşlıq ──────────────────
    async generateCollaborationContent({ groupId, contentType, topic }) {
        const group = await query('SELECT * FROM collaboration_groups WHERE id = $1', [groupId]);

        const prompts = {
            planning: `"${group.rows[0]?.name}" qrupu üçün birgə planlaşdırma məzmunu hazırla.\nMövzu: ${topic}\n\nDaxil etməlisən: paylaşımlı məqsədlər, iş bölgüsü, vaxt cədvəli.`,
            resource: `"${group.rows[0]?.name}" metodiki birlik üçün paylaşımlı resurs təklifi hazırla.\nMövzu: ${topic}\n\nDaxil etməlisən: resurs təsviri, istifadə qaydaları, təkmilləşdirmə təklifləri.`,
            meeting: `"${group.rows[0]?.name}" toplantısı üçün gündəm hazırla.\nMövzu: ${topic}\n\nDaxil etməlisən: gündəm maddələri, müzakirə sualları, qərar nöqtələri.`,
        };

        return await this.ai.complete({
            prompt: prompts[contentType] || `Əməkdaşlıq məzmunu hazırla: ${topic}`,
            maxTokens: 1000
        });
    }

    // ─── Toplu Mesaj Göndərmə ──────────────────────────
    async sendBulkMessages({ teacherId, recipientType, recipientIds, messageTemplate, channel = 'app' }) {
        const results = [];

        for (const recipientId of recipientIds) {
            let personalizedMessage = messageTemplate;

            if (recipientType === 'parent') {
                const student = await query('SELECT * FROM students WHERE id = $1', [recipientId]);
                const s = student.rows[0];
                personalizedMessage = messageTemplate
                    .replace('{ad}', s?.first_name || '')
                    .replace('{soyad}', s?.last_name || '')
                    .replace('{sinif}', `${s?.grade}-${s?.class_section}` || '');
            }

            const saved = await query(`
                INSERT INTO messages (sender_id, message_type, recipient_type, recipient_id,
                    body, channel, status) VALUES ($1, $2, $3, $4, $5, $6, 'draft')
                RETURNING id
            `, [teacherId, `${recipientType}_custom`, recipientType, recipientId, personalizedMessage, channel]);

            results.push({ recipientId, messageId: saved.rows[0]?.id, status: 'drafted' });
        }

        return { total: results.length, results };
    }

    // ─── Mesaj Şablonları ───────────────────────────────
    getTemplates() {
        return {
            parent: {
                weekly_report: 'Hörmətli valideyn, {ad} {soyad}-ın bu həftəki nəticələri...',
                meeting_invite: 'Hörmətli valideyn, {ad} ilə bağlı görüş keçirmək istəyirəm...',
                positive_feedback: '{ad} bu gün dərsdə əla çıxış etdi...',
                concern: '{ad}-ın son vaxtlar dərslərə marağı azalıb...',
            },
            student: {
                motivation: '{ad}, sən bunu bacarırsan! Davam et!',
                homework_reminder: '{ad}, sabah {fenn} fənnindən ev tapşırığı təhvil verirsən.',
                congratulations: 'Təbrik edirik, {ad}! {nailiyyet}',
            },
            teacher: {
                resource_share: 'Hörmətli həmkar, {fenn} fənni üçün yeni resurs paylaşmaq istəyirəm...',
                meeting_notes: 'Metodiki birlik toplantısının qeydləri...',
            },
        };
    }
}

module.exports = { CommunicationAgent };
