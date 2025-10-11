#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-corpus/corpus_txt/mini_corpus.jsonl}"
COLLECTION="${2:-clauses_es_v1}"
QDRANT_URL="${3:-http://localhost:6333}"
EMBED_URL="${4:-http://localhost:11434/api/embeddings}"
EMBED_MODEL="${5:-nomic-embed-text}"

i=1
while IFS= read -r line; do
  # Extraer campos del JSON de la línea
  doc_id=$(jq -r '.doc_id' <<<"$line")
  norma=$(jq -r '.norma' <<<"$line")
  articulo=$(jq -r '.articulo' <<<"$line")
  boe_url=$(jq -r '.boe_url' <<<"$line")
  jurisdiccion=$(jq -r '.jurisdiccion' <<<"$line")
  texto=$(jq -r '.texto' <<<"$line")

  # Texto -> embedding con Ollama
  emb=$(curl -s "$EMBED_URL" -H "Content-Type: application/json" \
        -d "$(jq -n --arg m "$EMBED_MODEL" --arg p "$texto" '{model:$m, prompt:$p}')" \
        | jq -c '.embedding')

  # Construir el body para Qdrant
  body=$(jq -n \
      --argjson vec "$emb" \
      --arg id "$i" \
      --arg doc_id "$doc_id" \
      --arg norma "$norma" \
      --arg articulo "$articulo" \
      --arg boe_url "$boe_url" \
      --arg jurisdiccion "$jurisdiccion" \
      --arg texto "$texto" '
    {
      points: [
        {
          id: ($id|tonumber),
          vector: $vec,
          payload: {
            doc_id: $doc_id,
            norma: $norma,
            articulo: $articulo,
            boe_url: $boe_url,
            jurisdiccion: $jurisdiccion,
            texto: $texto
          }
        }
      ]
    }')

  # Insertar el punto en Qdrant
  curl -s -X PUT "$QDRANT_URL/collections/$COLLECTION/points" \
      -H "Content-Type: application/json" \
      -d "$body" >/dev/null

  echo "Indexed $i ($doc_id)"
  i=$((i+1))
done < "$FILE"

echo "Listo."
