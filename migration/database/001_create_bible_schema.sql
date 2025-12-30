-- NOTE: Bible verses are fetched from external API (https://bible.helloao.org/api)
-- No need for bible_verses table since we use API for all verse data

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  primary_language TEXT NOT NULL DEFAULT 'niv',
  secondary_language TEXT NOT NULL DEFAULT 'cuv',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Create reading_progress table (for later auth integration)
CREATE TABLE IF NOT EXISTS reading_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  last_verse INTEGER NOT NULL,
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, book, chapter)
);

-- NOTE: Verse highlights removed since bible_verses table doesn't exist
-- If needed in future, store verse reference (book, chapter, verse_number) instead of verse_id

-- Enable RLS on user tables (will be used when auth is added)
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;

-- RLS policies for user_preferences
CREATE POLICY "Users can view their own preferences" ON user_preferences
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own preferences" ON user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own preferences" ON user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS policies for reading_progress
CREATE POLICY "Users can view their own progress" ON reading_progress
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own progress" ON reading_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own progress" ON reading_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- Bible verses are fetched from external API
-- No database storage needed for verse content
