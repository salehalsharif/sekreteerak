// ═══════════════════════════════════════════════════════════════
// سَكرتيرك — Parse Voice Input Edge Function v2
// Production-grade: DeepSeek primary + OpenAI fallback
// Axes covered: prompt v2, provider fallback, validation, observability
// ═══════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ─── Environment ──────────────────────────────────────────────
const DEEPSEEK_API_KEY    = Deno.env.get("DEEPSEEK_API_KEY") ?? "";
const OPENAI_API_KEY      = Deno.env.get("OPENAI_API_KEY") ?? "";
const AI_DEFAULT          = Deno.env.get("AI_PROVIDER_DEFAULT") ?? "deepseek";
const ENABLE_FALLBACK     = (Deno.env.get("ENABLE_OPENAI_FALLBACK") ?? "true").toLowerCase() === "true";
const PROMPT_VERSION      = Deno.env.get("PARSE_PROMPT_VERSION") ?? "v2";

// ─── Types ────────────────────────────────────────────────────
interface ProviderResult {
  raw: Record<string, unknown>;
  provider: string;
  model: string;
}

interface ParseContext {
  raw_text: string;
  source: string;
  audio_url: string | null;
  currentDate: string;
  currentTime: string;
  afterAsrTime: string;
  afterMaghribTime: string;
  timezone: string;
}

// ═══════════════════════════════════════════════════════════════
// SYSTEM PROMPT v2 — smarter date/time logic
// ═══════════════════════════════════════════════════════════════
const SYSTEM_PROMPT_V2 = `أنت محلل نوايا ذكي داخل تطبيق "سَكرتيرك" — مساعد شخصي عربي لإدارة المهام.

المدخل: نص عربي عفوي (مفرّغ من صوت المستخدم).
المخرج: JSON منظم فقط، بدون أي شرح إضافي.

## القواعد:

### 1. العنوان
استخرج عنوانًا واضحًا ومختصرًا يصف المهمة. لا تكرر النص كاملًا.

### 2. نوع العنصر
- task: مهمة عادية (الافتراضي)
- meeting: موعد اجتماع أو لقاء فعلي مؤكد (ليس مجرد ترتيب)
- followup: أي نص فيه: تابع، راجع، تأكد، ذكّرني أسأل، شيّك
- reminder: تذكير بسيط لا يتطلب إنجاز عمل
- idea: فكرة أو ملاحظة للمستقبل
- shopping: مشتريات أو قائمة شراء

### 3. قواعد التاريخ والوقت — مهمة جدًا:

#### متى تضع due_date:
- "اليوم"، "الحين"، "الآن"، "بعد شوي" → التاريخ الحالي
- "بكرة"، "باكر"، "غدًا" → اليوم التالي
- "الخميس"، "السبت"، إلخ → أقرب يوم قادم بهذا الاسم
- "أول الشهر"، "نهاية الشهر" → حسب السياق
- "بعد أسبوع" → تاريخ بعد 7 أيام
- "بعد العصر"، "بعد المغرب"، "الصبح"، "الليل" → التاريخ الحالي + الوقت
- أي عبارة فيها دلالة زمنية واضحة على يوم محدد → ذلك اليوم

#### متى لا تضع due_date (اجعله null):
- idea بدون ذكر زمني → null
- shopping بدون ذكر زمني واضح → null
- "إذا فضيت"، "لو عندك وقت"، "مو مستعجل" بدون تاريخ → null
- لا يوجد أي دلالة زمنية في النص → null
⚠️ لا تستخدم اليوم الحالي كافتراضي أبدًا. إذا لم يكن هناك دلالة زمنية واضحة، اجعل due_date = null

#### الوقت:
- "بعد العصر" → استخدم after_asr_time
- "بعد المغرب" → استخدم after_maghrib_time
- "الصبح"/"الصباح" → 09:00
- "الظهر" → 12:00
- "الليل"/"بالليل" → 21:00
- "الساعة X" → HH:MM
- بدون ذكر وقت → null

### 4. meeting بدون وقت واضح:
- إذا كان النص يقول "رتّب اجتماع" أو "نبي نجتمع" بدون تحديد موعد فعلي → اجعله task بدلاً من meeting
- meeting يكون فقط عند وجود موعد محدد أو واضح (يوم + وقت أو على الأقل يوم)

### 5. الأولوية:
- high: "ضروري"، "مهم"، "عاجل"، "لازم"، "ما ينسى"
- medium: الافتراضي
- low: "لو عندك وقت"، "مو مستعجل"، "إذا فضيت"

### 6. linked_person: استخرج اسم الشخص إن ذُكر، وإلا null
### 7. recurrence_rule: "يومي"، "أسبوعي"، "كل أحد"، إلخ. وإلا null
### 8. is_followup: true إذا كان النص متابعة
### 9. confirmation_text: جملة تأكيد عربية طبيعية مختصرة
### 10. أخرج JSON صالحًا فقط

## شكل المخرج:
{
  "title": "string",
  "item_type": "task|meeting|followup|reminder|idea|shopping",
  "due_date": "YYYY-MM-DD|null",
  "due_time": "HH:MM|null",
  "priority": "low|medium|high",
  "linked_person": "string|null",
  "recurrence_rule": "string|null",
  "is_followup": boolean,
  "notes": "string",
  "reminder_offset_minutes": number,
  "confirmation_text": "string",
  "has_explicit_time_reference": boolean
}`;

// ═══════════════════════════════════════════════════════════════
// UTILITIES
// ═══════════════════════════════════════════════════════════════

function jsonHeaders(status = 200) {
  return {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  };
}

function safeJsonParse(text: string): Record<string, unknown> {
  try {
    return JSON.parse(text);
  } catch {
    const cleaned = text
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/i, "")
      .replace(/\s*```$/i, "")
      .trim();
    return JSON.parse(cleaned);
  }
}

// ═══════════════════════════════════════════════════════════════
// NORMALIZATION HELPERS
// ═══════════════════════════════════════════════════════════════

function normalizeNullableString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const str = String(value).trim();
  if (!str || str.toLowerCase() === "null" || str === "undefined") return null;
  return str;
}

function normalizePriority(value: unknown): "low" | "medium" | "high" {
  const v = String(value ?? "").trim().toLowerCase();
  if (v === "low" || v === "high") return v;
  return "medium";
}

const VALID_ITEM_TYPES = new Set(["task", "meeting", "followup", "reminder", "idea", "shopping"]);
type ItemType = "task" | "meeting" | "followup" | "reminder" | "idea" | "shopping";

function normalizeItemType(value: unknown): ItemType {
  const v = String(value ?? "").trim().toLowerCase();
  return VALID_ITEM_TYPES.has(v) ? (v as ItemType) : "task";
}

function normalizeReminderOffset(value: unknown): number {
  const n = Number(value);
  if (!Number.isFinite(n)) return 30;
  return Math.max(0, Math.min(1440, Math.round(n)));
}

function isValidDate(str: string | null): boolean {
  if (!str) return false;
  return /^\d{4}-\d{2}-\d{2}$/.test(str) && !isNaN(Date.parse(str));
}

function isValidTime(str: string | null): boolean {
  if (!str) return false;
  return /^\d{2}:\d{2}$/.test(str);
}

// ═══════════════════════════════════════════════════════════════
// AXIS 4: BUSINESS VALIDATION RULES (post-parse)
// ═══════════════════════════════════════════════════════════════

function applyBusinessRules(parsed: Record<string, unknown>, rawText: string): Record<string, unknown> {
  const result = { ...parsed };

  // ── Rule 1: followup consistency ──
  // If is_followup=true or item_type mentions followup, unify
  if (result.is_followup === true || result.item_type === "followup") {
    result.item_type = "followup";
    result.is_followup = true;
  }

  // ── Rule 2: title fallback ──
  // If title is empty or too generic, derive from raw_text
  const title = String(result.title ?? "").trim();
  if (!title || title.length < 3 || title === "مهمة" || title === "تذكير") {
    result.title = rawText.length > 60 ? rawText.substring(0, 57) + "..." : rawText;
  }

  // ── Rule 3: priority safety ──
  result.priority = normalizePriority(result.priority);

  // ── Rule 4: reminder_offset_minutes bounds ──
  result.reminder_offset_minutes = normalizeReminderOffset(result.reminder_offset_minutes);

  // ── Rule 5: date/time consistency ──
  const dueDate = normalizeNullableString(result.due_date);
  const dueTime = normalizeNullableString(result.due_time);

  // Validate date format
  if (dueDate && !isValidDate(dueDate)) {
    result.due_date = null;
  }
  // Validate time format
  if (dueTime && !isValidTime(dueTime)) {
    result.due_time = null;
  }
  // If time exists but date doesn't — only keep time if there's clear intent
  if (result.due_time && !result.due_date) {
    const hasExplicitTimeRef = Boolean(result.has_explicit_time_reference);
    if (!hasExplicitTimeRef) {
      result.due_time = null;
    }
  }

  // ── Rule 6: meeting without clear time → task ──
  if (result.item_type === "meeting" && !result.due_date && !result.due_time) {
    result.item_type = "task";
  }

  // ── Rule 7: idea/shopping with no explicit time → null dates ──
  const hasExplicitTimeRef = Boolean(result.has_explicit_time_reference);
  if ((result.item_type === "idea" || result.item_type === "shopping") && !hasExplicitTimeRef) {
    result.due_date = null;
    result.due_time = null;
  }

  // ── Rule 8: confirmation_text fallback ──
  const confirmation = String(result.confirmation_text ?? "").trim();
  if (!confirmation) {
    const typeLabels: Record<string, string> = {
      task: "المهمة", meeting: "الموعد", followup: "المتابعة",
      reminder: "التذكير", idea: "الفكرة", shopping: "قائمة المشتريات",
    };
    const label = typeLabels[String(result.item_type)] || "العنصر";
    result.confirmation_text = `تم إضافة ${label}: ${String(result.title).substring(0, 30)}`;
  }

  // ── Rule 9: linked_person cleanup ──
  const person = normalizeNullableString(result.linked_person);
  result.linked_person = person;

  // ── Rule 10: recurrence_rule cleanup ──
  const recurrence = normalizeNullableString(result.recurrence_rule);
  if (recurrence) {
    const validRecurrencePatterns = ["يومي", "أسبوعي", "شهري"];
    const validDayPatterns = ["كل أحد", "كل اثنين", "كل ثلاثاء", "كل أربعاء", "كل خميس", "كل جمعة", "كل سبت"];
    const isValid = validRecurrencePatterns.some(p => recurrence.includes(p)) ||
                    validDayPatterns.some(p => recurrence.includes(p));
    result.recurrence_rule = isValid ? recurrence : null;
  } else {
    result.recurrence_rule = null;
  }

  // Clean up — remove internal AI field from final output
  delete result.has_explicit_time_reference;

  return result;
}

// ═══════════════════════════════════════════════════════════════
// NORMALIZE + VALIDATE full pipeline
// ═══════════════════════════════════════════════════════════════

function validateAndNormalize(raw: Record<string, unknown>, rawText: string): Record<string, unknown> {
  const p = raw ?? {};

  // Basic normalization
  const normalized: Record<string, unknown> = {
    title: String(p.title ?? "").trim() || "مهمة جديدة",
    item_type: normalizeItemType(p.item_type),
    due_date: normalizeNullableString(p.due_date),
    due_time: normalizeNullableString(p.due_time),
    priority: normalizePriority(p.priority),
    linked_person: normalizeNullableString(p.linked_person),
    recurrence_rule: normalizeNullableString(p.recurrence_rule),
    is_followup: Boolean(p.is_followup ?? p.item_type === "followup"),
    notes: String(p.notes ?? "").trim(),
    reminder_offset_minutes: normalizeReminderOffset(p.reminder_offset_minutes),
    confirmation_text: String(p.confirmation_text ?? "").trim(),
    has_explicit_time_reference: Boolean(p.has_explicit_time_reference),
  };

  // Apply business validation rules
  return applyBusinessRules(normalized, rawText);
}

// ═══════════════════════════════════════════════════════════════
// AXIS 2: PROVIDER ABSTRACTION
// ═══════════════════════════════════════════════════════════════

function buildMessages(ctx: ParseContext): Array<{ role: string; content: string }> {
  const userMessage = `النص: "${ctx.raw_text}"

السياق:
- source: ${ctx.source}
- audio_url: ${ctx.audio_url || "null"}
- current_date: ${ctx.currentDate}
- current_time: ${ctx.currentTime}
- after_asr_time: ${ctx.afterAsrTime}
- after_maghrib_time: ${ctx.afterMaghribTime}
- timezone: ${ctx.timezone}

أعد JSON فقط حسب الشكل المطلوب.`;

  return [
    { role: "system", content: SYSTEM_PROMPT_V2 },
    { role: "user", content: userMessage },
  ];
}

async function callDeepSeek(messages: Array<{ role: string; content: string }>): Promise<ProviderResult> {
  const response = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${DEEPSEEK_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      messages,
      temperature: 0.1,
      max_tokens: 500,
      response_format: { type: "json_object" },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`DeepSeek API error (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (!content || typeof content !== "string") {
    throw new Error("DeepSeek returned empty content");
  }

  return {
    raw: safeJsonParse(content),
    provider: "deepseek",
    model: data?.model || "deepseek-chat",
  };
}

async function callOpenAI(messages: Array<{ role: string; content: string }>): Promise<ProviderResult> {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages,
      temperature: 0.1,
      response_format: { type: "json_object" },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI API error (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (!content || typeof content !== "string") {
    throw new Error("OpenAI returned empty content");
  }

  return {
    raw: safeJsonParse(content),
    provider: "openai",
    model: data?.model || "gpt-4o-mini",
  };
}

function isTransientError(error: Error): boolean {
  const msg = error.message.toLowerCase();
  return msg.includes("timeout") ||
         msg.includes("rate limit") ||
         msg.includes("429") ||
         msg.includes("503") ||
         msg.includes("502") ||
         msg.includes("network") ||
         msg.includes("fetch");
}

// ─── Orchestrator: retry + fallback logic ─────────────────────
async function orchestrateParse(
  messages: Array<{ role: string; content: string }>
): Promise<{ result: ProviderResult; attempts: number }> {
  let attempts = 0;
  const errors: string[] = [];

  // Attempt 1: primary provider (DeepSeek)
  const primaryFn = AI_DEFAULT === "openai" && OPENAI_API_KEY ? callOpenAI : callDeepSeek;
  const primaryName = AI_DEFAULT === "openai" ? "openai" : "deepseek";
  const primaryKey = primaryName === "openai" ? OPENAI_API_KEY : DEEPSEEK_API_KEY;

  if (!primaryKey) {
    throw new Error(`${primaryName.toUpperCase()}_API_KEY غير موجود`);
  }

  try {
    attempts++;
    const result = await primaryFn(messages);
    return { result, attempts };
  } catch (e: any) {
    errors.push(`${primaryName}[1]: ${e.message}`);

    // Attempt 2: retry primary if transient or JSON parse failure
    if (isTransientError(e) || e.message.includes("JSON")) {
      try {
        attempts++;
        const result = await primaryFn(messages);
        return { result, attempts };
      } catch (e2: any) {
        errors.push(`${primaryName}[2]: ${e2.message}`);
      }
    }
  }

  // Attempt 3: fallback provider
  if (ENABLE_FALLBACK) {
    const fallbackFn = primaryName === "deepseek" ? callOpenAI : callDeepSeek;
    const fallbackName = primaryName === "deepseek" ? "openai" : "deepseek";
    const fallbackKey = fallbackName === "openai" ? OPENAI_API_KEY : DEEPSEEK_API_KEY;

    if (fallbackKey) {
      try {
        attempts++;
        const result = await fallbackFn(messages);
        return { result, attempts };
      } catch (e3: any) {
        errors.push(`${fallbackName}[fallback]: ${e3.message}`);
      }
    }
  }

  throw new Error(`All providers failed after ${attempts} attempts: ${errors.join(" | ")}`);
}

// ═══════════════════════════════════════════════════════════════
// MAIN HANDLER
// ═══════════════════════════════════════════════════════════════

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", jsonHeaders(200));
  }

  const startTime = Date.now();

  try {
    const {
      raw_text,
      source,
      audio_url,
      user_timezone,
      current_datetime,
      user_settings,
    } = await req.json();

    if (!raw_text || String(raw_text).trim() === "") {
      return new Response(
        JSON.stringify({
          success: false,
          prompt_version: PROMPT_VERSION,
          parse_attempts: 0,
          error: "النص فارغ",
        }),
        jsonHeaders(400),
      );
    }

    const now = current_datetime || new Date().toISOString();
    const ctx: ParseContext = {
      raw_text: String(raw_text).trim(),
      source: source || "voice",
      audio_url: audio_url || null,
      currentDate: now.split("T")[0],
      currentTime: now.split("T")[1]?.substring(0, 5) || "12:00",
      afterAsrTime: user_settings?.after_asr_time || "15:30",
      afterMaghribTime: user_settings?.after_maghrib_time || "18:30",
      timezone: user_timezone || "Asia/Riyadh",
    };

    const messages = buildMessages(ctx);

    // ── Orchestrate: primary → retry → fallback ──
    const { result, attempts } = await orchestrateParse(messages);

    // ── Validate + normalize + business rules ──
    const parsed = validateAndNormalize(result.raw, ctx.raw_text);

    const latencyMs = Date.now() - startTime;

    return new Response(
      JSON.stringify({
        success: true,
        provider: result.provider,
        model: result.model,
        prompt_version: PROMPT_VERSION,
        parse_attempts: attempts,
        parse_latency_ms: latencyMs,
        parsed,
        confirmation_text: parsed.confirmation_text,
      }),
      jsonHeaders(200),
    );
  } catch (error: any) {
    const latencyMs = Date.now() - startTime;

    return new Response(
      JSON.stringify({
        success: false,
        provider: AI_DEFAULT,
        prompt_version: PROMPT_VERSION,
        parse_attempts: 0,
        parse_latency_ms: latencyMs,
        error: error?.message || "حدث خطأ غير متوقع",
      }),
      jsonHeaders(500),
    );
  }
});
