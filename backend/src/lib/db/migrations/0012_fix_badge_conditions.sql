-- Fix impossible and unreasonable badge conditions.
-- Max earnable XP across all 8 quests (perfect scores) is ~1,370.
-- There are only 8 unique quests in the game.

-- xp_2500 "Legendary": lower from 2500 → 1200 (above regular-pass total of 1170,
-- below all-perfect total of 1370 — genuinely hard but reachable)
UPDATE badges SET
  requirement_value = 1200,
  description       = 'Earn 1,200 XP',
  requirement       = 'Earn 1,200 XP total'
WHERE id = 'xp_2500';

-- quest_10_passed "Quest Tracker": lower from 10 → 5 unique quests
UPDATE badges SET
  requirement_value = 5,
  description       = 'Pass 5 different quests',
  requirement       = 'Pass 5 different quests'
WHERE id = 'quest_10_passed';

-- quest_25_passed "Quest Master": lower from 25 → 8 (complete every quest)
UPDATE badges SET
  requirement_value = 8,
  description       = 'Pass all 8 quests',
  requirement       = 'Pass all 8 quests'
WHERE id = 'quest_25_passed';

-- Reading level badges: "Reach" is misleading — level is set once at onboarding,
-- not earned through gameplay. Update requirement text to be accurate.
UPDATE badges SET
  description = 'Placed at Reading Level 2 or above',
  requirement = 'Be placed at reading level 2 or above'
WHERE id = 'level_2';

UPDATE badges SET
  description = 'Placed at Reading Level 3 or above',
  requirement = 'Be placed at reading level 3 or above'
WHERE id = 'level_3';

UPDATE badges SET
  description = 'Placed at Reading Level 4',
  requirement = 'Be placed at reading level 4'
WHERE id = 'level_4';
