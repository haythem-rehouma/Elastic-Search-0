"""
Pipeline Bulk import en Python (alternative à run-all.sh / run-all.ps1).
Marche identiquement sur Windows, macOS, Linux.

Pré-requis : pip install elasticsearch==8.13.0 tqdm==4.66.4
"""
import json
import os
import sys
from pathlib import Path

from elasticsearch import Elasticsearch, helpers
from tqdm import tqdm

ES_URL  = os.environ.get("ES", "http://localhost:9200")
INDEX   = "news"
ROOT    = Path(__file__).resolve().parent.parent
RAW     = ROOT / "data" / "raw.jsonl"
SRC_DEFAULT = ROOT.parent.parent / "News_Category_Dataset_v2.json"
MAPPING = json.loads((ROOT / "mappings" / "news.mapping.json").read_text(encoding="utf-8"))
POST    = json.loads((ROOT / "mappings" / "news.post-import.json").read_text(encoding="utf-8"))


def step(msg):
    print(f"\n==== {msg} ====")


def prepare():
    step("1. Préparation du dataset")
    if not RAW.exists():
        if not SRC_DEFAULT.exists():
            sys.exit(f"ERREUR : ni {RAW} ni {SRC_DEFAULT} ne sont présents.")
        RAW.parent.mkdir(parents=True, exist_ok=True)
        RAW.write_bytes(SRC_DEFAULT.read_bytes())
    n = sum(1 for _ in RAW.open(encoding="utf-8"))
    print(f"   Lignes : {n} (attendu : 200 853)")
    return n


def create_index(es):
    step("2. Création de l'index")
    if es.indices.exists(index=INDEX):
        es.indices.delete(index=INDEX)
    es.indices.create(index=INDEX, body=MAPPING)
    print(f"   Index '{INDEX}' créé.")


def gen_actions():
    with RAW.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            yield {"_index": INDEX, "_source": json.loads(line)}


def bulk_import(es, total):
    step("3-4. Indexation _bulk (chunks de 2000)")
    success = errors = 0
    pbar = tqdm(total=total, unit=" docs")
    for ok, item in helpers.streaming_bulk(
        es, gen_actions(),
        chunk_size=2000,
        request_timeout=120,
        raise_on_error=False,
        raise_on_exception=False,
    ):
        if ok:
            success += 1
        else:
            errors += 1
        pbar.update(1)
    pbar.close()
    print(f"\n   OK : {success}    Erreurs : {errors}")
    return success, errors


def finalize(es):
    step("5. Finalisation")
    es.indices.put_settings(index=INDEX, body=POST)
    es.indices.refresh(index=INDEX)
    count = es.count(index=INDEX)["count"]
    print(f"   Documents indexés : {count}  (attendu 200 853)")
    return count


def main():
    es = Elasticsearch(ES_URL, request_timeout=120)
    if not es.ping():
        sys.exit(f"ES injoignable sur {ES_URL}. Lancez : docker compose up -d")

    total = prepare()
    create_index(es)
    bulk_import(es, total)
    finalize(es)
    print("\n===== Pipeline terminé =====")
    print("Kibana : http://localhost:5601")


if __name__ == "__main__":
    main()
