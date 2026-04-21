<a id="top"></a>

# 13 — CRUD pédagogique avec Kibana Dev Tools

> **Type** : Pratique · **Pré-requis** : [10 — Installation ES + Kibana](./10-installation-elasticsearch-kibana.md), [12 — Commandes ES de base](./12-commandes-base-elasticsearch.md)

## Table des matières

- [1. Pourquoi ce chapitre](#1-pourquoi-ce-chapitre)
- [2. Ouvrir Kibana Dev Tools](#2-ouvrir-kibana-dev-tools)
- [3. Premier index : `forum`](#3-premier-index--forum)
- [4. CRUD complet sur `liste_cours`](#4-crud-complet-sur-liste_cours)
  - [4.1 Création de l'index](#41-création-de-lindex)
  - [4.2 Insertion : POST vs PUT vs `_create`](#42-insertion--post-vs-put-vs-_create)
  - [4.3 Lecture](#43-lecture)
  - [4.4 Mise à jour partielle](#44-mise-à-jour-partielle)
  - [4.5 Suppression](#45-suppression)
- [5. Tableau récapitulatif PUT / POST / `_create` / `_update`](#5-tableau-récapitulatif-put--post--_create--_update)
- [6. Erreurs fréquentes du débutant](#6-erreurs-fréquentes-du-débutant)
- [7. Exercices d'auto-évaluation](#7-exercices-dauto-évaluation)

---

## 1. Pourquoi ce chapitre

Le chapitre [12](./12-commandes-base-elasticsearch.md) a montré comment parler à Elasticsearch en `curl` depuis un terminal. Ce chapitre 13 fait **la même chose dans Kibana Dev Tools** avec des datasets jouets (`forum`, `liste_cours`) — bien plus pédagogique pour comprendre :

- la différence entre **POST**, **PUT** et **`_create`** ;
- ce qui se passe quand on **omet** ou **réutilise** un `_id` ;
- le mécanisme de **mise à jour partielle** (`_update`) ;
- la suppression d'un seul document **vs** la suppression de l'index entier.

> **Note ES 7+** : on n'écrit plus `forum/adds/1` (où `adds` était un *type*) mais `forum/_doc/1`. Voir l'encart « Mémo 3 mots » au [chapitre 03](./03-concepts-cles-elasticsearch.md#2-index-document-mapping). Les exemples ci-dessous utilisent la syntaxe moderne.

---

## 2. Ouvrir Kibana Dev Tools

1. Ouvrir [http://localhost:5601](http://localhost:5601)
2. Menu latéral (en haut à gauche) → **Management** → **Dev Tools**
3. La **Console** s'ouvre. À gauche on tape les requêtes, à droite on lit la réponse.

> Astuce : pour exécuter une requête, place le curseur dessus et clique sur la flèche verte (ou `Ctrl+Entrée`).

Équivalence avec `curl` :

```bash
# Dans Kibana Console
PUT college

# Équivalent curl
curl -XPUT "http://localhost:9200/college"
```

---

## 3. Premier index : `forum`

On reproduit le scénario classique « introduction à Elasticsearch » : créer un index `forum`, indexer un document, le relire, le mettre à jour, le supprimer.

```http
PUT forum/_doc/1
{
  "titre": "Introduction a Elasticsearch"
}
```

```http
GET forum/_doc/1
```

```http
GET forum/_doc/10
```

> Le second renvoie `"found": false` car l'id `10` n'existe pas — c'est normal, ce n'est pas une erreur.

Mise à jour (ajouter un champ `motcle`) :

```http
POST forum/_update/1
{
  "doc": {
    "motcle": ["elasticsearch", "haythem", "montreal"]
  }
}
```

Vérifier :

```http
GET forum/_doc/1
```

Insérer un deuxième document :

```http
PUT forum/_doc/2
{
  "titre": "Introduction a Neo4j"
}
```

Lister tous les index du cluster :

```http
GET _cat/indices
```

Recherche plein texte sur `forum` :

```http
POST forum/_refresh
GET forum/_search?q=elasticsearch
```

> `_refresh` force Elasticsearch à rendre les nouveaux documents visibles immédiatement (par défaut le rafraîchissement se fait toutes les 1 s).

Suppression :

```http
DELETE forum/_doc/1
DELETE forum
```

---

## 4. CRUD complet sur `liste_cours`

On passe à un scénario plus parlant : un index qui liste les cours d'un collège.

### 4.1 Création de l'index

```http
DELETE liste_cours
PUT liste_cours
GET liste_cours
```

### 4.2 Insertion : POST vs PUT vs `_create`

#### Cas 1 — `POST` sans id (id auto-généré)

```http
POST liste_cours/_doc
{
  "nom_professeur": "Jean Dupon",
  "sigle_cours": "ABC123"
}
```

> Elasticsearch retourne un `_id` aléatoire (ex : `vFeWcZIBxxxxxx`). Pratique quand on n'a pas d'identifiant métier.

#### Cas 2 — `PUT` avec id imposé

```http
PUT liste_cours/_doc/1
{
  "nom_professeur": "Fred Cote",
  "sigle_cours": "DEF123"
}
```

> Avec `PUT`, l'id (`1`) est **obligatoire**. Si on rejoue la requête avec le même id, le document est **remplacé**.

#### Cas 3 — `POST` avec id imposé (équivalent fonctionnel à PUT)

```http
POST liste_cours/_doc/2
{
  "nom_professeur": "Fred Cote",
  "sigle_cours": "DEF123"
}
```

#### Cas 4 — `PUT` sans id : ERREUR

```http
PUT liste_cours/_doc
{
  "nom_professeur": "Alex Tremblay",
  "sigle_cours": "DER324"
}
```

> Réponse : `405 Method Not Allowed` ou `400 Bad Request`. **`PUT` exige un id**, point.

#### Cas 5 — `_create` : refuse d'écraser un id existant

```http
PUT liste_cours/_create/1
{
  "nom_professeur": "Sam Cote",
  "sigle_cours": "DEF123"
}
```

> Si l'id `1` existe déjà → `409 Conflict` (`version_conflict_engine_exception`). Très utile pour garantir une **insertion unique** sans risque d'écrasement.

### 4.3 Lecture

```http
GET liste_cours/_doc/1
GET liste_cours/_doc/2

GET _cat/indices
GET liste_cours
GET liste_cours/_search
```

### 4.4 Mise à jour partielle

Modifier les champs existants :

```http
POST liste_cours/_update/1
{
  "doc": {
    "nom_professeur": "Albert Beau-séjour",
    "sigle_cours": "ABC324"
  }
}

GET liste_cours/_doc/1
```

Ajouter un **nouveau** champ sans toucher aux autres :

```http
POST liste_cours/_update/1
{
  "doc": {
    "salle_cours": "salle1"
  }
}

GET liste_cours/_doc/1
```

> Différence clé : `PUT liste_cours/_doc/1 { ... }` **remplace** tout le document ; `POST liste_cours/_update/1 { "doc": { ... } }` **fusionne** seulement les champs fournis.

### 4.5 Suppression

```http
DELETE liste_cours/_doc/1
GET liste_cours/_doc/1

DELETE liste_cours
```

---

## 5. Tableau récapitulatif PUT / POST / `_create` / `_update`

| Verbe + chemin                       | id obligatoire ? | Si l'id existe déjà ? | Si l'id n'existe pas ? | Cas d'usage typique                          |
| ------------------------------------ | :--------------: | --------------------- | ---------------------- | -------------------------------------------- |
| `POST liste_cours/_doc`              | non (auto-géré)  | —                     | crée                   | Insertion sans contrainte d'id              |
| `POST liste_cours/_doc/1`            | oui              | **remplace**          | crée                   | Insertion / remplacement « upsert simple »   |
| `PUT liste_cours/_doc/1`             | oui              | **remplace**          | crée                   | Identique au POST avec id (style REST)       |
| `PUT liste_cours/_doc` (sans id)     | oui              | **erreur 4xx**        | erreur                 | À éviter                                     |
| `PUT liste_cours/_create/1`          | oui              | **conflit 409**       | crée                   | Garantir une insertion unique                |
| `POST liste_cours/_update/1 {doc:…}` | oui              | fusionne              | erreur 404             | Mise à jour partielle (ajout / modification) |
| `DELETE liste_cours/_doc/1`          | oui              | supprime              | 404                    | Supprimer un document                        |
| `DELETE liste_cours`                 | —                | supprime tout l'index | 404                    | Vider et recommencer                         |

---

## 6. Erreurs fréquentes du débutant

| Symptôme                                                    | Cause                                                  | Correctif                                                   |
| ----------------------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------- |
| `405 Method Not Allowed` sur `PUT liste_cours/_doc`         | Pas d'id avec PUT                                      | Ajouter un id : `PUT liste_cours/_doc/3`                    |
| `409 version_conflict_engine_exception`                     | `_create` sur id existant                              | Soit changer d'id, soit utiliser `PUT` / `POST _doc/<id>`   |
| `404 not_found` sur `_update`                               | Le document n'existe pas                               | Le créer d'abord ou utiliser `_update` avec `doc_as_upsert` |
| Le champ ajouté n'apparaît pas dans `_search`               | Refresh non fait                                       | `POST liste_cours/_refresh` avant la recherche              |
| Recherche `q=POLITICS` qui ne renvoie rien sur `category`   | Champ `text` analysé en minuscules                     | Chercher `q=politics` ou utiliser `category.keyword`        |
| Doc remplacé entièrement alors qu'on voulait juste modifier | `PUT _doc/<id>` au lieu de `POST _update/<id>`         | Toujours utiliser `_update` pour modifier partiellement     |

---

## 7. Exercices d'auto-évaluation

> Les corrigés sont dans les requêtes du chapitre. Essayez **d'abord** de les écrire sans regarder.

1. Créer un index `bibliotheque` et y insérer (avec `PUT`) le livre d'id `42` : `{ "titre": "1984", "auteur": "Orwell" }`.
2. Réinsérer le **même** id avec `_create` — quelle est la réponse ?
3. Ajouter un champ `annee: 1949` au document `42` **sans** toucher au titre et à l'auteur.
4. Insérer 3 livres supplémentaires sans préciser d'id (`POST _doc`). Comment retrouvez-vous les ids générés ?
5. Lister tous les documents de l'index.
6. Supprimer uniquement le livre `42`, vérifier qu'il n'existe plus, puis supprimer l'index entier.

<details>
<summary>Solution résumée</summary>

```http
PUT bibliotheque/_doc/42
{ "titre": "1984", "auteur": "Orwell" }

PUT bibliotheque/_create/42
{ "titre": "1984", "auteur": "Orwell" }
# 409 Conflict

POST bibliotheque/_update/42
{ "doc": { "annee": 1949 } }

POST bibliotheque/_doc
{ "titre": "Le Petit Prince", "auteur": "Saint-Exupéry" }
POST bibliotheque/_doc
{ "titre": "Candide", "auteur": "Voltaire" }
POST bibliotheque/_doc
{ "titre": "Germinal", "auteur": "Zola" }

POST bibliotheque/_refresh
GET bibliotheque/_search

DELETE bibliotheque/_doc/42
GET bibliotheque/_doc/42
DELETE bibliotheque
```

</details>

> Une fois ces réflexes acquis, passez au chapitre [14 — Bulk import](./14-import-bulk-dataset.md) pour charger un vrai dataset (~200 000 articles de presse), puis aux requêtes de recherche aux chapitres [15](./15-requetes-elasticsearch-intermediaire.md) et [16](./16-requetes-avancees-kql-esql-dsl.md).

<p align="right"><a href="#top">Retour en haut</a></p>
