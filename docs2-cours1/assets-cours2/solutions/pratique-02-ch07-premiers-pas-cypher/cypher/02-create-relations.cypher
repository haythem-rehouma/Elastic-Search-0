// Etape 2 : creer des relations
// Chaque personne HABITE_A une ville et CONNAIT d'autres personnes

MATCH (p:Personne {nom: 'Alice'}), (v:Ville {nom: 'Montreal'})
CREATE (p)-[:HABITE_A {depuis: 2018}]->(v);

MATCH (p:Personne {nom: 'Bob'}), (v:Ville {nom: 'Quebec'})
CREATE (p)-[:HABITE_A {depuis: 2020}]->(v);

MATCH (p:Personne {nom: 'Charlie'}), (v:Ville {nom: 'Montreal'})
CREATE (p)-[:HABITE_A {depuis: 2015}]->(v);

MATCH (p:Personne {nom: 'Diana'}), (v:Ville {nom: 'Toronto'})
CREATE (p)-[:HABITE_A {depuis: 2022}]->(v);

MATCH (a:Personne {nom: 'Alice'}), (b:Personne {nom: 'Bob'})
CREATE (a)-[:CONNAIT {depuis: 2019}]->(b);

MATCH (a:Personne {nom: 'Alice'}), (c:Personne {nom: 'Charlie'})
CREATE (a)-[:CONNAIT {depuis: 2017}]->(c);

MATCH (b:Personne {nom: 'Bob'}), (d:Personne {nom: 'Diana'})
CREATE (b)-[:CONNAIT {depuis: 2021}]->(d);
