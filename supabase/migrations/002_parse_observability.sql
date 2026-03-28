-- ============================================
-- سَكرتيرك — Migration 002: Parse Observability
-- Adds metadata columns to inbox_entries for
-- tracking AI provider, latency, and errors.
-- ============================================

-- ── Axis 3: observability fields ──

ALTER TABLE public.inbox_entries
  ADD COLUMN IF NOT EXISTS provider       TEXT,
  ADD COLUMN IF NOT EXISTS model          TEXT,
  ADD COLUMN IF NOT EXISTS prompt_version TEXT,
  ADD COLUMN IF NOT EXISTS parse_attempts INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS parse_latency_ms INTEGER,
  ADD COLUMN IF NOT EXISTS parse_error    TEXT,
  ADD COLUMN IF NOT EXISTS parsed_at      TIMESTAMPTZ;

-- Index for analytics queries
CREATE INDEX IF NOT EXISTS idx_inbox_provider
  ON public.inbox_entries(provider, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_inbox_status_error
  ON public.inbox_entries(status, parse_error)
  WHERE parse_error IS NOT NULL;

COMMENT ON COLUMN public.inbox_entries.provider IS 'AI provider used: deepseek | openai';
COMMENT ON COLUMN public.inbox_entries.model IS 'Exact model used (deepseek-chat, gpt-4o-mini, etc.)';
COMMENT ON COLUMN public.inbox_entries.prompt_version IS 'Prompt version (v1, v2, ...)';
COMMENT ON COLUMN public.inbox_entries.parse_attempts IS 'Number of API call attempts before success/failure';
COMMENT ON COLUMN public.inbox_entries.parse_latency_ms IS 'Total parse time in milliseconds';
COMMENT ON COLUMN public.inbox_entries.parse_error IS 'Error message if parsing failed';
COMMENT ON COLUMN public.inbox_entries.parsed_at IS 'Timestamp when parsing completed (success or failure)';
