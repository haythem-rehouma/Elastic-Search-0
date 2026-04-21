// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
// Methode 3 : effacer aussi les contraintes et les index
// IMPORTANT : DETACH DELETE n'enleve PAS les contraintes/indexes !

SHOW CONSTRAINTS;
SHOW INDEXES;

// Lister puis dropper individuellement
DROP CONSTRAINT user_nom_unique IF EXISTS;
DROP INDEX user_nom_index IF EXISTS;

// Verification
SHOW CONSTRAINTS;
SHOW INDEXES;
// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
