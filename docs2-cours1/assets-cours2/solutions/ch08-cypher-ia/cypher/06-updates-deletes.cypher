// 06 - Mises à jour et suppressions (à exécuter manuellement, une par une)

// M1 : Ajouter un bureau à Haythem
MATCH (p:professeur {prenom: 'Haythem', nom: 'Rehouma'})
SET p.bureau = 'A-204' RETURN p;

// M2 : Modifier le nbrhrs de la relation ENSEIGNER
MATCH (p:professeur {prenom: 'Haythem'})-[r:ENSEIGNER]->(c:cours)
SET r.nbrhrs = 75
RETURN p.nom AS prof, c.sigle AS cours, r.nbrhrs AS nouvelles_heures;

// M3 : Ajouter un label
MATCH (p:professeur {prenom: 'Haythem'}) SET p:senior RETURN labels(p);

// D1 : Supprimer la relation ENSEIGNER de Haythem
MATCH (:professeur {prenom:'Haythem'})-[r:ENSEIGNER]->(:cours) DELETE r;

// D2 : Supprimer Haythem (DETACH = avec ses relations restantes)
MATCH (p:professeur {prenom:'Haythem',nom:'Rehouma'}) DETACH DELETE p;

// D3 : Tout vider
MATCH (n) DETACH DELETE n;
