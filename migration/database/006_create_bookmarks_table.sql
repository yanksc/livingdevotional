-- Create verse_bookmarks table for bookmark feature
CREATE TABLE IF NOT EXISTS verse_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  verse_text TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, book, chapter, verse_number)
);

-- Enable RLS
ALTER TABLE verse_bookmarks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own bookmarks
CREATE POLICY "Users can view own bookmarks"
  ON verse_bookmarks FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own bookmarks
CREATE POLICY "Users can insert own bookmarks"
  ON verse_bookmarks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own bookmarks
CREATE POLICY "Users can update own bookmarks"
  ON verse_bookmarks FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own bookmarks
CREATE POLICY "Users can delete own bookmarks"
  ON verse_bookmarks FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_created 
  ON verse_bookmarks(user_id, created_at DESC);
