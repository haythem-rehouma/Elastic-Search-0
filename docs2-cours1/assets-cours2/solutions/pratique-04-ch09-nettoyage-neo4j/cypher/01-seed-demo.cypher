// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
// Donnees factices pour pouvoir tester chaque methode de nettoyage
CREATE (a:User {nom: 'Alice'})
CREATE (b:User {nom: 'Bob'})
CREATE (c:User {nom: 'Charlie'})
CREATE (a)-[:FOLLOW]->(b)
CREATE (b)-[:FOLLOW]->(c)
CREATE (c)-[:FOLLOW]->(a);

CREATE CONSTRAINT user_nom_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.nom IS UNIQUE;

CREATE INDEX user_nom_index IF NOT EXISTS
FOR (u:User) ON (u.nom);
// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
