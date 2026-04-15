-- Add level_1 badge and rename level_2 to match reading level names
INSERT INTO badges (id, name, description, category, icon, requirement, requirement_value, requirement_key)
VALUES ('level_1', 'Non Reader', 'Placed at Reading Level 1', 'level', '🌱', 'Be placed at reading level 1 or above', 1, NULL)
ON CONFLICT (id) DO NOTHING;

UPDATE badges SET name = 'Emerging Reader' WHERE id = 'level_2';
