// سَكرتيرك — Generate Briefing Edge Function
// Generates morning/evening daily summaries using OpenAI

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;

serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { user_id, briefing_type, date } = await req.json();

    if (!user_id || !briefing_type) {
      return new Response(
        JSON.stringify({ success: false, error: "بيانات ناقصة" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Fetch today's tasks
    const { data: todayTasks } = await supabase
      .from("tasks")
      .select("title, item_type, due_time, priority, status")
      .eq("user_id", user_id)
      .eq("due_date", date)
      .neq("status", "cancelled")
      .order("due_time", { ascending: true });

    // Fetch overdue tasks
    const { data: overdueTasks } = await supabase
      .from("tasks")
      .select("title, item_type, due_date, priority")
      .eq("user_id", user_id)
      .eq("status", "pending")
      .lt("due_date", date);

    // Fetch completed today
    const { data: completedToday } = await supabase
      .from("tasks")
      .select("title")
      .eq("user_id", user_id)
      .eq("status", "done")
      .eq("due_date", date);

    const isMorning = briefing_type === "morning";

    const prompt = isMorning
      ? `أنت سكرتير شخصي عربي. اكتب ملخصًا صباحيًا مختصرًا وودودًا.

مهام اليوم: ${JSON.stringify(todayTasks || [])}
مهام متأخرة: ${JSON.stringify(overdueTasks || [])}

اكتب ملخصًا بهذا الشكل:
- تحية صباحية
- عدد مهام اليوم
- أهم 3 مهام
- تنبيه بالمتأخرات إن وجدت
- جملة تحفيزية

اجعل النص قصيرًا ومباشرًا.`
      : `أنت سكرتير شخصي عربي. اكتب ملخصًا مسائيًا مختصرًا.

مهام اليوم: ${JSON.stringify(todayTasks || [])}
مهام مكتملة: ${JSON.stringify(completedToday || [])}
مهام متأخرة: ${JSON.stringify(overdueTasks || [])}

اكتب ملخصًا بهذا الشكل:
- تحية مسائية
- عدد المهام المنجزة
- المتبقي
- المتأخرات
- ملاحظة ختامية

اجعل النص قصيرًا ومباشرًا.`;

    // Call OpenAI
    const openAiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: prompt },
        ],
        temperature: 0.7,
        max_tokens: 500,
      }),
    });

    if (!openAiResponse.ok) {
      throw new Error("OpenAI API error");
    }

    const openAiData = await openAiResponse.json();
    const summary = openAiData.choices[0].message.content;

    // Save to daily_briefings
    const briefingData: any = {
      user_id,
      brief_date: date,
    };

    if (isMorning) {
      briefingData.morning_summary = summary;
    } else {
      briefingData.evening_summary = summary;
    }

    await supabase
      .from("daily_briefings")
      .upsert(briefingData, { onConflict: "user_id,brief_date" });

    return new Response(
      JSON.stringify({
        success: true,
        summary,
        today_count: todayTasks?.length || 0,
        overdue_count: overdueTasks?.length || 0,
        completed_count: completedToday?.length || 0,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
