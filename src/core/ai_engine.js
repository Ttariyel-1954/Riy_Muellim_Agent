// ============================================================
// Core AI Engine - Müəllim Agent
// Multi-model support: Claude 4.5 Sonnet, GPT-4o, Mixtral
// ============================================================
const Anthropic = require('@anthropic-ai/sdk');
const OpenAI = require('openai');

// System prompt - Azərbaycan müəllim konteksti
const SYSTEM_PROMPT_AZ = `Sən Azərbaycan Respublikası Təhsil İnstitutunun (ARTI) hazırladığı AI müəllim köməkçisisən.

KONTEKST:
- Azərbaycan kurikulumuna uyğun işləyirsən (5-11-ci siniflər)
- Bloom taksonomiyası: Xatırlama → Anlama → Tətbiqetmə → Təhlil → Qiymətləndirmə → Yaratma
- DOK (Depth of Knowledge) səviyyələri: 1-4
- Dil: Azərbaycan dili (əsas), Rus dili, İngilis dili
- Fənn standartları bazada saxlanılır və referans kimi istifadə olunur

PRİNSİPLƏR:
1. Hər cavab kurikulum standartlarına istinad etməlidir
2. Differensiallaşdırma: zəif/orta/yüksək səviyyə üçün uyğunlaşdırma
3. İnklyuziv təlim prinsipləri nəzərə alınmalıdır
4. Real həyat nümunələri Azərbaycan kontekstinə uyğun olmalıdır
5. Formativ qiymətləndirmə strategiyaları təqdim edilməlidir

FORMAT: Cavablarını strukturlu, təmiz və Azərbaycan dilində ver.`;

class AIEngine {
    constructor() {
        this.anthropic = process.env.ANTHROPIC_API_KEY
            ? new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })
            : null;

        this.openai = process.env.OPENAI_API_KEY
            ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
            : null;

        this.defaultModel = process.env.DEFAULT_AI_MODEL || 'claude-sonnet-4-5-20250514';
    }

    // Main completion method
    async complete({ prompt, systemPrompt, model, maxTokens = 4096, temperature = 0.7, context = {} }) {
        const system = systemPrompt || SYSTEM_PROMPT_AZ;
        const selectedModel = model || this.defaultModel;
        const startTime = Date.now();

        try {
            let result;

            if (selectedModel.startsWith('claude')) {
                result = await this._callClaude(system, prompt, selectedModel, maxTokens, temperature);
            } else if (selectedModel.startsWith('gpt')) {
                result = await this._callOpenAI(system, prompt, selectedModel, maxTokens, temperature);
            } else {
                throw new Error(`Dəstəklənməyən model: ${selectedModel}`);
            }

            const latency = Date.now() - startTime;

            return {
                success: true,
                content: result.content,
                model: selectedModel,
                tokensInput: result.inputTokens || 0,
                tokensOutput: result.outputTokens || 0,
                latencyMs: latency,
            };
        } catch (error) {
            console.error(`❌ AI xəta [${selectedModel}]:`, error.message);
            return {
                success: false,
                error: error.message,
                model: selectedModel,
                latencyMs: Date.now() - startTime,
            };
        }
    }

    // Claude API call
    async _callClaude(system, prompt, model, maxTokens, temperature) {
        if (!this.anthropic) throw new Error('Anthropic API key konfiqurasiya olunmayıb');

        const response = await this.anthropic.messages.create({
            model: model,
            max_tokens: maxTokens,
            temperature: temperature,
            system: system,
            messages: [{ role: 'user', content: prompt }],
        });

        return {
            content: response.content[0].text,
            inputTokens: response.usage?.input_tokens,
            outputTokens: response.usage?.output_tokens,
        };
    }

    // OpenAI API call
    async _callOpenAI(system, prompt, model, maxTokens, temperature) {
        if (!this.openai) throw new Error('OpenAI API key konfiqurasiya olunmayıb');

        const response = await this.openai.chat.completions.create({
            model: model,
            max_tokens: maxTokens,
            temperature: temperature,
            messages: [
                { role: 'system', content: system },
                { role: 'user', content: prompt },
            ],
        });

        return {
            content: response.choices[0].message.content,
            inputTokens: response.usage?.prompt_tokens,
            outputTokens: response.usage?.completion_tokens,
        };
    }

    // Structured JSON output
    async completeJSON({ prompt, systemPrompt, model, schema }) {
        const jsonPrompt = `${prompt}\n\nCAVABINI YERİNƏ JSON formatında qaytar. Schema:\n${JSON.stringify(schema, null, 2)}\n\nYALNIZ JSON qaytar, başqa heç nə əlavə etmə.`;

        const result = await this.complete({
            prompt: jsonPrompt,
            systemPrompt,
            model,
            temperature: 0.3, // Lower temp for structured output
        });

        if (result.success) {
            try {
                const cleaned = result.content
                    .replace(/```json\n?/g, '')
                    .replace(/```\n?/g, '')
                    .trim();
                result.parsed = JSON.parse(cleaned);
            } catch (e) {
                result.parseError = e.message;
            }
        }
        return result;
    }

    // Batch processing
    async batchComplete(prompts, { systemPrompt, model, maxTokens } = {}) {
        const results = await Promise.allSettled(
            prompts.map(prompt =>
                this.complete({ prompt, systemPrompt, model, maxTokens })
            )
        );
        return results.map((r, i) => ({
            index: i,
            ...(r.status === 'fulfilled' ? r.value : { success: false, error: r.reason?.message }),
        }));
    }
}

module.exports = { AIEngine, SYSTEM_PROMPT_AZ };
