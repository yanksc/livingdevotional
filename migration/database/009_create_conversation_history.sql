-- Create conversation history tables for verse AI features
-- Supports both explanation and question chat histories

-- Table for verse explanation conversations
CREATE TABLE IF NOT EXISTS verse_explanation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table for verse question conversations
CREATE TABLE IF NOT EXISTS verse_question_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookup by user and verse
CREATE INDEX IF NOT EXISTS idx_explanation_history_user_verse 
  ON verse_explanation_history(user_id, book, chapter, verse_number, created_at);

CREATE INDEX IF NOT EXISTS idx_question_history_user_verse 
  ON verse_question_history(user_id, book, chapter, verse_number, created_at);

-- Enable Row Level Security
ALTER TABLE verse_explanation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE verse_question_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for verse_explanation_history
CREATE POLICY "Users can view their own explanation history"
  ON verse_explanation_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own explanation history"
  ON verse_explanation_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own explanation history"
  ON verse_explanation_history FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for verse_question_history
CREATE POLICY "Users can view their own question history"
  ON verse_question_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own question history"
  ON verse_question_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own question history"
  ON verse_question_history FOR DELETE
  USING (auth.uid() = user_id);

