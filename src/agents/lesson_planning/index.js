// ============================================================
// Agent 1: Tədris Planlaşdırılması (Lesson Planning Agent)
// - Dərs planı hazırlamaq (gündəlik/həftəlik/aylıq)
// - Bloom, DOK, Taksonimiya uyğun məqsədlər
// - Resurs yaratmaq (PPT, Worksheet, layihə)
// - Fərdi təlim təklifləri
// ============================================================
const { AIEngine } = require('../../core/ai_engine');
const { query } = require('../../../config/database');

class LessonPlanningAgent {
    constructor() {
        this.ai = new AIEngine();
    }

    // ─── Dərs Planı Yaratma ───────────────────────────────
    async generateLessonPlan({ teacherId, subjectCode, grade, topic, planType = 'daily', standards = [], options = {} }) {
        // 1. Standartları bazadan çək
        const standardsData = await this._getStandards(subjectCode, grade, standards);

        // 2. AI prompt hazırla
        const prompt = this._buildPlanPrompt({
            topic, grade, planType, standardsData,
            durationMinutes: options.durationMinutes || 45,
            bloomLevels: options.bloomLevels || [],
            dokLevel: options.dokLevel,
            includeInclusive: options.includeInclusive || false,
        });

        // 3. AI-dan cavab al
        const result = await this.ai.completeJSON({
            prompt,
            systemPrompt: this._planSystemPrompt(),
            schema: this._planSchema(),
        });

        if (!result.success || !result.parsed) {
            throw new Error('Dərs planı yaratma xətası: ' + (result.error || result.parseError));
        }

        // 4. Bazaya yaz
        const plan = result.parsed;
        const saved = await this._savePlan(teacherId, subjectCode, grade, plan, planType);

        return { plan: saved, aiMetadata: { model: result.model, tokens: result.tokensOutput } };
    }

    // ─── Həftəlik Plan ───────────────────────────────────
    async generateWeeklyPlan({ teacherId, subjectCode, grade, weekNumber, topics }) {
        const standardsData = await this._getStandards(subjectCode, grade);

        const prompt = `${grade}-ci sinif ${subjectCode} fənni üçün ${weekNumber}-ci həftə planı hazırla.

Mövzular: ${topics.join(', ')}

STANDARTLAR:
${standardsData.map(s => `- ${s.standard_code}: ${s.standard_text_az}`).join('\n')}

Hər gün üçün ayrı-ayrı dərs planı hazırla (həftədə 5 gün).
Hər dərsdə Bloom taksonomiyasının müxtəlif səviyyələri əks olunmalıdır.
Diferensiallaşdırma: zəif, orta, yüksək səviyyələr üçün fərqli tapşırıqlar.`;

        const result = await this.ai.completeJSON({ prompt, schema: { days: [] } });
        return result.parsed;
    }

    // ─── Resurs Yaratma ──────────────────────────────────
    async generateWorksheet({ subjectCode, grade, topic, difficulty = 'orta', questionCount = 10 }) {
        const prompt = `${grade}-ci sinif ${subjectCode} fənni üçün İş Vərəqi hazırla.

Mövzu: ${topic}
Çətinlik: ${difficulty}
Sual sayı: ${questionCount}

Tələblər:
1. Müxtəlif sual tipləri: MCQ, boşluq doldurma, qısa cavab, uyğunlaşdırma
2. Bloom taksonomiyasının müxtəlif səviyyələri
3. Hər sual üçün düzgün cavab və izah
4. Zəif şagirdlər üçün ipucu (hint)
5. Yüksək səviyyəli şagirdlər üçün əlavə çağırış sualı`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                title: '', topic: '', grade: 0, difficulty: '',
                questions: [{ type: '', text: '', options: [], answer: '', explanation: '', hint: '', bloom: '' }],
                bonus_question: { text: '', answer: '' }
            }
        });
    }

    async generateProjectTask({ subjectCode, grade, topic, groupSize = 4, durationDays = 14 }) {
        const prompt = `${grade}-ci sinif ${subjectCode} fənni üçün qrup layihə tapşırığı hazırla.

Mövzu: ${topic}
Qrup ölçüsü: ${groupSize} şagird
Müddət: ${durationDays} gün

Daxil etməlisən:
1. Layihənin adı və təsviri
2. Məqsədlər (Bloom taksonomiyasına uyğun)
3. Tapşırıq mərhələləri (timeline)
4. Qrup üzvlərinin rolları
5. Qiymətləndirmə rubrikası (rubric)
6. Lazımi resurslar
7. Təqdimat formatı`;

        return await this.ai.completeJSON({ prompt, schema: { projectName: '', description: '', objectives: [], timeline: [], roles: [], rubric: {}, resources: [] } });
    }

    async generateHomework({ subjectCode, grade, topic, difficulty = 'orta', estimatedMinutes = 30 }) {
        const prompt = `${grade}-ci sinif ${subjectCode} fənni üçün ev tapşırığı yarat.

Mövzu: ${topic}
Çətinlik: ${difficulty}
Təxmini vaxt: ${estimatedMinutes} dəqiqə

Tapşırıq 3 hissədən ibarət olmalıdır:
1. Əsas tapşırıq (bütün şagirdlər üçün)
2. Əlavə tapşırıq (istəyən şagirdlər üçün)
3. Yaradıcı tapşırıq (qabaqcıl şagirdlər üçün)`;

        return await this.ai.completeJSON({ prompt, schema: { title: '', topic: '', tasks: { core: [], extended: [], creative: [] }, tips: '' } });
    }

    // ─── Fərdi Təlim Təklifləri ──────────────────────────
    async generateDifferentiatedPlan({ subjectCode, grade, topic, studentLevel, isInclusive = false, inclusiveType = null }) {
        let levelDescription = '';
        switch (studentLevel) {
            case 'zeif':
                levelDescription = 'Zəif səviyyəli şagirdlər: əsas anlayışları möhkəmləndirmək, vizual dəstək, sadələşdirilmiş tapşırıqlar, əlavə vaxt';
                break;
            case 'orta':
                levelDescription = 'Orta səviyyəli şagirdlər: standart kurikulum, tətbiqi tapşırıqlar, müstəqil iş';
                break;
            case 'yuksek':
                levelDescription = 'Yüksək səviyyəli şagirdlər: dərinləşdirilmiş tapşırıqlar, tədqiqat, yaradıcı layihələr, mentorluq';
                break;
        }

        const inclusiveNote = isInclusive
            ? `\nİNKLYUZİV UYĞUNLAŞDIRMA: ${inclusiveType || 'Ümumi inklyuziv dəstək'}\n- Sadələşdirilmiş dil\n- Vizual dəstək materialları\n- Əlavə vaxt\n- Fərdi yanaşma`
            : '';

        const prompt = `${grade}-ci sinif ${subjectCode} fənni, mövzu: "${topic}" üçün fərdiləşdirilmiş tədris planı hazırla.

ŞAGIRD SƏVİYYƏSİ: ${levelDescription}
${inclusiveNote}

Plan daxil etməlidir:
1. Uyğunlaşdırılmış məqsədlər
2. Modifikasiya olunmuş tapşırıqlar
3. Əlavə dəstək materialları
4. Qiymətləndirmə üsulları
5. Valideyn məlumatlandırma qeydi`;

        return await this.ai.completeJSON({ prompt, schema: { objectives: [], activities: [], supportMaterials: [], assessmentMethods: [], parentNote: '' } });
    }

    // ─── Daxili Metodlar ─────────────────────────────────
    async _getStandards(subjectCode, grade, specificCodes = []) {
        let sql = `
            SELECT cs.standard_code, cs.standard_text_az, cs.content_area, 
                   cs.bloom_level, cs.dok_level, cs.learning_outcomes
            FROM curriculum_standards cs
            JOIN subjects s ON cs.subject_id = s.id
            WHERE s.code = $1 AND cs.grade = $2
        `;
        const params = [subjectCode, grade];

        if (specificCodes.length > 0) {
            sql += ` AND cs.standard_code = ANY($3)`;
            params.push(specificCodes);
        }
        sql += ' ORDER BY cs.standard_code';

        const result = await query(sql, params);
        return result.rows;
    }

    _buildPlanPrompt({ topic, grade, planType, standardsData, durationMinutes, bloomLevels, dokLevel, includeInclusive }) {
        return `${grade}-ci sinif üçün ${planType} dərs planı hazırla.

MÖVZU: ${topic}
MÜDDƏT: ${durationMinutes} dəqiqə
${bloomLevels.length ? `BLOOM SƏVİYYƏLƏRİ: ${bloomLevels.join(', ')}` : ''}
${dokLevel ? `DOK SƏVİYYƏSİ: ${dokLevel}` : ''}

ƏLAQƏLI STANDARTLAR:
${standardsData.map(s => `- [${s.standard_code}] ${s.standard_text_az} (Bloom: ${s.bloom_level}, DOK: ${s.dok_level})`).join('\n')}

PLAN STRUKTURU:
1. Dərsin məqsədləri (SMART formatda, Bloom-a uyğun)
2. Ön biliklər / Prerekvizitlər
3. Giriş fəaliyyəti (5-7 dəq) - motivasiya, sual
4. Əsas fəaliyyət (20-25 dəq) - yeni materialın izahı
5. Tətbiqi fəaliyyət (10-12 dəq) - tapşırıqlar
6. Qiymətləndirmə fəaliyyəti (5 dəq) - formativ
7. Yekunlaşdırma (3 dəq) - nəticə, refleksiya
8. Ev tapşırığı
9. Resurslar / Materiallar
${includeInclusive ? '10. İnklyuziv uyğunlaşdırma' : ''}

DİFERENSİALLAŞDIRMA:
- Zəif səviyyə üçün tapşırıq
- Orta səviyyə üçün tapşırıq  
- Yüksək səviyyə üçün tapşırıq`;
    }

    _planSystemPrompt() {
        return `Sən təcrübəli Azərbaycan müəllimisindir. Dərs planları Azərbaycan kurikulumuna, Bloom taksonomiyasına və DOK səviyyələrinə uyğun olmalıdır. Bütün məzmun Azərbaycan dilindədir.`;
    }

    _planSchema() {
        return {
            title: '', topic: '', grade: 0, duration: 0,
            standards: [{ code: '', text: '' }],
            objectives: [{ text: '', bloom: '', dok: 0 }],
            prerequisites: '',
            warmUp: { duration: 0, activity: '' },
            mainActivity: { duration: 0, steps: [] },
            practice: { duration: 0, tasks: [] },
            assessment: { duration: 0, method: '', questions: [] },
            closure: { duration: 0, activity: '' },
            homework: { core: '', extended: '' },
            differentiation: { zeif: '', orta: '', yuksek: '' },
            materials: [], crossCurricular: []
        };
    }

    async _savePlan(teacherId, subjectCode, grade, plan, planType) {
        const subjectResult = await query('SELECT id FROM subjects WHERE code = $1', [subjectCode]);
        if (subjectResult.rows.length === 0) throw new Error('Fənn tapılmadı: ' + subjectCode);

        const result = await query(`
            INSERT INTO lesson_plans (teacher_id, subject_id, plan_type, title, topic, 
                duration_minutes, bloom_levels, dok_level, objectives, 
                warm_up, main_activity, practice_activity, assessment_activity, 
                closure, homework, differentiation, materials, teaching_methods,
                ai_generated, ai_model, status)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, true, $19, 'draft')
            RETURNING *
        `, [
            teacherId, subjectResult.rows[0].id, planType,
            plan.title, plan.topic, plan.duration,
            plan.objectives?.map(o => o.bloom) || [],
            plan.objectives?.[0]?.dok || 2,
            JSON.stringify(plan.objectives),
            plan.warmUp?.activity, plan.mainActivity?.steps?.join('\n'),
            plan.practice?.tasks?.join('\n'), plan.assessment?.method,
            plan.closure?.activity, plan.homework?.core,
            JSON.stringify(plan.differentiation),
            plan.materials || [], plan.crossCurricular || [],
            'claude-sonnet-4-5-20250514'
        ]);

        return result.rows[0];
    }
}

module.exports = { LessonPlanningAgent };
