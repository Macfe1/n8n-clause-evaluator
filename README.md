# 📄 Evaluador de Cláusulas Contractuales

> **Prueba técnica para n8n** - Workflow que evalúa cláusulas contractuales usando RAG, IA y normativa española.

Este proyecto fue desarrollado como parte de una evaluación técnica que requería implementar un sistema de análisis de cláusulas usando los siguientes nodos de n8n:
- ✅ Webhook
- ✅ HTTP Request
- ✅ Agente de IA
- ✅ RAG (Retrieval-Augmented Generation)
- ✅ Code

El sistema recibe una cláusula, la evalúa contra normativa española (Código de Comercio, LSC, LC, RRM), y devuelve un análisis estructurado con score de riesgo, citas normativas y sugerencias de redacción.

## 🛠️ Tecnologías

- **Ollama** - Embeddings locales con `nomic-embed-text`
- **Qdrant** - Vector store para búsqueda semántica
- **n8n** - Orquestación del flujo: Webhook → Embeddings → Qdrant → IA Agent


## 📋 Requisitos

- n8n (local o cloud)
- Docker + Docker Compose
- `curl`, `jq`
- **(Opcional)** ngrok o Cloudflare Tunnel si necesitas exponer puertos públicamente para n8n cloud


## Estructura del repo

```
n8n-clause-evaluator/
├─ corpus/
│  └─ corpus_txt/mini_corpus.jsonl
├─ scripts/
│  ├─ index_corpus.sh
│  └─ tests/
│     ├─ test_1.sh
│     └─ test_2.sh
├─ docker/
│  ├─ .env
│  ├─ .env.example
│  └─ docker-compose.yml
└─ workflow/
   └─ (Mi workflow de n8n)
```

## 🚀 Ejecutar el Flujo Completo

### 1️⃣ Levantar servicios en Docker

Inicia Qdrant y Ollama:

```
cd docker
docker compose up -d
```

### 2️⃣ Descargar modelo de embeddings en Ollama

```
docker exec -it ollama_container ollama pull nomic-embed-text
```

### 3️⃣ Cargar el corpus en Qdrant

Ejecuta el script ubicado en `scripts/index_corpus.sh`:

```
chmod +x scripts/index_corpus.sh
./scripts/index_corpus.sh
```

## 🧪 Tests Rápidos en Terminal (sin n8n)

Para probar Ollama y Qdrant

```
chmod +x scripts/test_1.sh
chmod +x scripts/test_2.sh

./scripts/test_1.sh
./scripts/test_2.sh
```

## 🔗 Flujo en n8n

**Nodos y mapeo**

- Webhook (POST)
    Recibe JSON del cliente:
    {"prompt":"texto a evaluar","top_k":3}

- Normalizo entrada (Code: “Review input”)
    Aseguro que existan prompt y top_k.

- Embeddings (HTTP → Ollama)
    POST a (URL Ollama) con {model:"nomic-embed-text", prompt} → obtengo embedding.

- Búsqueda (HTTP → Qdrant)
    POST a (URL QDRANT SEARCH) con vector, limit=top_k(Opcional), with_payload:true → obtengo result (citas del corpus).

- Construyo contexto (Code: “Build Prompt”)
    Armo ctx concatenando los trozos payload.texto (+ ids/normas). Si no hay citas, lanzo error.

- Agente IA
    Le paso {prompt, ctx} y me devuelve solo JSON con:
    score, risk_level, answer, policy_citation, read_line_suggestion.

- Respond to Webhook
    Devuelvo ese JSON al cliente.

## ⚡Cómo usarlo

1. Pulsa Execute Workflow (modo test) y copia la URL.

2. En tu terminal puedes correr este curl.

```
curl -X POST "N8N URL TESt" \
> -H "Content-Type: application/json" \
> -d '{"prompt":"Cláusula de Operación y Publicidad. La Sociedad podrá iniciar y continuar sus actividades mercantiles y celebrar cualquier acto o contrato sin necesidad de escritura pública ni inscripción en el Registro Mercantil, siendo plenamente oponibles a terceros desde su firma y sin publicación en el BORME.","top_k":5}'
```

3. Debes recibir un JSON tipo:

```json
{
  "score": "8.0",
  "risk_level": "HIGH",
  "answer": "...",
  "policy_citation": "RRM-Denominacion",
  "read_line_suggestion": "..."
}
```

## ⚙️ Requisitos Mínimos

- ✅ Ollama accesible (puerto público si usas n8n cloud) con nomic-embed-text descargado
- ✅ Qdrant accesible (puerto público si usas n8n cloud) con colección clauses_es_v1 y corpus cargado
- 💡 Nota: Si n8n está en cloud y Ollama/Qdrant en local, expón ambos con ngrok o Cloudflare Tunnel y usa esas URLs en los nodos HTTP


🎯 ¡Listo para evaluar cláusulas contractuales con IA!