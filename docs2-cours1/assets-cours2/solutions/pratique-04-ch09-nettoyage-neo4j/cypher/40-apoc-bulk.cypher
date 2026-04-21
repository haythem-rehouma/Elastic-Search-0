// Methode 4 (BIG DATA) : nettoyage en lots via APOC
// A utiliser quand DETACH DELETE plante en OutOfMemory sur des millions de noeuds

CALL apoc.periodic.iterate(
  "MATCH (n) RETURN n",
  "DETACH DELETE n",
  {batchSize: 10000, parallel: false}
);

// Verification
MATCH (n) RETURN count(n) AS noeuds_restants;
