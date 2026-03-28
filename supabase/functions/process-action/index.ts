// سَكرتيرك — Process Action Edge Function
// Handles task CRUD operations with event logging

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "غير مصرح" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get user from JWT
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "جلسة غير صالحة" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const { action, data } = await req.json();

    let result: any;

    switch (action) {
      case "create_task": {
        const taskData = {
          user_id: user.id,
          title: data.title,
          description: data.description || null,
          item_type: data.item_type || "task",
          priority: data.priority || "medium",
          due_date: data.due_date || null,
          due_time: data.due_time || null,
          reminder_at: data.reminder_at || null,
          recurrence_rule: data.recurrence_rule || null,
          linked_person: data.linked_person || null,
          source_entry_id: data.source_entry_id || null,
        };

        const { data: task, error } = await supabase
          .from("tasks")
          .insert(taskData)
          .select()
          .single();

        if (error) throw error;

        // Log creation event
        await supabase.from("task_events").insert({
          task_id: task.id,
          event: "created",
          payload: { source: data.source || "voice" },
        });

        result = { task };
        break;
      }

      case "update_task": {
        const { task_id, updates } = data;
        const { data: task, error } = await supabase
          .from("tasks")
          .update(updates)
          .eq("id", task_id)
          .eq("user_id", user.id)
          .select()
          .single();

        if (error) throw error;

        await supabase.from("task_events").insert({
          task_id,
          event: "edited",
          payload: updates,
        });

        result = { task };
        break;
      }

      case "complete_task": {
        const { task_id } = data;
        const { data: task, error } = await supabase
          .from("tasks")
          .update({
            status: "done",
            completed_at: new Date().toISOString(),
          })
          .eq("id", task_id)
          .eq("user_id", user.id)
          .select()
          .single();

        if (error) throw error;

        await supabase.from("task_events").insert({
          task_id,
          event: "completed",
        });

        result = { task };
        break;
      }

      case "snooze_task": {
        const { task_id, new_reminder_at } = data;
        const { data: task, error } = await supabase
          .from("tasks")
          .update({
            status: "snoozed",
            reminder_at: new_reminder_at,
          })
          .eq("id", task_id)
          .eq("user_id", user.id)
          .select()
          .single();

        if (error) throw error;

        await supabase.from("task_events").insert({
          task_id,
          event: "snoozed",
          payload: { new_reminder_at },
        });

        result = { task };
        break;
      }

      case "reschedule_task": {
        const { task_id, new_due_date, new_due_time } = data;
        const updates: any = {
          due_date: new_due_date,
          status: "pending",
        };
        if (new_due_time) updates.due_time = new_due_time;

        const { data: task, error } = await supabase
          .from("tasks")
          .update(updates)
          .eq("id", task_id)
          .eq("user_id", user.id)
          .select()
          .single();

        if (error) throw error;

        await supabase.from("task_events").insert({
          task_id,
          event: "rescheduled",
          payload: { new_due_date, new_due_time },
        });

        result = { task };
        break;
      }

      case "cancel_task": {
        const { task_id } = data;
        const { error } = await supabase
          .from("tasks")
          .update({ status: "cancelled" })
          .eq("id", task_id)
          .eq("user_id", user.id);

        if (error) throw error;
        result = { success: true };
        break;
      }

      default:
        return new Response(
          JSON.stringify({ success: false, error: `إجراء غير معروف: ${action}` }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
    }

    return new Response(
      JSON.stringify({ success: true, ...result }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
