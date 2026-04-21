// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
// 04 - Relations PREALABLE et COLLEGUES (idempotentes via MERGE)

MATCH (a:cours {sigle: '420-AI05-RO'}), (b:cours {sigle: '420-AI01-RO'})
MERGE (a)-[:PREALABLE]->(b);

MATCH (a:cours {sigle: '420-AI06-RO'}), (b:cours {sigle: '420-AI02-RO'})
MERGE (a)-[:PREALABLE]->(b);

MATCH (a:cours {sigle: '420-AI02-RO'}), (b:cours {sigle: '420-AI03-RO'})
MERGE (a)-[:PREALABLE]->(b);

MATCH (a:professeur {prenom: 'Haythem', nom: 'Rehouma'}),
      (b:professeur {prenom: 'John',    nom: 'Smith'})
MERGE (a)-[:COLLEGUES {programme: 'Intelligence Artificielle'}]->(b);

MATCH (a:professeur {prenom: 'Emily', nom: 'Johnson'}),
      (b:professeur {prenom: 'Sarah', nom: 'Brown'})
MERGE (a)-[:COLLEGUES {programme: 'Intelligence Artificielle'}]->(b);

MATCH (a:professeur {prenom: 'Michael', nom: 'Williams'}),
      (b:professeur {prenom: 'Sarah',   nom: 'Brown'})
MERGE (a)-[:COLLEGUES {programme: 'Intelligence Artificielle'}]->(b);
// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
