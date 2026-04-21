// Methode 2 : effacer noeuds + relations en une commande
// DETACH DELETE retire automatiquement les relations attachees
MATCH (n) DETACH DELETE n;

// Verification
MATCH (n) RETURN count(n) AS noeuds_restants;
