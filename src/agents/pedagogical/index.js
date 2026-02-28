// ============================================================
// Agent 3: Tədris Materialları və Metodika (Pedagogical Support Agent)
// - Dərs metodları: STEAM, PBL, IBL, Formativ qiymətləndirmə
// - Rol modelləri: tədqiqat, eksperiment ssenariləri
// - Yeni dərs ideyaları: giriş fəaliyyətləri, oyunlaşdırma
// ============================================================
const { AIEngine } = require('../../core/ai_engine');
const { query } = require('../../../config/database');

class PedagogicalAgent {
    constructor() {
        this.ai = new AIEngine();
    }

    // ─── Dərs Metodu Təklifi ─────────────────────────────
    async suggestMethod({ subjectCode, grade, topic, studentCount, challengeType }) {
        const prompt = `${grade}-ci sinif ${subjectCode} fənni, mövzu: "${topic}" üçün tədris metodu təklif et.

Sinif: ${studentCount || 25} şagird
${challengeType ? `PROBLEM: ${challengeType}` : ''}

Aşağıdakı metodlardan ən uyğunlarını seç və tətbiq planını ver:

1. STEAM (Science, Technology, Engineering, Arts, Mathematics)
2. Problem-based Learning (PBL) - Problem əsaslı öyrənmə
3. Inquiry-based Learning (IBL) - Araşdırma əsaslı öyrənmə
4. Flipped Classroom - Tərsinə sinif
5. Cooperative Learning - Əməkdaşlıq öyrənməsi
6. Gamification - Oyunlaşdırma
7. Project-based Learning - Layihə əsaslı öyrənmə
8. Differentiated Instruction - Diferensiallaşdırılmış tədris

Hər metod üçün:
- Niyə bu mövzuya uyğundur
- Addım-addım tətbiq planı
- Lazımi resurslar
- Qiymətləndirmə strategiyası
- Azərbaycan sinif otağı kontekstinə uyğunlaşdırma`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                recommendedMethods: [{
                    name: '', relevance: '', steps: [], resources: [],
                    assessmentStrategy: '', adaptationNotes: '', estimatedTime: ''
                }],
                formativeStrategies: [],
                tipsForTeacher: []
            }
        });
    }

    // ─── Formativ Qiymətləndirmə Strategiyaları ─────────
    async getFormativeStrategies({ subjectCode, grade, topic, objective }) {
        const prompt = `${grade}-ci sinif ${subjectCode}, mövzu: "${topic}" üçün formativ qiymətləndirmə strategiyaları təklif et.

Dərsin məqsədi: ${objective || 'Mövzunun əsas anlayışlarını başa düşmək'}

Strategiyalar:
1. Exit Ticket (Çıxış bileti) - dərsin sonunda qısa sual
2. Think-Pair-Share (Düşün-Paylaş)
3. KWL Chart (Bilirəm-Bilmək istəyirəm-Öyrəndim)
4. Traffic Light (Svetofor) - öz-özünə qiymətləndirmə
5. Quick Write (Sürətli yazı)
6. Thumbs Up/Down (Bəyənmə işarəsi)
7. Digital Poll (Rəqəmsal sorğu)
8. Observation Checklist (Müşahidə cədvəli)
9. Peer Assessment (Tay qiymətləndirmə)
10. Portfolio (Portfel)

Hər strategiya üçün konkret nümunə ver.`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                strategies: [{
                    name: '', description: '', example: '', duration: '',
                    materials: [], whenToUse: '', dataCollected: ''
                }]
            }
        });
    }

    // ─── Eksperiment / Tədqiqat Ssenarisi ────────────────
    async generateExperimentScenario({ subjectCode, grade, topic, experimentType = 'lab' }) {
        const prompt = `${grade}-ci sinif ${subjectCode}, mövzu: "${topic}" üçün ${experimentType === 'lab' ? 'laboratoriya eksperimenti' : 'tədqiqat layihəsi'} hazırla.

SSENARIDƏ OLMALIDIR:
1. Eksperimentin adı və məqsədi
2. Hipotez
3. Lazımi avadanlıq / materiallar (Azərbaycan məktəblərində mövcud olanlar)
4. Addım-addım təlimat (təhlükəsizlik qaydaları daxil)
5. Verilənlərin toplanması cədvəli
6. Analiz sualları
7. Nəticə formatı
8. Zəif şagirdlər üçün sadələşdirilmiş variant
9. Qabaqcıl şagirdlər üçün genişləndirilmiş tapşırıq
10. Müəllim üçün qeydlər`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                title: '', objective: '', hypothesis: '',
                materials: [], safetyRules: [], steps: [],
                dataTable: { headers: [], sampleRow: [] },
                analysisQuestions: [], conclusionFormat: '',
                simplifiedVersion: '', extendedTask: '', teacherNotes: ''
            }
        });
    }

    // ─── Giriş Fəaliyyətləri (Warm-up Ideas) ────────────
    async generateWarmUpActivities({ subjectCode, grade, topic, count = 5 }) {
        const prompt = `${grade}-ci sinif ${subjectCode}, mövzu: "${topic}" üçün ${count} fərqli 5-7 dəqiqəlik giriş fəaliyyəti (warm-up) yarat.

Fəaliyyət tipləri:
- Beyin fırtınası
- Mini oyun / tapmaca
- Real həyat nümunəsi ilə sual
- Video / şəkil analizi
- Qısa debat / müzakirə
- "Bilirsənmi?" faktları
- Keçən dərslə əlaqə sualı

Hər fəaliyyət üçün: ad, təsvir, lazımi material, müddət, bütün sinfi cəlb etmə üsulu.`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                activities: [{
                    name: '', type: '', description: '', duration: '',
                    materials: [], engagementTip: '', bloom: ''
                }]
            }
        });
    }

    // ─── Real Həyat Tətbiqi ──────────────────────────────
    async generateRealWorldExamples({ subjectCode, grade, topic }) {
        const prompt = `${grade}-ci sinif ${subjectCode}, mövzu: "${topic}" üçün real həyat tətbiqi nümunələri hazırla.

AZƏRBAYCAN KONTEKSTİNƏ UYĞUN:
- Bakıda / Azərbaycanda nümunələr
- Yerli sənaye, kənd təsərrüfatı, texnologiya
- Gündəlik həyatdan nümunələr
- Milli dəyərlər və tarix ilə əlaqə

5-7 fərqli real həyat nümunəsi ver. Hər biri üçün:
1. Ssenari təsviri
2. Mövzu ilə əlaqəsi
3. Şagirdlərə verilə biləcək sual
4. Dərinləşdirmə imkanı`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                examples: [{
                    title: '', scenario: '', connection: '',
                    discussionQuestion: '', deepDive: ''
                }]
            }
        });
    }

    // ─── Oyunlaşdırma ───────────────────────────────────
    async generateGamification({ subjectCode, grade, topic, classSize = 25 }) {
        const prompt = `${grade}-ci sinif ${subjectCode}, mövzu: "${topic}" üçün oyunlaşdırma (gamification) planı hazırla.

Sinif: ${classSize} şagird

OYUN ELEMENTLƏRİ:
1. Xal sistemi (point system)
2. Səviyyələr (levels)
3. Nişanlar / medalllar (badges)
4. Lider cədvəli (leaderboard)
5. Komanda yarışları
6. Quest / missiyalar
7. Vaxt yarışı

2-3 fərqli oyun formatı təklif et:
- Sinif daxili oyun
- Rəqəmsal oyun (kompüter/telefon)
- Ev tapşırığı oyunu`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                games: [{
                    name: '', type: '', rules: '', duration: '',
                    materials: [], learningObjective: '', scoringSystem: '',
                    adaptations: { zeif: '', yuksek: '' }
                }]
            }
        });
    }

    // ─── Debat / Mətn Analizi ────────────────────────────
    async generateDebateTopic({ subjectCode, grade, topic }) {
        const prompt = `${grade}-ci sinif ${subjectCode}, mövzu: "${topic}" üçün debat və ya mətn analizi fəaliyyəti hazırla.

1. DEBAT MÖVZUSU:
- Mövzu ilə bağlı mübahisəli/maraqlı sual
- Tərəf A-nın arqumentləri
- Tərəf B-nin arqumentləri
- Debat qaydaları
- Hakimlik rubrikası

2. MƏTN ANALİZİ:
- Qısa mətn (150-200 söz, Azərbaycan dilində)
- Analiz sualları (Bloom-un yuxarı səviyyələri)
- Müqayisə tapşırığı
- Yaradıcı yazma tapşırığı`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                debate: { topic: '', question: '', sideA: [], sideB: [], rules: [], rubric: {} },
                textAnalysis: { text: '', comprehensionQuestions: [], analysisQuestions: [], creativeTask: '' }
            }
        });
    }

    // ─── Zəif Şagirdlərlə İş Metodu ────────────────────
    async getWeakStudentStrategies({ subjectCode, grade, topic, specificChallenge }) {
        const prompt = `${grade}-ci sinif ${subjectCode}, mövzu: "${topic}" üçün zəif şagirdlərlə işləmə strategiyaları hazırla.

${specificChallenge ? `KONKRET PROBLEM: ${specificChallenge}` : ''}

STRATEGİYALAR:
1. Scaffolding (Dəstəkləmə) metodları
2. Vizual dəstək materialları
3. Sadələşdirilmiş izahlar (analogiyalar ilə)
4. Kiçik addımlarla öyrətmə
5. Tay dəstəyi (peer tutoring)
6. Fərdi müdaxilə planı
7. Motivasiya strategiyaları
8. Ev tapşırığı uyğunlaşdırması
9. Valideynlə əməkdaşlıq planı`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                strategies: [{
                    name: '', description: '', implementation: [],
                    materials: [], expectedOutcome: '', timeline: ''
                }],
                interventionPlan: { shortTerm: [], longTerm: [] },
                parentGuidance: ''
            }
        });
    }
}

module.exports = { PedagogicalAgent };
