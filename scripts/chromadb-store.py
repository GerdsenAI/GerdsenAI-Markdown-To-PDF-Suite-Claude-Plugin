#!/usr/bin/env python3
"""ChromaDB local vector storage for GerdsenAI research memory.

Provides persistent, local vector storage as an alternative to Pinecone.
Uses ChromaDB's built-in embedding model (no API keys needed).

Commands:
    init <project-name>             Create/open a persistent collection
    store <collection> <text>       Add a document with optional metadata
        [--metadata '{"key":"val"}']
        [--chunk-size 500]
        [--chunk-overlap 100]
    query <collection> <query>      Semantic search
        [--n-results 5]
        [--max-distance 1.0]
        [--where '{"phase":"4"}']
    list                            List all collections
    clear <collection>              Delete a collection

Global optional flags:
    --settings <path>               Read defaults from a settings file
    --embedding-model <model>       Override embedding model

Settings (via --settings):
    vector_db_chromadb_embedding_model   (default: all-MiniLM-L6-v2)
    vector_db_chromadb_chunk_size        (default: 500)
    vector_db_chromadb_chunk_overlap     (default: 100)
    vector_db_chromadb_max_distance      (default: 1.0)
    vector_db_chromadb_default_results   (default: 5)

Storage location: ~/.gerdsenai/chromadb/<project-name>/
"""

import argparse
import hashlib
import json
import os
import re
import sys
import uuid


# --- YAML Front Matter Parser (matches bash parse-settings.sh pattern) ---

def parse_settings(settings_path):
    """Read flat YAML front matter from a settings file.

    Line-by-line regex parser matching the bash parse-settings.sh pattern.
    Strips \\r for Windows CRLF compatibility.
    Returns a dict of key-value pairs found between --- delimiters.
    """
    settings = {}
    if not settings_path or not os.path.isfile(settings_path):
        return settings

    in_frontmatter = False
    try:
        with open(settings_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\r\n")
                if line == "---":
                    if in_frontmatter:
                        break
                    else:
                        in_frontmatter = True
                        continue
                if in_frontmatter:
                    m = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*):\s*"?([^"]*)"?\s*$', line)
                    if m:
                        settings[m.group(1)] = m.group(2).strip()
    except OSError:
        pass
    return settings


def get_setting(settings, key, default=None):
    """Get a setting value with type coercion for booleans, ints, and floats."""
    val = settings.get(key)
    if val is None:
        return default
    if isinstance(default, bool):
        return val.lower() in ("true", "yes", "1")
    if isinstance(default, int):
        try:
            return int(val)
        except ValueError:
            return default
    if isinstance(default, float):
        try:
            return float(val)
        except ValueError:
            return default
    return val


def resolve_chromadb_settings(args):
    """Resolve ChromaDB settings from --settings file and CLI overrides.

    Priority: CLI flag > settings file > built-in default.
    Returns a dict with resolved values.
    """
    file_settings = {}
    if hasattr(args, "settings") and args.settings:
        file_settings = parse_settings(args.settings)

    # Embedding model: CLI flag > settings file > built-in default
    embedding_model = "all-MiniLM-L6-v2"
    settings_model = get_setting(file_settings, "vector_db_chromadb_embedding_model", None)
    if settings_model:
        embedding_model = settings_model
    if hasattr(args, "embedding_model") and args.embedding_model:
        embedding_model = args.embedding_model

    return {
        "embedding_model": embedding_model,
        "chunk_size": get_setting(file_settings, "vector_db_chromadb_chunk_size", 500),
        "chunk_overlap": get_setting(file_settings, "vector_db_chromadb_chunk_overlap", 100),
        "max_distance": get_setting(file_settings, "vector_db_chromadb_max_distance", 1.0),
        "default_results": get_setting(file_settings, "vector_db_chromadb_default_results", 5),
    }


def get_embedding_function(model_name):
    """Get a ChromaDB embedding function for the specified model.

    Returns None to use ChromaDB's built-in default (all-MiniLM-L6-v2),
    or a SentenceTransformerEmbeddingFunction for alternative models.
    """
    if model_name == "all-MiniLM-L6-v2":
        return None  # ChromaDB's built-in default

    try:
        from chromadb.utils.embedding_functions import SentenceTransformerEmbeddingFunction
        return SentenceTransformerEmbeddingFunction(model_name=model_name)
    except ImportError:
        print(f"WARNING: Could not load embedding function for '{model_name}', "
              f"falling back to default", file=sys.stderr)
        return None
    except Exception as e:
        print(f"WARNING: Error loading model '{model_name}': {e}, "
              f"falling back to default", file=sys.stderr)
        return None


def get_chromadb_base_path():
    """Get the base path for ChromaDB storage from environment or default."""
    return os.environ.get("GERDSEN_CHROMADB_PATH", os.path.join(os.path.expanduser("~"), ".gerdsenai", "chromadb"))


def normalize_name(name):
    """Normalize project/collection names for consistency."""
    return name.lower().strip().replace(" ", "-")


def validate_metadata(metadata):
    """Ensure all metadata values are ChromaDB-compatible scalars.

    ChromaDB only supports str, int, float, bool as metadata values.
    Nested structures (lists, dicts) are serialized to JSON strings.
    """
    cleaned = {}
    for k, v in metadata.items():
        if isinstance(v, (str, int, float, bool)):
            cleaned[k] = v
        elif isinstance(v, (list, dict)):
            cleaned[k] = json.dumps(v)
        else:
            cleaned[k] = str(v)
    return cleaned


def chunk_text(text, chunk_size=500, overlap=100):
    """Split text into overlapping chunks for better embedding coverage.

    ChromaDB's default embedding model (all-MiniLM-L6-v2) truncates inputs
    to 256 tokens. Chunking ensures long documents are fully searchable.
    """
    if len(text) <= chunk_size:
        return [text]
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + chunk_size, len(text))
        chunks.append(text[start:end])
        if end >= len(text):
            break
        start += chunk_size - overlap
    return chunks


def get_client(project_name=None):
    """Get a persistent ChromaDB client."""
    try:
        import chromadb
    except ImportError:
        print(json.dumps({
            "success": False,
            "error": "ChromaDB is not installed. Run: <venv_python> -m pip install chromadb"
        }))
        sys.exit(1)

    base_path = get_chromadb_base_path()
    if project_name:
        project_name = normalize_name(project_name)
        persist_dir = os.path.join(base_path, project_name)
    else:
        persist_dir = base_path

    os.makedirs(persist_dir, exist_ok=True)
    return chromadb.PersistentClient(path=persist_dir)


def cmd_init(args):
    """Create or open a persistent collection for a project."""
    project = normalize_name(args.project_name)
    client = get_client(project)
    cfg = resolve_chromadb_settings(args)

    # Build collection kwargs with optional embedding function
    collection_kwargs = {
        "name": "research",
        "metadata": {"project": project},
    }
    ef = get_embedding_function(cfg["embedding_model"])
    if ef is not None:
        collection_kwargs["embedding_function"] = ef

    collection = client.get_or_create_collection(**collection_kwargs)
    count = collection.count()

    result = {
        "success": True,
        "project": project,
        "collection": "research",
        "document_count": count,
        "path": os.path.join(get_chromadb_base_path(), project),
        "embedding_model": cfg["embedding_model"],
    }

    # Check if embedding model is likely cached
    cache_dirs = [
        os.path.join(os.path.expanduser("~"), ".cache", "chroma"),
        os.path.join(os.path.expanduser("~"), ".cache", "huggingface"),
    ]
    model_cached = any(os.path.isdir(d) and os.listdir(d) for d in cache_dirs)
    if not model_cached and count == 0:
        result["note"] = "First store/query will download the embedding model (~50MB). Subsequent operations are local-only."

    print(json.dumps(result))


def cmd_store(args):
    """Store a document in a project's collection."""
    collection_name = normalize_name(args.collection)
    client = get_client(collection_name)
    cfg = resolve_chromadb_settings(args)

    # Build collection kwargs with optional embedding function
    collection_kwargs = {"name": "research"}
    ef = get_embedding_function(cfg["embedding_model"])
    if ef is not None:
        collection_kwargs["embedding_function"] = ef

    collection = client.get_or_create_collection(**collection_kwargs)

    metadata = {}
    if args.metadata:
        try:
            metadata = json.loads(args.metadata)
        except json.JSONDecodeError:
            print(json.dumps({"success": False, "error": "Invalid JSON metadata"}))
            sys.exit(1)

    # Validate metadata values (ChromaDB only supports scalars)
    if metadata:
        metadata = validate_metadata(metadata)

    # Resolve chunk params: CLI value if explicitly provided, else settings default
    # argparse defaults are 500/100; settings may override those
    chunk_size = args.chunk_size if args.chunk_size is not None else cfg["chunk_size"]
    chunk_overlap = args.chunk_overlap if args.chunk_overlap is not None else cfg["chunk_overlap"]

    # Chunk the text for better embedding coverage
    chunks = chunk_text(args.text, chunk_size, chunk_overlap)
    base_id = str(uuid.uuid4())

    docs = []
    metas = []
    ids = []

    for i, chunk in enumerate(chunks):
        chunk_id = f"{base_id}_chunk_{i}" if len(chunks) > 1 else base_id
        chunk_meta = dict(metadata) if metadata else {}
        if len(chunks) > 1:
            chunk_meta["chunk_index"] = i
            chunk_meta["total_chunks"] = len(chunks)
            chunk_meta["parent_id"] = base_id
        docs.append(chunk)
        metas.append(chunk_meta if chunk_meta else None)
        ids.append(chunk_id)

    try:
        # ChromaDB requires metadatas to be None or a list of dicts (not a list with None entries)
        effective_metas = metas if any(m for m in metas) else None
        collection.add(
            documents=docs,
            metadatas=effective_metas,
            ids=ids
        )
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Failed to store document: {e}",
            "hint": "If this is the first run, ChromaDB needs to download its embedding model (~50MB). Check your internet connection."
        }))
        sys.exit(1)

    print(json.dumps({
        "success": True,
        "id": base_id,
        "chunks_created": len(chunks),
        "collection": collection_name,
        "document_count": collection.count()
    }))


def cmd_query(args):
    """Query a project's collection for similar documents."""
    collection_name = normalize_name(args.collection)
    client = get_client(collection_name)
    cfg = resolve_chromadb_settings(args)

    # Build collection kwargs with optional embedding function
    get_kwargs = {"name": "research"}
    ef = get_embedding_function(cfg["embedding_model"])
    if ef is not None:
        get_kwargs["embedding_function"] = ef

    try:
        collection = client.get_collection(**get_kwargs)
    except Exception:
        print(json.dumps({
            "success": False,
            "error": f"Collection '{collection_name}' not found. Run 'init {collection_name}' first."
        }))
        sys.exit(1)

    if collection.count() == 0:
        print(json.dumps({
            "success": True,
            "results": [],
            "message": "Collection is empty"
        }))
        return

    # Parse --where filter if provided
    where_filter = None
    if args.where:
        try:
            where_filter = json.loads(args.where)
        except json.JSONDecodeError:
            print(json.dumps({"success": False, "error": "Invalid JSON for --where filter"}))
            sys.exit(1)

    # Resolve query params: CLI value if explicitly changed, else settings default
    n_results = args.n_results if args.n_results is not None else cfg["default_results"]
    max_distance = args.max_distance if args.max_distance is not None else cfg["max_distance"]

    try:
        query_kwargs = {
            "query_texts": [args.query_text],
            "n_results": min(n_results, collection.count()),
        }
        if where_filter:
            query_kwargs["where"] = where_filter

        results = collection.query(**query_kwargs)
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Query failed: {e}",
            "hint": "If this is the first run, ChromaDB needs to download its embedding model (~50MB). Check your internet connection."
        }))
        sys.exit(1)

    formatted = []
    if results and results["documents"]:
        for i, doc in enumerate(results["documents"][0]):
            distance = results["distances"][0][i] if results.get("distances") else None
            entry = {
                "rank": i + 1,
                "text": doc,
                "distance": distance,
            }
            if results.get("metadatas") and results["metadatas"][0][i]:
                entry["metadata"] = results["metadatas"][0][i]
            formatted.append(entry)

    # Apply max-distance filter
    total_before_filter = len(formatted)
    if max_distance is not None:
        formatted = [e for e in formatted if e["distance"] is not None and e["distance"] <= max_distance]

    print(json.dumps({
        "success": True,
        "query": args.query_text,
        "results": formatted,
        "total_in_collection": collection.count(),
        "max_distance": max_distance,
        "filtered_count": total_before_filter - len(formatted)
    }))


def cmd_list(args):
    """List all project collections."""
    base_path = get_chromadb_base_path()
    projects = []

    if os.path.exists(base_path):
        for name in sorted(os.listdir(base_path)):
            project_path = os.path.join(base_path, name)
            if os.path.isdir(project_path):
                try:
                    client = get_client(name)
                    collection = client.get_collection(name="research")
                    projects.append({
                        "project": name,
                        "document_count": collection.count(),
                        "path": project_path
                    })
                except Exception:
                    projects.append({
                        "project": name,
                        "document_count": 0,
                        "path": project_path,
                        "error": "Could not read collection"
                    })

    print(json.dumps({
        "success": True,
        "projects": projects,
        "total": len(projects)
    }))


def cmd_clear(args):
    """Delete a project's collection."""
    collection_name = normalize_name(args.collection)
    client = get_client(collection_name)

    try:
        client.delete_collection(name="research")
        print(json.dumps({
            "success": True,
            "collection": collection_name,
            "message": "Collection deleted"
        }))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Failed to delete collection: {e}"
        }))
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="ChromaDB local vector storage for GerdsenAI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # init
    p_init = subparsers.add_parser("init", help="Create/open a persistent collection")
    p_init.add_argument("project_name", help="Project name (used for storage isolation)")
    p_init.add_argument("--settings", default=None,
                        help="Path to settings file for defaults")
    p_init.add_argument("--embedding-model", default=None,
                        help="Override embedding model (e.g. sentence-transformers/all-mpnet-base-v2)")
    p_init.set_defaults(func=cmd_init)

    # store
    p_store = subparsers.add_parser("store", help="Store a document")
    p_store.add_argument("collection", help="Project/collection name")
    p_store.add_argument("text", help="Document text to store")
    p_store.add_argument("--metadata", help="JSON metadata string", default=None)
    p_store.add_argument("--chunk-size", type=int, default=None,
                         help="Chunk size in characters (default: 500 or from settings)")
    p_store.add_argument("--chunk-overlap", type=int, default=None,
                         help="Overlap between chunks in characters (default: 100 or from settings)")
    p_store.add_argument("--settings", default=None,
                         help="Path to settings file for defaults")
    p_store.add_argument("--embedding-model", default=None,
                         help="Override embedding model (e.g. sentence-transformers/all-mpnet-base-v2)")
    p_store.set_defaults(func=cmd_store)

    # query
    p_query = subparsers.add_parser("query", help="Semantic search")
    p_query.add_argument("collection", help="Project/collection name")
    p_query.add_argument("query_text", help="Query text")
    p_query.add_argument("--n-results", type=int, default=None, help="Number of results (default: 5 or from settings)")
    p_query.add_argument("--max-distance", type=float, default=None,
                         help="Maximum distance threshold (default: 1.0 or from settings, range 0-2 for cosine)")
    p_query.add_argument("--where", type=str, default=None,
                         help='ChromaDB where filter JSON, e.g. \'{"phase": "4"}\'')
    p_query.add_argument("--settings", default=None,
                         help="Path to settings file for defaults")
    p_query.add_argument("--embedding-model", default=None,
                         help="Override embedding model (e.g. sentence-transformers/all-mpnet-base-v2)")
    p_query.set_defaults(func=cmd_query)

    # list
    p_list = subparsers.add_parser("list", help="List all collections")
    p_list.set_defaults(func=cmd_list)

    # clear
    p_clear = subparsers.add_parser("clear", help="Delete a collection")
    p_clear.add_argument("collection", help="Project/collection name to delete")
    p_clear.set_defaults(func=cmd_clear)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
