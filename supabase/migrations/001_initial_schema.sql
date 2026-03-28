-- ============================================
-- سَكرتيرك — Initial Database Schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ──────────────────────────────────────────────
-- PROFILES (extends Supabase auth.users)
-- ──────────────────────────────────────────────
CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   TEXT,
  phone       TEXT,
  locale      TEXT DEFAULT 'ar',
  timezone    TEXT DEFAULT 'Asia/Riyadh',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────
-- USER SETTINGS
-- ──────────────────────────────────────────────
CREATE TABLE public.user_settings (
  id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  default_reminder_minutes INTEGER DEFAULT 30,
  workday_start            TIME DEFAULT '08:00',
  workday_end              TIME DEFAULT '18:00',
  after_asr_time           TIME DEFAULT '15:30',
  after_maghrib_time       TIME DEFAULT '18:30',
  summary_enabled          BOOLEAN DEFAULT TRUE,
  morning_summary_time     TIME DEFAULT '07:00',
  evening_summary_time     TIME DEFAULT '21:00',
  created_at               TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ──────────────────────────────────────────────
-- INBOX ENTRIES (raw voice/text input)
-- ──────────────────────────────────────────────
CREATE TYPE source_type AS ENUM ('voice', 'text');
CREATE TYPE parse_status AS ENUM ('pending', 'parsed', 'failed');

CREATE TABLE public.inbox_entries (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  raw_text          TEXT,
  source            source_type NOT NULL DEFAULT 'voice',
  original_audio_url TEXT,
  parsed_json       JSONB,
  status            parse_status DEFAULT 'pending',
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────
-- TASKS
-- ──────────────────────────────────────────────
CREATE TYPE item_type AS ENUM ('task', 'meeting', 'followup', 'reminder', 'idea', 'shopping');
CREATE TYPE task_status AS ENUM ('pending', 'done', 'snoozed', 'cancelled');
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high');

CREATE TABLE public.tasks (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  description      TEXT,
  item_type        item_type DEFAULT 'task',
  status           task_status DEFAULT 'pending',
  priority         priority_level DEFAULT 'medium',
  due_date         DATE,
  due_time         TIME,
  reminder_at      TIMESTAMPTZ,
  recurrence_rule  TEXT,
  linked_person    TEXT,
  source_entry_id  UUID REFERENCES public.inbox_entries(id),
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  completed_at     TIMESTAMPTZ
);

-- ──────────────────────────────────────────────
-- TASK EVENTS (audit trail)
-- ──────────────────────────────────────────────
CREATE TYPE event_type AS ENUM ('created', 'edited', 'snoozed', 'completed', 'missed', 'rescheduled');

CREATE TABLE public.task_events (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id     UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  event       event_type NOT NULL,
  payload     JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────
-- DAILY BRIEFINGS
-- ──────────────────────────────────────────────
CREATE TABLE public.daily_briefings (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  brief_date       DATE NOT NULL,
  morning_summary  TEXT,
  evening_summary  TEXT,
  generated_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, brief_date)
);

-- ──────────────────────────────────────────────
-- SUBSCRIPTIONS
-- ──────────────────────────────────────────────
CREATE TYPE plan_name AS ENUM ('free', 'pro', 'business_lite');
CREATE TYPE sub_status AS ENUM ('active', 'expired', 'cancelled');

CREATE TABLE public.subscriptions (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan       plan_name DEFAULT 'free',
  status     sub_status DEFAULT 'active',
  renews_at  TIMESTAMPTZ,
  provider   TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ──────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ──────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inbox_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_briefings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users read own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users manage own settings"
  ON public.user_settings FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users manage own inbox"
  ON public.inbox_entries FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users manage own tasks"
  ON public.tasks FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users read own task events"
  ON public.task_events FOR SELECT
  USING (task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid()));
CREATE POLICY "Users insert own task events"
  ON public.task_events FOR INSERT
  WITH CHECK (task_id IN (SELECT id FROM public.tasks WHERE user_id = auth.uid()));

CREATE POLICY "Users manage own briefings"
  ON public.daily_briefings FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users manage own subscription"
  ON public.subscriptions FOR ALL USING (auth.uid() = user_id);

-- ──────────────────────────────────────────────
-- INDEXES
-- ──────────────────────────────────────────────
CREATE INDEX idx_tasks_user_status ON public.tasks(user_id, status);
CREATE INDEX idx_tasks_user_due ON public.tasks(user_id, due_date);
CREATE INDEX idx_tasks_reminder ON public.tasks(reminder_at) WHERE reminder_at IS NOT NULL;
CREATE INDEX idx_inbox_user ON public.inbox_entries(user_id, created_at DESC);
CREATE INDEX idx_events_task ON public.task_events(task_id, created_at DESC);
CREATE INDEX idx_briefings_user_date ON public.daily_briefings(user_id, brief_date);

-- ──────────────────────────────────────────────
-- FUNCTIONS & TRIGGERS
-- ──────────────────────────────────────────────

-- Auto-create profile + settings + subscription on new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id);

  INSERT INTO public.subscriptions (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at on tasks
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
