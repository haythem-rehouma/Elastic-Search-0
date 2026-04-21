<a id="top"></a>

# Solutions — Chapitre 13 : CRUD pédagogique dans Kibana Dev Tools

> **Lien chapitre source** : [`13-crud-pedagogique-kibana.md`](../../13-crud-pedagogique-kibana.md)
> **Pré-requis** : [Setup A à Z](./00-setup-complet-a-z.md) — Kibana ouvert sur http://localhost:5601 → **Dev Tools → Console**.

## Table des matières

- [0. Ouvrir Kibana Dev Tools](#0-ouvrir-kibana-dev-tools)
- [1. Session pédagogique complète sur `liste_cours`](#1-session-pédagogique-complète-sur-liste_cours)
- [2. PUT vs POST vs `_create` — démonstrations](#2-put-vs-post-vs-_create--démonstrations)
- [3. Update partiel vs remplacement complet](#3-update-partiel-vs-remplacement-complet)
- [4. Suppression document vs index](#4-suppression-document-vs-index)
- [5. Solution complète des exercices d'auto-évaluation](#5-solution-complète-des-exercices-dauto-évaluation)
- [6. Vérifications finales](#6-vérifications-finales)

---

## 0. Ouvrir Kibana Dev Tools

1. Ouvrez http://localhost:5601
2. Menu (☰ en haut à gauche) → **Management → Dev Tools**
3. Vous arrivez sur l'onglet **Console**.

> Toutes les requêtes ci-dessous se collent dans cette console. `Ctrl + Entrée` pour exécuter celle où est le curseur, ou cliquez le triangle ▶ à droite.

---

## 1. Session pédagogique complète sur `liste_cours`

À copier-coller en bloc dans la Console (les commandes s'exécutent **une à une** quand vous mettez le curseur dessus) :

```
# ============================================================
# 1. PRÉPARATION - INDEX VIERGE
# ============================================================
DELETE liste_cours

PUT liste_cours

GET liste_cours


# ============================================================
# 2. INSERTION - POST AUTO-ID
# ============================================================
# POST sans id → Elasticsearch génère un id aléatoire (~20 caractères)
POST liste_cours/_doc
{
  "nom_professeur": "Jean Dupon",
  "sigle_cours":    "ABC123"
}


# ============================================================
# 3. INSERTION - PUT AVEC ID CHOISI
# ============================================================
# Avec PUT, l'id est OBLIGATOIRE
PUT liste_cours/_doc/1
{
  "nom_professeur": "Robert",
  "sigle_cours":    "ABC456"
}


# ============================================================
# 4. INSERTION - POST AVEC ID CHOISI (les deux marchent)
# ============================================================
POST liste_cours/_doc/2
{
  "nom_professeur": "Fred Cote",
  "sigle_cours":    "DEF123"
}


# ============================================================
# 5. ERREURS À PROVOQUER VOLONTAIREMENT
# ============================================================
# PUT sans id → erreur (PUT exige un id)
PUT liste_cours/_doc
{
  "nom_professeur": "Alex Tremblay",
  "sigle_cours":    "DER324"
}
# Réponse attendue : 405 Method Not Allowed


# ============================================================
# 6. _create - REFUSER L'ÉCRASEMENT
# ============================================================
# L'id 1 existe déjà → _create renvoie une erreur 409
PUT liste_cours/_create/1
{
  "nom_professeur": "Sam Cote",
  "sigle_cours":    "ZZZ999"
}
# Réponse attendue : 409 Conflict (version_conflict_engine_exception)

# Avec un id qui n'existe pas → fonctionne
PUT liste_cours/_create/3
{
  "nom_professeur": "Albert Beau-séjour",
  "sigle_cours":    "ABC324"
}


# ============================================================
# 7. LECTURE
# ============================================================
GET liste_cours/_doc/1
GET liste_cours/_doc/2
GET liste_cours/_doc/3

# Lister tous les indices
GET _cat/indices?v

# Lister tous les documents
GET liste_cours/_search


# ============================================================
# 8. UPDATE PARTIEL (modifier 1 champ sans toucher aux autres)
# ============================================================
GET liste_cours/_doc/1
# {"nom_professeur": "Robert", "sigle_cours": "ABC456"}

POST liste_cours/_update/1
{
  "doc": {
    "nom_professeur": "Robert Tremblay"
  }
}

GET liste_cours/_doc/1
# {"nom_professeur": "Robert Tremblay", "sigle_cours": "ABC456"} ← sigle préservé


# ============================================================
# 9. UPDATE - AJOUTER UNE NOUVELLE CLÉ
# ============================================================
POST liste_cours/_update/1
{
  "doc": {
    "salle_cours": "salle1"
  }
}

GET liste_cours/_doc/1
# {"nom_professeur": "Robert Tremblay", "sigle_cours": "ABC456", "salle_cours": "salle1"}


# ============================================================
# 10. PIÈGE - PUT vs _update sur un doc existant
# ============================================================
# PUT _doc/<id> ÉCRASE TOUT le document (perte des champs absents)
PUT liste_cours/_doc/1
{
  "nom_professeur": "Robert Tremblay"
}

GET liste_cours/_doc/1
# Le champ "sigle_cours" et "salle_cours" ONT DISPARU !


# ============================================================
# 11. SUPPRESSION
# ============================================================
DELETE liste_cours/_doc/1
GET liste_cours/_doc/1
# "found": false


# ============================================================
# 12. SUPPRESSION DE L'INDEX ENTIER
# ============================================================
DELETE liste_cours
GET liste_cours
# 404 index_not_found_exception
```

---

## 2. PUT vs POST vs `_create` — démonstrations

| Verbe                      | Comportement attendu                    | Si l'id n'existe pas | Si l'id existe                |
| -------------------------- | --------------------------------------- | -------------------- | ----------------------------- |
| `POST <idx>/_doc`          | Crée avec id auto-généré                | Crée                 | (n'utilise pas d'id existant) |
| `POST <idx>/_doc/<id>`     | Crée OU met à jour                      | Crée                 | **Écrase**                    |
| `PUT <idx>/_doc/<id>`      | Crée OU met à jour                      | Crée                 | **Écrase**                    |
| `PUT <idx>/_doc` (sans id) | **Erreur 405**                          | —                    | —                             |
| `PUT <idx>/_create/<id>`   | **Crée seulement** (échoue si existe)   | Crée                 | **409 Conflict**              |

> **Règle d'or** : pour la mise à jour de champs spécifiques, utilisez `POST <idx>/_update/<id>` (le verbe d'update **partiel** sans tout perdre).

---

## 3. Update partiel vs remplacement complet

```
# Préparation
DELETE demo
POST demo/_doc/1
{ "a": 1, "b": 2, "c": 3 }


# Cas 1 : UPDATE partiel (préserve les autres champs)
POST demo/_update/1
{ "doc": { "a": 100 } }

GET demo/_doc/1
# { "a": 100, "b": 2, "c": 3 }


# Cas 2 : PUT _doc (REMPLACEMENT TOTAL)
PUT demo/_doc/1
{ "a": 999 }

GET demo/_doc/1
# { "a": 999 }   ← b et c ont disparu !


# Cas 3 : UPDATE par script (Painless)
POST demo/_update/1
{
  "script": {
    "source": "ctx._source.a += params.delta",
    "lang":   "painless",
    "params": { "delta": 5 }
  }
}
GET demo/_doc/1
# { "a": 1004 }  (999 + 5)


DELETE demo
```

---

## 4. Suppression document vs index

| Action                | Commande                       | Effet                                          |
| --------------------- | ------------------------------ | ---------------------------------------------- |
| Supprimer 1 document  | `DELETE liste_cours/_doc/1`    | Le doc id=1 disparaît, l'index reste           |
| Vider tous les docs   | `POST liste_cours/_delete_by_query { "query": {"match_all": {}} }` | Tous les docs effacés, l'index reste (mapping conservé) |
| Supprimer l'index     | `DELETE liste_cours`           | L'index entier disparaît (docs + mapping)      |
| Supprimer plusieurs   | `DELETE liste_cours,demo`      | Plusieurs index d'un coup                      |
| Wildcard (DANGER)     | `DELETE liste_*`               | À éviter sans `action.destructive_requires_name` activé |

---

## 5. Solution complète des exercices d'auto-évaluation

> Énoncé original (chap. 13 § 7) :
> 1. Créer un index `bibliotheque` et y insérer (avec `PUT`) le livre d'id `42` : `{ "titre": "1984", "auteur": "Orwell" }`.
> 2. Réinsérer le **même** id avec `_create` — quelle est la réponse ?
> 3. Ajouter un champ `annee: 1949` au document `42` **sans** toucher au titre et à l'auteur.
> 4. Insérer 3 livres supplémentaires sans préciser d'id (`POST _doc`). Comment retrouvez-vous les ids générés ?
> 5. Lister tous les documents de l'index.
> 6. Supprimer uniquement le livre `42`, vérifier qu'il n'existe plus, puis supprimer l'index entier.

```
# --- Q1 ---
DELETE bibliotheque
PUT bibliotheque

PUT bibliotheque/_doc/42
{ "titre": "1984", "auteur": "Orwell" }
# Réponse : { "result": "created", "_id": "42", ... }


# --- Q2 ---
PUT bibliotheque/_create/42
{ "titre": "1984", "auteur": "Orwell" }
# Réponse : 409 Conflict / version_conflict_engine_exception
#  → _create REFUSE d'écraser un id existant


# --- Q3 ---
POST bibliotheque/_update/42
{ "doc": { "annee": 1949 } }

GET bibliotheque/_doc/42
# Réponse : { "_source": { "titre": "1984", "auteur": "Orwell", "annee": 1949 } }
#  → titre et auteur SONT préservés


# --- Q4 ---
POST bibliotheque/_doc
{ "titre": "Le Petit Prince", "auteur": "Saint-Exupéry" }
# La réponse contient le _id auto-généré (chaîne de ~20 caractères)
# Exemple : "_id": "kQ8aZIcBnP7yvN_3uXYz"

POST bibliotheque/_doc
{ "titre": "Candide", "auteur": "Voltaire" }

POST bibliotheque/_doc
{ "titre": "Germinal", "auteur": "Zola" }


# --- Q5 ---
POST bibliotheque/_refresh

GET bibliotheque/_search
# Réponse : 4 hits — id "42" (Orwell) + 3 ids auto-générés


# Variante : voir uniquement les ids et titres
GET bibliotheque/_search
{
  "_source": ["titre","auteur"],
  "size": 100
}


# --- Q6 ---
DELETE bibliotheque/_doc/42
# Réponse : { "result": "deleted", "_id": "42", ... }

GET bibliotheque/_doc/42
# Réponse : { "found": false }

DELETE bibliotheque
# Réponse : { "acknowledged": true }

GET bibliotheque
# Réponse : 404 index_not_found_exception
```

---

## 6. Vérifications finales

À la fin des exercices, plus rien ne doit subsister :

```
GET _cat/indices?v
```

→ ni `liste_cours`, ni `demo`, ni `bibliotheque` (sauf indices système commençant par `.`).

### Quiz éclair (corrigé)

| Question                                                          | Réponse                                                |
| ----------------------------------------------------------------- | ------------------------------------------------------ |
| Comment créer un doc avec un id que je choisis ?                  | `PUT <idx>/_doc/<id>` ou `POST <idx>/_doc/<id>`        |
| Comment créer un doc avec un id auto-généré ?                     | `POST <idx>/_doc` (sans id)                            |
| Comment empêcher l'écrasement d'un doc existant ?                 | `PUT <idx>/_create/<id>` → renvoie 409 si existe       |
| Comment ajouter un champ sans détruire les autres ?               | `POST <idx>/_update/<id> { "doc": { ... } }`           |
| Comment supprimer un seul doc sans toucher au mapping de l'index ?| `DELETE <idx>/_doc/<id>`                               |
| Quel est le piège avec `PUT <idx>/_doc/<id>` sur un doc existant ?| **Remplacement complet** (perte des champs absents)    |
| Pourquoi mes nouveaux docs n'apparaissent pas dans `_search` ?    | Refresh non fait (cycle 1s par défaut) → `_refresh`    |

→ Si vous savez répondre à toutes ces questions, vous êtes prêt pour le [chapitre 14 : Bulk import](../../14-import-bulk-dataset.md).

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
