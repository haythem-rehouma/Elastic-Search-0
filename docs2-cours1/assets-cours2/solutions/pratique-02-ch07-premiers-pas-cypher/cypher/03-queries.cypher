// Etape 3 : 8 requetes types pour decouvrir Cypher

// Q1 : tous les noeuds Personne
MATCH (p:Personne) RETURN p;

// Q2 : noms et ages tries par age decroissant
MATCH (p:Personne) RETURN p.nom AS nom, p.age AS age ORDER BY age DESC;

// Q3 : personnes habitant Montreal
MATCH (p:Personne)-[:HABITE_A]->(v:Ville {nom: 'Montreal'})
RETURN p.nom AS habitant_montreal;

// Q4 : qui Alice connait ?
MATCH (alice:Personne {nom: 'Alice'})-[:CONNAIT]->(ami:Personne)
RETURN ami.nom AS connaissances_alice;

// Q5 : amis d'amis (chemin de longueur 2)
MATCH (alice:Personne {nom: 'Alice'})-[:CONNAIT*2]->(ami_d_ami:Personne)
WHERE ami_d_ami.nom <> 'Alice'
RETURN DISTINCT ami_d_ami.nom AS amis_d_amis;

// Q6 : compter le nombre d'habitants par ville
MATCH (p:Personne)-[:HABITE_A]->(v:Ville)
RETURN v.nom AS ville, count(p) AS nb_habitants
ORDER BY nb_habitants DESC;

// Q7 : moyenne d'age
MATCH (p:Personne)
RETURN avg(p.age) AS age_moyen;

// Q8 : depuis quand Alice habite a Montreal ?
MATCH (p:Personne {nom: 'Alice'})-[r:HABITE_A]->(v:Ville)
RETURN p.nom AS personne, v.nom AS ville, r.depuis AS depuis_annee;
