-- Enable pg_stat_statements for performance tracking if needed
-- create extension if not exists pg_stat_statements;

-- Enum for different game types
CREATE TYPE lotto_game_type AS ENUM ('super_lotto_638', 'lotto_649', 'daily_cash_539');

-- Draws table to store all historical results
CREATE TABLE public.draws (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    draw_id VARCHAR(50) NOT NULL,
    game_type lotto_game_type NOT NULL,
    draw_date DATE NOT NULL,
    numbers INTEGER[] NOT NULL,
    special_number INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(draw_id, game_type)
);

-- Index for querying recent draws
CREATE INDEX idx_draws_date ON public.draws(game_type, draw_date DESC);

-- Table for storing daily predictions/computations from the Vercel cron job
-- This avoids recalculating the Monte Carlo and other heavy models on every user load.
CREATE TABLE public.prediction_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_type lotto_game_type NOT NULL,
    prediction_date DATE NOT NULL, -- The date this prediction targets
    alpha_set JSONB NOT NULL, -- e.g. {"numbers": [...], "justification": "..."}
    beta_set JSONB NOT NULL,
    gamma_set JSONB NOT NULL,
    stats_summary JSONB, -- Pre-computed Hot/Cold, mean/metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(game_type, prediction_date)
);

-- Index to quickly find the latest prediction cache
CREATE INDEX idx_prediction_cache_date ON public.prediction_cache(game_type, prediction_date DESC);

-- Setup RLS (Row Level Security)
ALTER TABLE public.draws ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_cache ENABLE ROW LEVEL SECURITY;

-- Allow public read access to everyone
CREATE POLICY "Public Read Access"
ON public.draws FOR SELECT
USING (true);

CREATE POLICY "Public Read Access"
ON public.prediction_cache FOR SELECT
USING (true);

-- Backend (Serverless functions with SERVICE_ROLE_KEY) will bypass RLS to insert/update data.
