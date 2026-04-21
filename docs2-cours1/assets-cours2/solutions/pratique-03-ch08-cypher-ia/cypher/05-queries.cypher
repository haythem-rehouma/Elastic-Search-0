// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite.
// 05 - Requêtes d'exploration (à exécuter une par une dans Neo4j Browser)

// Q1 : Tous les profs
MATCH (p:professeur) RETURN p;

// Q2 : Prénoms / noms triés
MATCH (p:professeur) RETURN p.prenom AS prenom, p.nom AS nom ORDER BY nom;

// Q3 : Trouver Haythem Rehouma
MATCH (p:professeur) WHERE p.prenom = 'Haythem' AND p.nom = 'Rehouma' RETURN p;

// Q4 : Profs et leurs cours (avec heures si dispo)
MATCH (p:professeur)-[r:ENSEIGNER]->(c:cours)
RETURN p.prenom + ' ' + p.nom AS professeur,
       c.sigle              AS cours,
       coalesce(r.nbrhrs, 'non précisé') AS heures
ORDER BY professeur;

// Q5 : Relations entre collègues
MATCH (p1:professeur)-[r:COLLEGUES]->(p2:professeur)
RETURN p1.nom AS de, p2.nom AS vers, r.programme AS programme;

// Q6 : Tous les prérequis directs
MATCH (a:cours)-[:PREALABLE]->(b:cours)
RETURN a.sigle AS prerequis, b.sigle AS pour_le_cours
ORDER BY pour_le_cours;

// Q7 : Chaîne complète (transitive)
MATCH path = (a:cours)-[:PREALABLE*1..5]->(b:cours)
RETURN [n IN nodes(path) | n.sigle] AS chaine;

// Q8 : UNWIND des diplômes acceptés pour AI01
MATCH (n:cours) WHERE n.sigle = "420-AI01-RO"
UNWIND split(n.diplome, "/") AS element
RETURN element ORDER BY element ASC;

// Q9 : Préfixe et collège (substring + WITH)
MATCH (n:cours)
WITH substring(n.sigle, 0, 3) AS prefixe,
     substring(n.sigle, 8, 2) AS college
RETURN DISTINCT prefixe, college;

// Vérifs chiffrées attendues : 6 cours, 5 profs, 5 ENSEIGNER, 3 PREALABLE, 3 COLLEGUES
MATCH (n)         RETURN labels(n) AS label, count(n) AS nb;
MATCH ()-[r]->()  RETURN type(r)  AS rel, count(r) AS nb;
// Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG]
