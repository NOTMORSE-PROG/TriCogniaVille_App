-- Shift existing "Fluent" students (old level 3) to level 4 (new Fluent).
-- Level 3 slot is now "Developing" (new tier between Emerging and Fluent).
UPDATE students SET reading_level = 4 WHERE reading_level = 3;
