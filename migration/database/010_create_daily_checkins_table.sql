-- Create daily_checkins table for tracking user reading activity
CREATE TABLE IF NOT EXISTS daily_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  check_in_date DATE NOT NULL,
  read_count INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, check_in_date)
);

-- Enable RLS
ALTER TABLE daily_checkins ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own check-ins
CREATE POLICY "Users can view own check-ins"
  ON daily_checkins FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own check-ins
CREATE POLICY "Users can insert own check-ins"
  ON daily_checkins FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own check-ins
CREATE POLICY "Users can update own check-ins"
  ON daily_checkins FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own check-ins
CREATE POLICY "Users can delete own check-ins"
  ON daily_checkins FOR DELETE
  USING (auth.uid() = user_id);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_checkins_user_date 
  ON daily_checkins(user_id, check_in_date DESC);

CREATE INDEX IF NOT EXISTS idx_checkins_user_created 
  ON daily_checkins(user_id, created_at DESC);

