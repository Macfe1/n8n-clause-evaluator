#!/usr/bin/env bash

Q="Sociedades de capital"

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

# Buscar en Qdrant con filtro - no esta aplicado en n8n
curl -s -X POST http://localhost:6333/collections/clauses_es_v1/points/search \
    -H "Content-Type: application/json" \
    -d '{
    "vector": '"$QEMB"',
    "limit": 3,
    "with_payload": true,
    "filter": { "must": [{ "key": "norma", "match": { "value": "Ley de Sociedades de Capital" } }] }
    }' | jq .

echo "-----------------------------------"

#Traer algunos campos del paylod
curl -s -X POST http://localhost:6333/collections/clauses_es_v1/points/search \
    -H "Content-Type: application/json" \
    -d '{
    "vector": '"$QEMB"',
    "limit": 2,
    "with_payload": { "include": ["doc_id","norma","articulo","boe_url"] }
    }' | jq .
