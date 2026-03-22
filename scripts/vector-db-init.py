#!/usr/bin/env python3
"""Unified vector DB initialization for GerdsenAI research memory.

Reads project settings and initializes the correct backend(s) for a given
context (research, sprint, redteam). Supports chromadb, pinecone, dual, or
none (in-context fallback) modes.

Usage:
    vector-db-init.py <settings-file> <context>

Context values:
    research    Research memory for deep-dive investigations
    sprint      Sprint/iteration working memory
    redteam     Red-team review findings

Settings it reads:
    vector_db_mode              chromadb | pinecone | dual | none (default: chromadb)
    vector_db_primary           chromadb | pinecone (default: chromadb, for dual mode)
    vector_db_sync_mode         mirror | primary-only (default: mirror, for dual mode)
    vector_db_collection_prefix Override auto-derived repo name prefix
    vector_db_chromadb_enabled  true | false (default: true)
    vector_db_pinecone_enabled  true | false (default: false)
    document_builder_path       Used to locate venv Python
"""

import json
import os
import re
import subprocess
import sys


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
    if isinstance(default, bool):
        return val.lower() in ("true", "yes", "1")
    if isinstance(default, int):
        try:
            return int(val)
        except ValueError:
            return default
    return val


# --- Backend Initialization ---

def get_script_dir():
    """Get the directory containing this script."""
    return os.path.dirname(os.path.abspath(__file__))


def derive_repo_name():
    """Derive a repository name from the current working directory basename."""
    cwd = os.getcwd()
    return os.path.basename(cwd).lower().replace(" ", "-")


def init_chromadb(collection_name):
    """Initialize a ChromaDB collection via chromadb-store.py interface.

    Returns a dict with collection info or error details.
    """
    # First check if chromadb is importable
    try:
        import chromadb
    except ImportError:
        return {
            "success": False,
            "error": "ChromaDB is not installed. Run: pip install chromadb"
        }

    script = os.path.join(get_script_dir(), "chromadb-store.py")
    if not os.path.isfile(script):
        return {
            "success": False,
            "error": f"chromadb-store.py not found at {script}"
        }

    try:
        cmd = [sys.executable, script, "init", collection_name]
        if settings_path:
            cmd.extend(["--settings", settings_path])
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            return {
                "collection": collection_name,
                "document_count": data.get("document_count", 0),
                "path": data.get("path", ""),
            }
        else:
            error_output = result.stdout or result.stderr
            try:
                error_data = json.loads(error_output)
                return {"success": False, "error": error_data.get("error", error_output)}
            except json.JSONDecodeError:
                return {"success": False, "error": error_output.strip()}
    except subprocess.TimeoutExpired:
        return {"success": False, "error": "ChromaDB init timed out after 30s"}
    except Exception as e:
        return {"success": False, "error": f"Failed to run chromadb-store.py: {e}"}


def init_pinecone(index_name, settings_path=None):
    """Initialize a Pinecone index via pinecone-store.py interface.

    Returns a dict with index info or error details.
    """
    # Check API key first
    if not os.environ.get("PINECONE_API_KEY"):
        return {
            "success": False,
            "error": "PINECONE_API_KEY environment variable is not set"
        }

    # Check if pinecone is importable
    try:
        from pinecone import Pinecone
    except ImportError:
        return {
            "success": False,
            "error": "Pinecone SDK is not installed. Run: pip install pinecone"
        }

    script = os.path.join(get_script_dir(), "pinecone-store.py")
    if not os.path.isfile(script):
        return {
            "success": False,
            "error": f"pinecone-store.py not found at {script}"
        }

    cmd = [sys.executable, script, "init", index_name]
    if settings_path:
        cmd.extend(["--settings", settings_path])

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            return {
                "index": index_name,
                "document_count": data.get("document_count", 0),
                "embedding_model": data.get("embedding_model", ""),
            }
        else:
            error_output = result.stdout or result.stderr
            try:
                error_data = json.loads(error_output)
                return {"success": False, "error": error_data.get("error", error_output)}
            except json.JSONDecodeError:
                return {"success": False, "error": error_output.strip()}
    except subprocess.TimeoutExpired:
        return {"success": False, "error": "Pinecone init timed out after 60s"}
    except Exception as e:
        return {"success": False, "error": f"Failed to run pinecone-store.py: {e}"}


# --- Main ---

def main():
    if len(sys.argv) < 3:
        print(json.dumps({
            "success": False,
            "error": "Usage: vector-db-init.py <settings-file> <context>"
        }))
        sys.exit(1)

    settings_path = sys.argv[1]
    context = sys.argv[2].lower()

    valid_contexts = ("research", "sprint", "redteam")
    if context not in valid_contexts:
        print(json.dumps({
            "success": False,
            "error": f"Invalid context '{context}'. Must be one of: {', '.join(valid_contexts)}"
        }))
        sys.exit(1)

    # Parse settings
    settings = parse_settings(settings_path)

    # Resolve mode
    mode = get_setting(settings, "vector_db_mode", "chromadb")
    primary = get_setting(settings, "vector_db_primary", "chromadb")
    sync_mode = get_setting(settings, "vector_db_sync_mode", "mirror")
    chromadb_enabled = get_setting(settings, "vector_db_chromadb_enabled", True)
    pinecone_enabled = get_setting(settings, "vector_db_pinecone_enabled", False)

    # Derive collection/index name
    prefix = get_setting(settings, "vector_db_collection_prefix", None)
    if not prefix:
        prefix = derive_repo_name()
    collection_name = f"{prefix}-{context}"

    # Mode "none" => in-context fallback
    if mode == "none":
        print(json.dumps({
            "success": True,
            "mode": "none",
            "backends": {},
            "primary": "in-context",
            "sync_mode": "none",
            "message": "Vector DB disabled. Using in-context memory only."
        }))
        return

    # Determine which backends to initialize based on mode
    do_chromadb = False
    do_pinecone = False

    if mode == "chromadb":
        do_chromadb = True
    elif mode == "pinecone":
        do_pinecone = True
    elif mode == "dual":
        do_chromadb = chromadb_enabled
        do_pinecone = pinecone_enabled
        # If dual but neither explicitly enabled, enable both
        if not do_chromadb and not do_pinecone:
            do_chromadb = True
            do_pinecone = True
    else:
        # Unknown mode, default to chromadb
        print(f"WARNING: Unknown vector_db_mode '{mode}', defaulting to chromadb",
              file=sys.stderr)
        mode = "chromadb"
        do_chromadb = True

    backends = {}
    errors = []

    # Initialize ChromaDB
    if do_chromadb:
        chromadb_result = init_chromadb(collection_name)
        if "success" in chromadb_result and not chromadb_result["success"]:
            errors.append(f"ChromaDB: {chromadb_result['error']}")
            backends["chromadb"] = chromadb_result
        else:
            backends["chromadb"] = chromadb_result

    # Initialize Pinecone
    if do_pinecone:
        pinecone_result = init_pinecone(collection_name, settings_path)
        if "success" in pinecone_result and not pinecone_result["success"]:
            errors.append(f"Pinecone: {pinecone_result['error']}")
            backends["pinecone"] = pinecone_result
        else:
            backends["pinecone"] = pinecone_result

    # Determine effective primary
    effective_primary = primary
    if mode != "dual":
        effective_primary = mode

    # If the chosen primary backend failed, fall back
    if effective_primary == "chromadb" and "chromadb" in backends:
        if backends["chromadb"].get("success") is False:
            if "pinecone" in backends and backends["pinecone"].get("success") is not False:
                effective_primary = "pinecone"
                print("WARNING: ChromaDB failed, falling back to Pinecone as primary",
                      file=sys.stderr)
    elif effective_primary == "pinecone" and "pinecone" in backends:
        if backends["pinecone"].get("success") is False:
            if "chromadb" in backends and backends["chromadb"].get("success") is not False:
                effective_primary = "chromadb"
                print("WARNING: Pinecone failed, falling back to ChromaDB as primary",
                      file=sys.stderr)

    # Check if all backends failed
    all_failed = all(
        b.get("success") is False
        for b in backends.values()
    )

    if all_failed and backends:
        print(json.dumps({
            "success": False,
            "mode": mode,
            "backends": backends,
            "errors": errors,
            "message": "All vector DB backends failed. Falling back to in-context memory."
        }))
        sys.exit(1)

    effective_sync = sync_mode if mode == "dual" else "none"

    print(json.dumps({
        "success": True,
        "mode": mode,
        "backends": backends,
        "primary": effective_primary,
        "sync_mode": effective_sync,
        "collection_name": collection_name,
        "context": context,
    }))


if __name__ == "__main__":
    main()
