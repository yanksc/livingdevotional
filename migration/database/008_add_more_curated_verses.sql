-- Helper script to add more curated verses as you seed more chapters
-- Run this AFTER you've seeded additional chapters of John

-- Example: If you've seeded chapters 4-6, add these verses
-- Uncomment and run after seeding those chapters

/*
-- From Chapter 4
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 4, 14, 'hope'),
  ('John', 4, 23, 'truth'),
  ('John', 4, 24, 'truth')
ON CONFLICT DO NOTHING;

-- From Chapter 5
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 5, 24, 'faith'),
  ('John', 5, 26, 'life'),
  ('John', 5, 28, 'hope')
ON CONFLICT DO NOTHING;

-- From Chapter 6
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 6, 33, 'life'),
  ('John', 6, 35, 'encouragement'),
  ('John', 6, 37, 'faith'),
  ('John', 6, 40, 'hope'),
  ('John', 6, 47, 'life'),
  ('John', 6, 51, 'life'),
  ('John', 6, 68, 'life')
ON CONFLICT DO NOTHING;

-- From Chapter 8
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 8, 12, 'faith'),
  ('John', 8, 31, 'wisdom'),
  ('John', 8, 32, 'truth')
ON CONFLICT DO NOTHING;

-- From Chapter 10
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 10, 10, 'encouragement'),
  ('John', 10, 11, 'faith'),
  ('John', 10, 27, 'life'),
  ('John', 10, 28, 'hope')
ON CONFLICT DO NOTHING;

-- From Chapter 11
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 11, 25, 'encouragement'),
  ('John', 11, 26, 'hope')
ON CONFLICT DO NOTHING;

-- From Chapter 13
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 13, 17, 'wisdom'),
  ('John', 13, 34, 'love'),
  ('John', 13, 35, 'love')
ON CONFLICT DO NOTHING;

-- From Chapter 14
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 14, 1, 'faith'),
  ('John', 14, 2, 'hope'),
  ('John', 14, 3, 'hope'),
  ('John', 14, 6, 'encouragement'),
  ('John', 14, 13, 'promise'),
  ('John', 14, 14, 'prayer'),
  ('John', 14, 16, 'promise'),
  ('John', 14, 19, 'hope'),
  ('John', 14, 21, 'love'),
  ('John', 14, 23, 'love'),
  ('John', 14, 26, 'promise'),
  ('John', 14, 27, 'peace')
ON CONFLICT DO NOTHING;

-- From Chapter 15
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 15, 5, 'encouragement'),
  ('John', 15, 7, 'wisdom'),
  ('John', 15, 9, 'love'),
  ('John', 15, 10, 'wisdom'),
  ('John', 15, 11, 'joy'),
  ('John', 15, 12, 'love'),
  ('John', 15, 13, 'encouragement'),
  ('John', 15, 14, 'wisdom'),
  ('John', 15, 16, 'prayer'),
  ('John', 15, 17, 'love'),
  ('John', 15, 26, 'promise')
ON CONFLICT DO NOTHING;

-- From Chapter 16
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 16, 7, 'promise'),
  ('John', 16, 13, 'truth'),
  ('John', 16, 20, 'joy'),
  ('John', 16, 22, 'joy'),
  ('John', 16, 23, 'prayer'),
  ('John', 16, 24, 'joy'),
  ('John', 16, 26, 'prayer'),
  ('John', 16, 33, 'peace')
ON CONFLICT DO NOTHING;

-- From Chapter 17
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 17, 2, 'life'),
  ('John', 17, 3, 'faith'),
  ('John', 17, 13, 'joy'),
  ('John', 17, 17, 'truth'),
  ('John', 17, 26, 'love')
ON CONFLICT DO NOTHING;

-- From Chapter 18
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 18, 37, 'truth')
ON CONFLICT DO NOTHING;

-- From Chapter 20
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 20, 19, 'peace'),
  ('John', 20, 21, 'peace'),
  ('John', 20, 26, 'peace'),
  ('John', 20, 29, 'faith'),
  ('John', 20, 31, 'life')
ON CONFLICT DO NOTHING;

-- From Chapter 21
INSERT INTO curated_verses (book, chapter, verse_number, category) VALUES
  ('John', 21, 15, 'love')
ON CONFLICT DO NOTHING;
*/

-- Quick check: How many curated verses do we have?
SELECT category, COUNT(*) as count 
FROM curated_verses 
GROUP BY category 
ORDER BY count DESC;

-- Total count
SELECT COUNT(*) as total_curated_verses FROM curated_verses;

