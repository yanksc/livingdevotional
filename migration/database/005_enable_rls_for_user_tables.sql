-- Enable Row Level Security on user tables

-- User preferences table
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own preferences"
  ON user_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences"
  ON user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences"
  ON user_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own preferences"
  ON user_preferences FOR DELETE
  USING (auth.uid() = user_id);

-- Reading progress table
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own reading progress"
  ON reading_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own reading progress"
  ON reading_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reading progress"
  ON reading_progress FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reading progress"
  ON reading_progress FOR DELETE
  USING (auth.uid() = user_id);

-- Verse highlights table
ALTER TABLE verse_highlights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own verse highlights"
  ON verse_highlights FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own verse highlights"
  ON verse_highlights FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own verse highlights"
  ON verse_highlights FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own verse highlights"
  ON verse_highlights FOR DELETE
  USING (auth.uid() = user_id);
