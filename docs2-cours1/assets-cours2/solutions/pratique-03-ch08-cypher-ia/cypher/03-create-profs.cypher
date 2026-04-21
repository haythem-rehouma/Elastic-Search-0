// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
// 03 - Professeurs + relation ENSEIGNER
MATCH (c1:cours {sigle: '420-AI01-RO'})
MATCH (c2:cours {sigle: '420-AI02-RO'})
MATCH (c3:cours {sigle: '420-AI03-RO'})
MATCH (c4:cours {sigle: '420-AI04-RO'})
MATCH (c5:cours {sigle: '420-AI05-RO'})
CREATE (:professeur {matricule: 101, prenom: 'John',    nom: 'Smith'})    -[:ENSEIGNER]->(c1),
       (:professeur {matricule: 102, prenom: 'Emily',   nom: 'Johnson'})  -[:ENSEIGNER {nbrhrs: 45}]->(c2),
       (:professeur {matricule: 103, prenom: 'Michael', nom: 'Williams'}) -[:ENSEIGNER]->(c3),
       (:professeur {matricule: 104, prenom: 'Sarah',   nom: 'Brown'})    -[:ENSEIGNER]->(c4),
       (:professeur {matricule: 105, prenom: 'Haythem', nom: 'Rehouma'})  -[:ENSEIGNER {nbrhrs: 60}]->(c5);
// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
