-- Create curated_verses table for pre-selected meaningful verses
-- Stores only verse references (book, chapter, verse)
-- Actual text will be fetched from Bible API based on user's preferred translation
CREATE TABLE IF NOT EXISTS curated_verses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(book, chapter, verse_number)
);

-- Create index for faster random selection
CREATE INDEX IF NOT EXISTS idx_curated_verses_category ON curated_verses(category);
CREATE INDEX IF NOT EXISTS idx_curated_verses_created ON curated_verses(created_at);

-- Create daily_verse_cache table for date-based caching
CREATE TABLE IF NOT EXISTS daily_verse_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  selected_date DATE NOT NULL UNIQUE,
  book TEXT NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
  -- Note: No foreign key constraint to allow flexible caching
);

-- Create index for date lookup (most important query)
CREATE INDEX IF NOT EXISTS idx_daily_verse_date ON daily_verse_cache(selected_date);

-- Optional: Create cleanup function for old cache entries (keep last 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_daily_verses()
RETURNS void AS $$
BEGIN
  DELETE FROM daily_verse_cache
  WHERE selected_date < CURRENT_DATE - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Seed initial curated verses with meaningful, inspiring verse references
-- Text will be fetched from Bible API, so we can include any valid verse
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  -- Encouragement
  ('John', 3, 16, 'encouragement'),
  ('John', 14, 6, 'encouragement'),
  ('John', 15, 5, 'encouragement'),
  ('John', 16, 33, 'encouragement'),
  ('John', 1, 12, 'encouragement'),
  ('John', 10, 10, 'encouragement'),
  ('John', 6, 35, 'encouragement'),
  ('John', 11, 25, 'encouragement'),
  ('John', 14, 27, 'encouragement'),
  ('John', 15, 13, 'encouragement'),
  
  -- Faith
  ('John', 20, 29, 'faith'),
  ('John', 1, 1, 'faith'),
  ('John', 1, 14, 'faith'),
  ('John', 6, 37, 'faith'),
  ('John', 8, 12, 'faith'),
  ('John', 10, 11, 'faith'),
  ('John', 14, 1, 'faith'),
  ('John', 17, 3, 'faith'),
  ('John', 3, 3, 'faith'),
  ('John', 5, 24, 'faith'),
  
  -- Love
  ('John', 13, 34, 'love'),
  ('John', 15, 9, 'love'),
  ('John', 15, 12, 'love'),
  ('John', 3, 35, 'love'),
  ('John', 14, 21, 'love'),
  ('John', 14, 23, 'love'),
  ('John', 15, 17, 'love'),
  ('John', 17, 26, 'love'),
  ('John', 21, 15, 'love'),
  ('John', 13, 35, 'love'),
  
  -- Hope
  ('John', 1, 5, 'hope'),
  ('John', 3, 17, 'hope'),
  ('John', 4, 14, 'hope'),
  ('John', 5, 28, 'hope'),
  ('John', 6, 40, 'hope'),
  ('John', 10, 28, 'hope'),
  ('John', 11, 26, 'hope'),
  ('John', 14, 2, 'hope'),
  ('John', 14, 3, 'hope'),
  ('John', 14, 19, 'hope'),
  
  -- Peace
  ('John', 14, 27, 'peace'),
  ('John', 16, 33, 'peace'),
  ('John', 20, 19, 'peace'),
  ('John', 20, 21, 'peace'),
  ('John', 20, 26, 'peace'),
  
  -- Truth
  ('John', 8, 32, 'truth'),
  ('John', 14, 6, 'truth'),
  ('John', 16, 13, 'truth'),
  ('John', 17, 17, 'truth'),
  ('John', 18, 37, 'truth'),
  ('John', 4, 23, 'truth'),
  ('John', 4, 24, 'truth'),
  
  -- Wisdom
  ('John', 8, 31, 'wisdom'),
  ('John', 12, 35, 'wisdom'),
  ('John', 12, 36, 'wisdom'),
  ('John', 13, 17, 'wisdom'),
  ('John', 15, 7, 'wisdom'),
  ('John', 15, 10, 'wisdom'),
  ('John', 15, 14, 'wisdom'),
  
  -- Promise
  ('John', 14, 13, 'promise'),
  ('John', 14, 14, 'promise'),
  ('John', 14, 16, 'promise'),
  ('John', 14, 26, 'promise'),
  ('John', 15, 26, 'promise'),
  ('John', 16, 7, 'promise'),
  ('John', 16, 23, 'promise'),
  ('John', 16, 24, 'promise'),
  
  -- Life
  ('John', 1, 4, 'life'),
  ('John', 3, 15, 'life'),
  ('John', 5, 26, 'life'),
  ('John', 6, 33, 'life'),
  ('John', 6, 47, 'life'),
  ('John', 6, 51, 'life'),
  ('John', 6, 68, 'life'),
  ('John', 10, 27, 'life'),
  ('John', 10, 28, 'life'),
  ('John', 11, 25, 'life'),
  ('John', 17, 2, 'life'),
  ('John', 20, 31, 'life'),
  
  -- Prayer
  ('John', 14, 13, 'prayer'),
  ('John', 14, 14, 'prayer'),
  ('John', 15, 16, 'prayer'),
  ('John', 16, 23, 'prayer'),
  ('John', 16, 24, 'prayer'),
  ('John', 16, 26, 'prayer'),
  
  -- Joy
  ('John', 15, 11, 'joy'),
  ('John', 16, 20, 'joy'),
  ('John', 16, 22, 'joy'),
  ('John', 16, 24, 'joy'),
  ('John', 17, 13, 'joy')
ON CONFLICT (book, chapter, verse_number) DO NOTHING;

-- Note: These are just references. The actual verse text will be fetched from Bible API
-- based on the user's preferred translation version. This makes it easy to support
-- new translations without updating the database.

