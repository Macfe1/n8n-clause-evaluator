#!/usr/bin/env bash
# test_1.sh

Q="Nacionalidad española"

# Obtener embedding de la query
QEMB=$(
    curl -s http://localhost:11434/api/embeddings \
    -H "Content-Type: application/json" \
    -d '{
    "model": "nomic-embed-text",
    "prompt": "'"$Q"'"
    }' \
    | jq -c '.embedding'
)

# Buscar en Qdrant
curl -s -X POST http://localhost:6333/collections/clauses_es_v1/points/search \
    -H "Content-Type: application/json" \
    -d '{"vector": '"$QEMB"', "limit": 2, "with_payload": true}' | jq .
