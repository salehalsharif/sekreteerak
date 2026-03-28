#!/usr/bin/env -S deno run --allow-net --allow-read --allow-env
// ═══════════════════════════════════════════════════════════════
// سَكرتيرك — Parse Benchmark Runner
// Runs the 50-command dataset against the Edge Function
// Shows pass/fail, mismatches, and summary stats.
//
// Usage:
//   deno run --allow-net --allow-read --allow-env tests/benchmark/run_benchmark.ts
//
// Environment:
//   SUPABASE_URL       (required)
//   SUPABASE_ANON_KEY  (required)
//   TEST_USER_TOKEN    (required — a valid JWT for an authenticated user)
// ═══════════════════════════════════════════════════════════════

interface TestCase {
  id: number;
  raw_text: string;
  expected_item_type: string;
  expected_due_date: string | null;
  expected_due_time: string | null;
  expected_priority: string;
  expected_is_followup: boolean;
  expected_linked_person: string | null;
  expected_recurrence_rule?: string | null;
  notes: string;
}

interface TestResult {
  id: number;
  raw_text: string;
  pass: boolean;
  mismatches: string[];
  actual: Record<string, unknown>;
  latencyMs: number;
}

// ── Relative date keywords → skip exact date matching ──
const RELATIVE_DATES = new Set([
  "today", "tomorrow", "next_thursday", "next_saturday", "next_sunday",
  "next_wednesday", "next_monday", "in_7_days", "first_of_month",
  "end_of_month", "after_asr", "after_maghrib",
]);

function compareDueDate(expected: string | null, actual: unknown): boolean {
  if (expected === null) return actual === null || actual === undefined;
  if (RELATIVE_DATES.has(expected)) {
    // For relative dates, just check it's not null (actual resolution depends on current date)
    return actual !== null && actual !== undefined;
  }
  return String(actual) === expected;
}

function compareDueTime(expected: string | null, actual: unknown): boolean {
  if (expected === null) return actual === null || actual === undefined;
  if (expected === "after_asr" || expected === "after_maghrib") {
    return actual !== null && actual !== undefined;
  }
  return String(actual) === expected;
}

async function runBenchmark() {
  const SUPABASE_URL  = Deno.env.get("SUPABASE_URL");
  const ANON_KEY      = Deno.env.get("SUPABASE_ANON_KEY");
  const USER_TOKEN    = Deno.env.get("TEST_USER_TOKEN");

  if (!SUPABASE_URL || !ANON_KEY) {
    console.error("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY");
    Deno.exit(1);
  }

  // Load dataset
  const datasetPath = new URL("./parse_benchmark_dataset.json", import.meta.url);
  const datasetText = await Deno.readTextFile(datasetPath);
  const dataset: TestCase[] = JSON.parse(datasetText);

  console.log(`\n═══ سَكرتيرك Parse Benchmark ═══`);
  console.log(`Dataset: ${dataset.length} commands\n`);

  const results: TestResult[] = [];
  let passed = 0;
  let failed = 0;
  let totalLatency = 0;

  for (const tc of dataset) {
    const start = Date.now();

    try {
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
        "apikey": ANON_KEY,
      };
      if (USER_TOKEN) {
        headers["Authorization"] = `Bearer ${USER_TOKEN}`;
      }

      const resp = await fetch(
        `${SUPABASE_URL}/functions/v1/parse-voice-input`,
        {
          method: "POST",
          headers,
          body: JSON.stringify({
            raw_text: tc.raw_text,
            source: "text",
            current_datetime: new Date().toISOString(),
            user_settings: {
              after_asr_time: "15:30",
              after_maghrib_time: "18:30",
            },
          }),
        },
      );

      const data = await resp.json();
      const latency = Date.now() - start;
      totalLatency += latency;

      if (!data.success) {
        results.push({
          id: tc.id,
          raw_text: tc.raw_text,
          pass: false,
          mismatches: [`API error: ${data.error}`],
          actual: data,
          latencyMs: latency,
        });
        failed++;
        console.log(`  ❌ #${tc.id}: API error — ${data.error}`);
        continue;
      }

      const parsed = data.parsed;
      const mismatches: string[] = [];

      // Check item_type
      if (parsed.item_type !== tc.expected_item_type) {
        mismatches.push(`item_type: expected=${tc.expected_item_type} got=${parsed.item_type}`);
      }

      // Check due_date
      if (!compareDueDate(tc.expected_due_date, parsed.due_date)) {
        mismatches.push(`due_date: expected=${tc.expected_due_date} got=${parsed.due_date}`);
      }

      // Check due_time
      if (!compareDueTime(tc.expected_due_time, parsed.due_time)) {
        mismatches.push(`due_time: expected=${tc.expected_due_time} got=${parsed.due_time}`);
      }

      // Check priority
      if (parsed.priority !== tc.expected_priority) {
        mismatches.push(`priority: expected=${tc.expected_priority} got=${parsed.priority}`);
      }

      // Check is_followup
      if (Boolean(parsed.is_followup) !== tc.expected_is_followup) {
        mismatches.push(`is_followup: expected=${tc.expected_is_followup} got=${parsed.is_followup}`);
      }

      // Check linked_person (null-safe)
      const expectedPerson = tc.expected_linked_person;
      const actualPerson = parsed.linked_person ?? null;
      if (expectedPerson === null && actualPerson !== null) {
        mismatches.push(`linked_person: expected=null got=${actualPerson}`);
      } else if (expectedPerson !== null && actualPerson === null) {
        mismatches.push(`linked_person: expected=${expectedPerson} got=null`);
      }

      // Check recurrence_rule if expected
      if (tc.expected_recurrence_rule !== undefined) {
        const actualRecurrence = parsed.recurrence_rule ?? null;
        if (tc.expected_recurrence_rule === null && actualRecurrence !== null) {
          mismatches.push(`recurrence_rule: expected=null got=${actualRecurrence}`);
        } else if (tc.expected_recurrence_rule !== null && actualRecurrence === null) {
          mismatches.push(`recurrence_rule: expected=${tc.expected_recurrence_rule} got=null`);
        }
      }

      const isPass = mismatches.length === 0;

      results.push({
        id: tc.id,
        raw_text: tc.raw_text,
        pass: isPass,
        mismatches,
        actual: parsed,
        latencyMs: latency,
      });

      if (isPass) {
        passed++;
        console.log(`  ✅ #${tc.id}: ${tc.raw_text.substring(0, 40)}... (${latency}ms)`);
      } else {
        failed++;
        console.log(`  ❌ #${tc.id}: ${tc.raw_text.substring(0, 40)}...`);
        mismatches.forEach(m => console.log(`      ↳ ${m}`));
      }

    } catch (err: any) {
      const latency = Date.now() - start;
      totalLatency += latency;
      results.push({
        id: tc.id,
        raw_text: tc.raw_text,
        pass: false,
        mismatches: [`Exception: ${err.message}`],
        actual: {},
        latencyMs: latency,
      });
      failed++;
      console.log(`  ❌ #${tc.id}: Exception — ${err.message}`);
    }
  }

  // ── Summary ──
  const avgLatency = Math.round(totalLatency / dataset.length);
  const passRate = Math.round((passed / dataset.length) * 100);

  console.log(`\n═══ Summary ═══`);
  console.log(`  Total:     ${dataset.length}`);
  console.log(`  Passed:    ${passed} (${passRate}%)`);
  console.log(`  Failed:    ${failed}`);
  console.log(`  Avg Latency: ${avgLatency}ms`);
  console.log(`  Total Time:  ${totalLatency}ms`);

  if (failed > 0) {
    console.log(`\n═══ Failed Cases ═══`);
    results
      .filter(r => !r.pass)
      .forEach(r => {
        console.log(`\n  #${r.id}: "${r.raw_text}"`);
        r.mismatches.forEach(m => console.log(`    ↳ ${m}`));
      });
  }

  console.log(`\n═══ Done ═══\n`);
}

await runBenchmark();
