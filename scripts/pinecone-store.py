#!/usr/bin/env python3
"""Pinecone vector storage for GerdsenAI research memory.

Provides cloud-hosted vector storage using Pinecone's integrated inference.
Uses Pinecone's built-in embedding models (requires PINECONE_API_KEY).

Commands:
    init <repo-name>                Create/connect to an integrated index
    store <index> <text>            Upsert a record with optional metadata
        [--metadata '{"key":"val"}']
        [--namespace <ns>]
    query <index> <query_text>      Semantic search with auto-embedding
        [--n-results 5]
        [--namespace <ns>]
        [--rerank]
        [--rerank-model <model>]
        [--rerank-top-n N]
    list                            List all indexes
    clear <index>                   Delete an index or namespace
        [--namespace <ns>]

Settings (via --settings):
    vector_db_pinecone_embedding_model   (default: llama-text-embed-v2)
    vector_db_pinecone_cloud             (default: aws)
    vector_db_pinecone_region            (default: us-east-1)
    vector_db_pinecone_rerank_enabled    (default: false)
    vector_db_pinecone_rerank_model      (default: pinecone-rerank-v0)
    vector_db_pinecone_rerank_top_n      (default: 5)
"""

import argparse
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
    """Get a setting value with type coercion for booleans and ints."""
    val = settings.get(key)
    if val is None:
        return default
    # Boolean coercion
    if isinstance(default, bool):
        return val.lower() in ("true", "yes", "1")
    # Integer coercion
    if isinstance(default, int):
        try:
            return int(val)
        except ValueError:
            return default
    return val


# --- Helpers ---

def normalize_name(name):
    """Normalize index names for consistency."""
    return name.lower().strip().replace(" ", "-")


def validate_metadata(metadata):
    """Ensure all metadata values are Pinecone-compatible scalars.

    Pinecone supports str, int, float, bool as metadata values.
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


def get_pinecone_client():
    """Create a Pinecone client. Requires PINECONE_API_KEY env var."""
    try:
        from pinecone import Pinecone
    except ImportError:
        print(json.dumps({
            "success": False,
            "error": "Pinecone SDK is not installed. Run: pip install pinecone"
        }))
        sys.exit(1)

    api_key = os.environ.get("PINECONE_API_KEY")
    if not api_key:
        print(json.dumps({
            "success": False,
            "error": "PINECONE_API_KEY environment variable is not set. "
                     "Get your API key from https://app.pinecone.io/"
        }))
        sys.exit(1)

    return Pinecone(api_key=api_key)


def resolve_settings(args):
    """Resolve settings from --settings file, returning merged defaults."""
    settings = {}
    if hasattr(args, "settings") and args.settings:
        settings = parse_settings(args.settings)

    return {
        "embedding_model": get_setting(
            settings, "vector_db_pinecone_embedding_model", "llama-text-embed-v2"
        ),
        "cloud": get_setting(
            settings, "vector_db_pinecone_cloud", "aws"
        ),
        "region": get_setting(
            settings, "vector_db_pinecone_region", "us-east-1"
        ),
        "rerank_enabled": get_setting(
            settings, "vector_db_pinecone_rerank_enabled", False
        ),
        "rerank_model": get_setting(
            settings, "vector_db_pinecone_rerank_model", "pinecone-rerank-v0"
        ),
        "rerank_top_n": get_setting(
            settings, "vector_db_pinecone_rerank_top_n", 5
        ),
    }


# --- Commands ---

def cmd_init(args):
    """Create or connect to an integrated Pinecone index."""
    from pinecone import ServerlessSpec

    index_name = normalize_name(args.repo_name)
    pc = get_pinecone_client()
    cfg = resolve_settings(args)

    # Check if index already exists
    existing = [idx.name for idx in pc.list_indexes()]

    if index_name not in existing:
        try:
            pc.create_index(
                name=index_name,
                dimension=1024,
                metric="cosine",
                spec=ServerlessSpec(
                    cloud=cfg["cloud"],
                    region=cfg["region"],
                ),
                tags={"source": "gerdsenai-plugin"},
            )
        except Exception as e:
            error_str = str(e)
            # If the index already exists (race condition), continue
            if "ALREADY_EXISTS" not in error_str:
                print(json.dumps({
                    "success": False,
                    "error": f"Failed to create index: {error_str}"
                }))
                sys.exit(1)

    # Connect and get stats
    try:
        idx = pc.Index(index_name)
        stats = idx.describe_index_stats()
        doc_count = stats.get("total_vector_count", 0)
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Failed to connect to index: {e}"
        }))
        sys.exit(1)

    print(json.dumps({
        "success": True,
        "index": index_name,
        "document_count": doc_count,
        "embedding_model": cfg["embedding_model"],
        "cloud": cfg["cloud"],
        "region": cfg["region"],
    }))


def cmd_store(args):
    """Store a record in a Pinecone index using integrated inference."""
    index_name = normalize_name(args.index)
    pc = get_pinecone_client()
    cfg = resolve_settings(args)

    metadata = {}
    if args.metadata:
        try:
            metadata = json.loads(args.metadata)
        except json.JSONDecodeError:
            print(json.dumps({"success": False, "error": "Invalid JSON metadata"}))
            sys.exit(1)

    # Validate metadata values (Pinecone only supports scalars)
    if metadata:
        metadata = validate_metadata(metadata)

    record_id = str(uuid.uuid4())

    try:
        idx = pc.Index(index_name)
        # Use integrated inference: pass text directly, Pinecone embeds it
        record = {
            "id": record_id,
            "_text": args.text,
        }
        if metadata:
            record.update(metadata)

        upsert_kwargs = {"records": [record]}
        if args.namespace:
            upsert_kwargs["namespace"] = args.namespace

        idx.upsert_records(**upsert_kwargs)
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Failed to store record: {e}"
        }))
        sys.exit(1)

    result = {
        "success": True,
        "id": record_id,
        "index": index_name,
    }
    if args.namespace:
        result["namespace"] = args.namespace

    print(json.dumps(result))


def cmd_query(args):
    """Query a Pinecone index using integrated inference."""
    index_name = normalize_name(args.index)
    pc = get_pinecone_client()
    cfg = resolve_settings(args)

    n_results = args.n_results if args.n_results else cfg.get("rerank_top_n", 5)

    # Determine reranking: CLI flag overrides settings
    do_rerank = args.rerank if args.rerank else cfg["rerank_enabled"]
    rerank_model = args.rerank_model if args.rerank_model else cfg["rerank_model"]
    rerank_top_n = args.rerank_top_n if args.rerank_top_n else cfg["rerank_top_n"]

    try:
        idx = pc.Index(index_name)

        search_kwargs = {
            "query": {"top_k": n_results, "inputs": {"text": args.query_text}},
        }
        if args.namespace:
            search_kwargs["namespace"] = args.namespace

        if do_rerank:
            search_kwargs["rerank"] = {
                "model": rerank_model,
                "top_n": rerank_top_n,
                "rank_fields": ["_text"],
            }

        results = idx.search(**search_kwargs)
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Query failed: {e}",
            "hint": "Ensure the index exists and has records. Run 'init' first."
        }))
        sys.exit(1)

    formatted = []
    hits = results.get("result", {}).get("hits", []) if isinstance(results, dict) else []
    # Handle SDK response object (may have .result.hits or be iterable)
    if not hits and hasattr(results, "result"):
        result_obj = results.result
        if hasattr(result_obj, "hits"):
            hits = result_obj.hits

    for i, hit in enumerate(hits):
        entry = {"rank": i + 1}

        # Extract score
        if isinstance(hit, dict):
            entry["score"] = hit.get("_score", hit.get("score"))
            fields = hit.get("fields", hit)
            entry["text"] = fields.get("_text", "")
            # Collect metadata (everything except _text, _score, id)
            meta = {k: v for k, v in fields.items()
                    if k not in ("_text", "_score", "id", "_id")}
            if meta:
                entry["metadata"] = meta
            entry["id"] = hit.get("_id", hit.get("id", ""))
        elif hasattr(hit, "_score"):
            entry["score"] = hit._score
            entry["text"] = getattr(hit, "_text", "")
            entry["id"] = getattr(hit, "_id", getattr(hit, "id", ""))
            # Collect metadata from hit fields
            if hasattr(hit, "fields") and hit.fields:
                meta = {k: v for k, v in hit.fields.items()
                        if k not in ("_text",)}
                if meta:
                    entry["metadata"] = meta
        else:
            entry["text"] = str(hit)

        formatted.append(entry)

    output = {
        "success": True,
        "query": args.query_text,
        "results": formatted,
        "index": index_name,
    }
    if args.namespace:
        output["namespace"] = args.namespace
    if do_rerank:
        output["reranked"] = True
        output["rerank_model"] = rerank_model

    print(json.dumps(output))


def cmd_list(args):
    """List all Pinecone indexes."""
    pc = get_pinecone_client()

    try:
        indexes = []
        for idx_info in pc.list_indexes():
            entry = {"name": idx_info.name}
            if hasattr(idx_info, "dimension"):
                entry["dimension"] = idx_info.dimension
            if hasattr(idx_info, "metric"):
                entry["metric"] = idx_info.metric
            if hasattr(idx_info, "host"):
                entry["host"] = idx_info.host

            # Get document count
            try:
                idx = pc.Index(idx_info.name)
                stats = idx.describe_index_stats()
                entry["document_count"] = stats.get("total_vector_count", 0)
            except Exception:
                entry["document_count"] = None

            indexes.append(entry)

        print(json.dumps({
            "success": True,
            "indexes": indexes,
            "total": len(indexes)
        }))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Failed to list indexes: {e}"
        }))
        sys.exit(1)


def cmd_clear(args):
    """Delete a Pinecone index or namespace."""
    index_name = normalize_name(args.index)
    pc = get_pinecone_client()

    if args.namespace:
        # Delete just the namespace, not the whole index
        try:
            idx = pc.Index(index_name)
            idx.delete(delete_all=True, namespace=args.namespace)
            print(json.dumps({
                "success": True,
                "index": index_name,
                "namespace": args.namespace,
                "message": f"Namespace '{args.namespace}' cleared"
            }))
        except Exception as e:
            print(json.dumps({
                "success": False,
                "error": f"Failed to clear namespace: {e}"
            }))
            sys.exit(1)
    else:
        # Delete the entire index
        try:
            pc.delete_index(index_name)
            print(json.dumps({
                "success": True,
                "index": index_name,
                "message": "Index deleted"
            }))
        except Exception as e:
            print(json.dumps({
                "success": False,
                "error": f"Failed to delete index: {e}"
            }))
            sys.exit(1)


# --- Main ---

def main():
    parser = argparse.ArgumentParser(
        description="Pinecone vector storage for GerdsenAI research memory"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # init
    p_init = subparsers.add_parser("init", help="Create/connect to an integrated index")
    p_init.add_argument("repo_name", help="Repository/index name")
    p_init.add_argument("--settings", default=None,
                        help="Path to settings file for defaults")
    p_init.set_defaults(func=cmd_init)

    # store
    p_store = subparsers.add_parser("store", help="Store a record")
    p_store.add_argument("index", help="Index name")
    p_store.add_argument("text", help="Document text to store")
    p_store.add_argument("--metadata", default=None,
                         help="JSON metadata string")
    p_store.add_argument("--namespace", default=None,
                         help="Pinecone namespace for record isolation")
    p_store.add_argument("--settings", default=None,
                         help="Path to settings file for defaults")
    p_store.set_defaults(func=cmd_store)

    # query
    p_query = subparsers.add_parser("query", help="Semantic search")
    p_query.add_argument("index", help="Index name")
    p_query.add_argument("query_text", help="Query text")
    p_query.add_argument("--n-results", type=int, default=5,
                         help="Number of results (default: 5)")
    p_query.add_argument("--namespace", default=None,
                         help="Pinecone namespace to search")
    p_query.add_argument("--rerank", action="store_true", default=False,
                         help="Enable reranking of results")
    p_query.add_argument("--rerank-model", default=None,
                         help="Rerank model (default: pinecone-rerank-v0)")
    p_query.add_argument("--rerank-top-n", type=int, default=None,
                         help="Number of results after reranking")
    p_query.add_argument("--settings", default=None,
                         help="Path to settings file for defaults")
    p_query.set_defaults(func=cmd_query)

    # list
    p_list = subparsers.add_parser("list", help="List all indexes")
    p_list.set_defaults(func=cmd_list)

    # clear
    p_clear = subparsers.add_parser("clear", help="Delete an index or namespace")
    p_clear.add_argument("index", help="Index name to delete")
    p_clear.add_argument("--namespace", default=None,
                         help="Delete only this namespace (keeps the index)")
    p_clear.set_defaults(func=cmd_clear)

    args = parser.parse_args()

    try:
        args.func(args)
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Unexpected error: {e}"
        }), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
