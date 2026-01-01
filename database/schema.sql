-- Neo AI Running Coach - Database Schema
-- PostgreSQL / Supabase

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  phone TEXT PRIMARY KEY,
  nom TEXT,
  edat INTEGER,
  pes DECIMAL(5,2),
  sexe TEXT CHECK (sexe IN ('home', 'dona', 'altre')),
  terreny TEXT CHECK (terreny IN ('asfalto', 'tierra', 'mixto')),
  dies_disponibles INTEGER CHECK (dies_disponibles BETWEEN 1 AND 7),
  disponibilitat_detallada TEXT,
  nivell TEXT CHECK (nivell IN ('principiante', 'intermedio', 'avanzado')),
  objectius TEXT,
  subscripcio TEXT CHECK (subscripcio IN ('active', 'trial', 'canceled')) DEFAULT 'trial',
  stripe_customer_id TEXT,
  onboarding_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on subscription status
CREATE INDEX IF NOT EXISTS idx_users_subscription ON users(subscripcio);
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer ON users(stripe_customer_id);

-- ============================================================================
-- CHAT HISTORY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS chat_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_phone TEXT NOT NULL REFERENCES users(phone) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_chat_history_phone ON chat_history(user_phone);
CREATE INDEX IF NOT EXISTS idx_chat_history_created ON chat_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_history_phone_created ON chat_history(user_phone, created_at DESC);

-- ============================================================================
-- WEEKLY PLANS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_phone TEXT NOT NULL REFERENCES users(phone) ON DELETE CASCADE,
  week_number INTEGER NOT NULL,
  plan_text TEXT NOT NULL,
  status TEXT CHECK (status IN ('active', 'completed')) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_phone, week_number)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_weekly_plans_phone ON weekly_plans(user_phone);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_status ON weekly_plans(status);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_phone_status ON weekly_plans(user_phone, status);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_week_number ON weekly_plans(week_number DESC);

-- ============================================================================
-- WORKOUT HISTORY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS workout_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_phone TEXT NOT NULL REFERENCES users(phone) ON DELETE CASCADE,
  week_number INTEGER NOT NULL,
  session_number INTEGER NOT NULL,
  distance DECIMAL(5,2) NOT NULL CHECK (distance > 0),
  time_minutes DECIMAL(6,2) NOT NULL CHECK (time_minutes > 0),
  pace_min_per_km DECIMAL(5,2) NOT NULL CHECK (pace_min_per_km > 0),
  difficulty_rating INTEGER NOT NULL CHECK (difficulty_rating BETWEEN 1 AND 10),
  feedback TEXT,
  completed BOOLEAN DEFAULT true,
  completion_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_phone, week_number, session_number)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_workout_history_phone ON workout_history(user_phone);
CREATE INDEX IF NOT EXISTS idx_workout_history_completion ON workout_history(completion_date DESC);
CREATE INDEX IF NOT EXISTS idx_workout_history_week ON workout_history(week_number);
CREATE INDEX IF NOT EXISTS idx_workout_history_phone_week ON workout_history(user_phone, week_number DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_history ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Allow anon to insert users" 
ON users FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to read users" 
ON users FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to update users" 
ON users FOR UPDATE TO anon USING (true);

-- Chat history policies
CREATE POLICY "Allow anon to insert chat_history" 
ON chat_history FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to read chat_history" 
ON chat_history FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to update chat_history" 
ON chat_history FOR UPDATE TO anon USING (true);

-- Weekly plans policies
CREATE POLICY "Allow anon to insert weekly_plans" 
ON weekly_plans FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to read weekly_plans" 
ON weekly_plans FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to update weekly_plans" 
ON weekly_plans FOR UPDATE TO anon USING (true);

-- Workout history policies
CREATE POLICY "Allow anon to insert workout_history" 
ON workout_history FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anon to read workout_history" 
ON workout_history FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anon to update workout_history" 
ON workout_history FOR UPDATE TO anon USING (true);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at 
BEFORE UPDATE ON users 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_plans_updated_at 
BEFORE UPDATE ON weekly_plans 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SAMPLE QUERIES (for testing)
-- ============================================================================

-- Get user with subscription info
-- SELECT * FROM users WHERE phone = '2349056323196';

-- Get last 10 chat messages for user
-- SELECT * FROM chat_history 
-- WHERE user_phone = '2349056323196' 
-- ORDER BY created_at DESC 
-- LIMIT 10;

-- Get active weekly plan
-- SELECT * FROM weekly_plans 
-- WHERE user_phone = '2349056323196' 
-- AND status = 'active' 
-- ORDER BY week_number DESC 
-- LIMIT 1;

-- Get workout history for current week
-- SELECT * FROM workout_history 
-- WHERE user_phone = '2349056323196' 
-- AND week_number = 1
-- ORDER BY session_number;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================