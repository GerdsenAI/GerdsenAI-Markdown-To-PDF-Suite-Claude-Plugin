#!/usr/bin/env python3
"""ChromaDB reporting utility for GerdsenAI research memory.

Generates detailed reports on vector database contents, metadata analysis,
data quality metrics, and system health.

Commands:
    report <project-name>   Detailed report for a single project
    report --all            Cross-project overview with summaries
    health                  System health: versions, paths, disk usage, cache status
"""

import argparse
import hashlib
import json
import os
import sys


def get_chromadb_base_path():
    """Get the base path for ChromaDB storage from environment or default."""
    return os.environ.get("GERDSEN_CHROMADB_PATH", os.path.join(os.path.expanduser("~"), ".gerdsenai", "chromadb"))


def normalize_name(name):
    """Normalize project/collection names for consistency."""
    return name.lower().strip().replace(" ", "-")


def get_dir_size(path):
    """Calculate total size of a directory in bytes."""
    total = 0
    for dirpath, dirnames, filenames in os.walk(path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            try:
                total += os.path.getsize(fp)
            except OSError:
                pass
    return total


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


def analyze_metadata_schema(metadatas):
    """Analyze metadata across all documents to discover field distributions."""
    if not metadatas:
        return {"observed_fields": [], "field_distributions": {}}

    field_counts = {}
    field_values = {}

    for meta in metadatas:
        if not meta:
            continue
        for key, value in meta.items():
            field_counts[key] = field_counts.get(key, 0) + 1
            if key not in field_values:
                field_values[key] = {}
            str_val = str(value)
            field_values[key][str_val] = field_values[key].get(str_val, 0) + 1

    # Limit distributions to top 10 values per field
    distributions = {}
    for key, vals in field_values.items():
        sorted_vals = sorted(vals.items(), key=lambda x: -x[1])[:10]
        distributions[key] = dict(sorted_vals)

    return {
        "observed_fields": sorted(field_counts.keys()),
        "field_distributions": distributions
    }


def analyze_data_quality(documents, metadatas, ids):
    """Analyze data quality: duplicates, empties, metadata completeness."""
    total = len(documents)
    if total == 0:
        return {
            "duplicate_documents": 0,
            "empty_documents": 0,
            "documents_without_metadata": 0,
            "metadata_completeness": 1.0
        }

    # Check for empty documents
    empty_count = sum(1 for doc in documents if not doc or not doc.strip())

    # Check for duplicate documents (by content hash)
    seen_hashes = set()
    duplicate_count = 0
    for doc in documents:
        h = hashlib.md5(doc.encode() if doc else b"").hexdigest()
        if h in seen_hashes:
            duplicate_count += 1
        seen_hashes.add(h)

    # Check metadata completeness
    docs_without_meta = 0
    if metadatas:
        for meta in metadatas:
            if not meta or len(meta) == 0:
                docs_without_meta += 1
    else:
        docs_without_meta = total

    completeness = 1.0 - (docs_without_meta / total) if total > 0 else 1.0

    return {
        "duplicate_documents": duplicate_count,
        "empty_documents": empty_count,
        "documents_without_metadata": docs_without_meta,
        "metadata_completeness": round(completeness, 2)
    }


def get_sample_documents(collection, limit=5):
    """Get a sample of documents with previews."""
    count = collection.count()
    if count == 0:
        return []

    result = collection.get(limit=min(limit, count), include=["documents", "metadatas"])
    samples = []
    for i in range(len(result["ids"])):
        doc = result["documents"][i] if result["documents"] else ""
        meta = result["metadatas"][i] if result["metadatas"] else None
        samples.append({
            "id": result["ids"][i],
            "text_preview": (doc[:200] + "...") if len(doc) > 200 else doc,
            "metadata": meta
        })
    return samples


def cmd_report(args):
    """Generate a detailed report for a single project or all projects."""
    if args.all:
        cmd_report_all(args)
        return

    if not args.project_name:
        print(json.dumps({"success": False, "error": "Provide a project name or use --all"}))
        sys.exit(1)

    project = normalize_name(args.project_name)
    project_path = os.path.join(get_chromadb_base_path(), project)

    if not os.path.isdir(project_path):
        print(json.dumps({
            "success": False,
            "error": f"Project '{project}' not found at {project_path}"
        }))
        sys.exit(1)

    try:
        client = get_client(project)
        collection = client.get_collection(name="research")
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Could not open collection for '{project}': {e}"
        }))
        sys.exit(1)

    count = collection.count()
    storage_size = get_dir_size(project_path)

    # Get all documents for analysis
    all_data = None
    metadata_schema = {"observed_fields": [], "field_distributions": {}}
    quality = {
        "duplicate_documents": 0,
        "empty_documents": 0,
        "documents_without_metadata": 0,
        "metadata_completeness": 1.0
    }

    if count > 0:
        try:
            all_data = collection.get(include=["documents", "metadatas"])
            metadata_schema = analyze_metadata_schema(all_data["metadatas"])
            quality = analyze_data_quality(
                all_data["documents"],
                all_data["metadatas"],
                all_data["ids"]
            )
        except Exception:
            pass

    # Sample documents
    samples = get_sample_documents(collection)

    # Run a test query if there are documents
    query_test = None
    if count > 0:
        try:
            # Use the first metadata field's most common value as a test query
            test_query = project.replace("-", " ")
            results = collection.query(
                query_texts=[test_query],
                n_results=min(3, count)
            )
            if results and results["distances"] and results["distances"][0]:
                query_test = {
                    "query": test_query,
                    "top_result_distance": round(results["distances"][0][0], 4),
                    "results_within_threshold": sum(
                        1 for d in results["distances"][0] if d <= 1.0
                    )
                }
        except Exception:
            pass

    report = {
        "success": True,
        "backend": "chromadb",
        "project": project,
        "storage_path": project_path,
        "storage_size_bytes": storage_size,
        "document_count": count,
        "embedding_model": "all-MiniLM-L6-v2",
        "embedding_dimensions": 384,
        "metadata_schema": metadata_schema,
        "sample_documents": samples,
        "data_quality": quality
    }

    if query_test:
        report["query_test"] = query_test

    print(json.dumps(report))


def cmd_report_all(args):
    """Generate a cross-project overview."""
    base_path = get_chromadb_base_path()
    projects = []
    total_docs = 0
    total_size = 0

    if os.path.exists(base_path):
        for name in sorted(os.listdir(base_path)):
            project_path = os.path.join(base_path, name)
            if not os.path.isdir(project_path):
                continue

            size = get_dir_size(project_path)
            total_size += size

            try:
                client = get_client(name)
                collection = client.get_collection(name="research")
                count = collection.count()
                total_docs += count

                # Quick metadata field scan
                fields = []
                if count > 0:
                    try:
                        sample = collection.get(limit=min(10, count), include=["metadatas"])
                        field_set = set()
                        for meta in (sample["metadatas"] or []):
                            if meta:
                                field_set.update(meta.keys())
                        fields = sorted(field_set)
                    except Exception:
                        pass

                projects.append({
                    "project": name,
                    "document_count": count,
                    "storage_size_bytes": size,
                    "metadata_fields": fields,
                    "path": project_path
                })
            except Exception:
                projects.append({
                    "project": name,
                    "document_count": 0,
                    "storage_size_bytes": size,
                    "path": project_path,
                    "error": "Could not read collection"
                })

    print(json.dumps({
        "success": True,
        "backend": "chromadb",
        "projects": projects,
        "total_projects": len(projects),
        "total_documents": total_docs,
        "total_storage_bytes": total_size,
        "base_path": base_path
    }))


def cmd_health(args):
    """Check ChromaDB system health."""
    base_path = get_chromadb_base_path()

    # ChromaDB version
    chromadb_version = None
    try:
        import chromadb
        chromadb_version = chromadb.__version__
    except ImportError:
        print(json.dumps({
            "success": False,
            "error": "ChromaDB is not installed"
        }))
        sys.exit(1)

    # Storage stats
    storage_exists = os.path.isdir(base_path)
    total_size = get_dir_size(base_path) if storage_exists else 0
    project_count = 0
    if storage_exists:
        project_count = sum(
            1 for name in os.listdir(base_path)
            if os.path.isdir(os.path.join(base_path, name))
        )

    # Embedding model cache
    cache_dirs = [
        os.path.join(os.path.expanduser("~"), ".cache", "chroma"),
        os.path.join(os.path.expanduser("~"), ".cache", "huggingface"),
    ]
    model_cached = any(os.path.isdir(d) and os.listdir(d) for d in cache_dirs)
    cache_size = 0
    for d in cache_dirs:
        if os.path.isdir(d):
            cache_size += get_dir_size(d)

    print(json.dumps({
        "success": True,
        "chromadb_version": chromadb_version,
        "base_storage_path": base_path,
        "storage_exists": storage_exists,
        "total_storage_bytes": total_size,
        "project_count": project_count,
        "embedding_model": "all-MiniLM-L6-v2",
        "embedding_dimensions": 384,
        "model_cached": model_cached,
        "model_cache_size_bytes": cache_size,
        "env_override": os.environ.get("GERDSEN_CHROMADB_PATH", None)
    }))


def main():
    parser = argparse.ArgumentParser(description="ChromaDB reporting for GerdsenAI research memory")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # report
    p_report = subparsers.add_parser("report", help="Detailed project report")
    p_report.add_argument("project_name", nargs="?", default=None, help="Project name")
    p_report.add_argument("--all", action="store_true", help="Report on all projects")
    p_report.set_defaults(func=cmd_report)

    # health
    p_health = subparsers.add_parser("health", help="System health check")
    p_health.set_defaults(func=cmd_health)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
