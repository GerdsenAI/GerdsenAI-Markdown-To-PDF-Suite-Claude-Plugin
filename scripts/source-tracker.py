#!/usr/bin/env python3
"""Source Tracker for GerdsenAI Living Intelligence Reports.

Extracts source URLs from markdown report References sections,
computes content hashes for change detection, and manages
.sources.json manifest files alongside reports.

Usage:
    python source-tracker.py extract <report.md>       # Extract sources → .sources.json
    python source-tracker.py check <report.md>          # Check for stale sources
    python source-tracker.py update <report.md>         # Update hashes after refresh
    python source-tracker.py list-stale [directory]     # List all reports with stale sources
"""

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path


def extract_references(markdown_path: str) -> list[dict]:
    """Extract numbered references from a markdown file's Sources & References section."""
    with open(markdown_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Find the Sources & References section (or just References)
    ref_pattern = r"^##\s+(?:Sources\s*(?:&|and)\s*)?References\s*$"
    ref_match = re.search(ref_pattern, content, re.MULTILINE | re.IGNORECASE)
    if not ref_match:
        return []

    # Get text from References heading to next H2 or end of file
    ref_start = ref_match.end()
    next_h2 = re.search(r"^## ", content[ref_start:], re.MULTILINE)
    ref_text = content[ref_start:ref_start + next_h2.start()] if next_h2 else content[ref_start:]

    # Extract numbered references: [N] ... URL
    references = []
    # Match lines starting with [N]
    citation_pattern = r"^\[(\d+)\]\s+(.+)$"
    url_pattern = r"https?://[^\s\)\]\"'>]+"

    for match in re.finditer(citation_pattern, ref_text, re.MULTILINE):
        citation_num = int(match.group(1))
        citation_text = match.group(2).strip()

        # Extract URL from the citation text
        url_match = re.search(url_pattern, citation_text)
        url = url_match.group(0).rstrip(".,;") if url_match else None

        references.append({
            "citation_number": citation_num,
            "citation_text": citation_text,
            "url": url,
            "title": _extract_title(citation_text),
        })

    return references


def _extract_title(citation_text: str) -> str:
    """Extract a readable title from citation text."""
    # Try to find italicized title: *Title*
    italic_match = re.search(r"\*([^*]+)\*", citation_text)
    if italic_match:
        return italic_match.group(1)

    # Try to find quoted title: "Title"
    # Use curly quotes too
    quote_match = re.search(r'["\u201c]([^"\u201d]+)["\u201d]', citation_text)
    if quote_match:
        return quote_match.group(1)

    # Fall back to first 80 chars
    return citation_text[:80].strip()


def fetch_content_hash(url: str, timeout: int = 15) -> tuple[str | None, str]:
    """Fetch a URL and return (content_hash, status).

    Returns:
        (hash_string, "ok") on success
        (None, error_description) on failure
    """
    if not url:
        return None, "no_url"

    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "GerdsenAI-SourceTracker/1.0 (research-monitoring)",
        })
        with urllib.request.urlopen(req, timeout=timeout) as response:
            content = response.read()
            content_hash = hashlib.sha256(content).hexdigest()[:16]
            return content_hash, "ok"
    except urllib.error.HTTPError as e:
        return None, f"http_{e.code}"
    except urllib.error.URLError as e:
        return None, f"url_error: {e.reason}"
    except Exception as e:
        return None, f"error: {str(e)[:100]}"


def get_manifest_path(markdown_path: str) -> str:
    """Get the .sources.json path for a given markdown file."""
    base = os.path.splitext(markdown_path)[0]
    return base + ".sources.json"


def extract_command(markdown_path: str, fetch_hashes: bool = True) -> dict:
    """Extract sources from a report and create the manifest."""
    markdown_path = os.path.abspath(markdown_path)
    if not os.path.isfile(markdown_path):
        print(f"Error: File not found: {markdown_path}", file=sys.stderr)
        sys.exit(1)

    references = extract_references(markdown_path)
    if not references:
        print(json.dumps({
            "success": False,
            "error": "No Sources & References section found in the document",
            "report": markdown_path,
        }))
        sys.exit(1)

    now = datetime.now(timezone.utc).isoformat()
    sources = []

    for ref in references:
        source = {
            "citation_number": ref["citation_number"],
            "title": ref["title"],
            "citation_text": ref["citation_text"],
            "url": ref["url"],
            "accessed_date": now,
            "content_hash": None,
            "status": "no_url" if not ref["url"] else "pending",
        }

        if fetch_hashes and ref["url"]:
            content_hash, status = fetch_content_hash(ref["url"])
            source["content_hash"] = content_hash
            source["status"] = status

        sources.append(source)

    manifest = {
        "report": markdown_path,
        "monitored_since": now,
        "last_checked": now,
        "sources": sources,
    }

    manifest_path = get_manifest_path(markdown_path)
    with open(manifest_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=2)

    ok_count = sum(1 for s in sources if s["status"] == "ok")
    total_urls = sum(1 for s in sources if s["url"])

    result = {
        "success": True,
        "manifest_path": manifest_path,
        "total_sources": len(sources),
        "urls_found": total_urls,
        "urls_fetched": ok_count,
        "urls_failed": total_urls - ok_count,
    }
    print(json.dumps(result, indent=2))
    return manifest


def check_command(markdown_path: str) -> dict:
    """Check a monitored report for stale sources."""
    markdown_path = os.path.abspath(markdown_path)
    manifest_path = get_manifest_path(markdown_path)

    if not os.path.isfile(manifest_path):
        print(json.dumps({
            "success": False,
            "error": f"No manifest found. Run 'extract' first: {manifest_path}",
        }))
        sys.exit(1)

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    now = datetime.now(timezone.utc).isoformat()
    changed = []
    failed = []
    unchanged = []

    for source in manifest["sources"]:
        if not source.get("url"):
            continue

        new_hash, status = fetch_content_hash(source["url"])

        if status != "ok":
            source["status"] = status
            failed.append(source)
        elif source.get("content_hash") and new_hash != source["content_hash"]:
            source["previous_hash"] = source["content_hash"]
            source["content_hash"] = new_hash
            source["status"] = "changed"
            source["change_detected"] = now
            changed.append(source)
        else:
            source["status"] = "ok"
            unchanged.append(source)

    manifest["last_checked"] = now

    with open(manifest_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=2)

    # Find which sections are affected by changed sources
    affected_sections = _find_affected_sections(markdown_path, changed)

    result = {
        "success": True,
        "report": markdown_path,
        "last_checked": now,
        "total_sources": len(manifest["sources"]),
        "changed": len(changed),
        "unchanged": len(unchanged),
        "failed": len(failed),
        "changed_sources": [
            {"citation": s["citation_number"], "title": s["title"], "url": s["url"]}
            for s in changed
        ],
        "failed_sources": [
            {"citation": s["citation_number"], "title": s["title"], "status": s["status"]}
            for s in failed
        ],
        "affected_sections": affected_sections,
    }
    print(json.dumps(result, indent=2))
    return result


def _find_affected_sections(markdown_path: str, changed_sources: list[dict]) -> list[str]:
    """Find which report sections cite the changed sources."""
    if not changed_sources:
        return []

    with open(markdown_path, "r", encoding="utf-8") as f:
        content = f.read()

    affected = set()
    current_section = "Unknown"

    for line in content.split("\n"):
        # Track current H2 section
        h2_match = re.match(r"^## (.+)$", line)
        if h2_match:
            current_section = h2_match.group(1).strip()
            continue

        # Check if any changed citation number appears in this line
        for source in changed_sources:
            citation_marker = f"[{source['citation_number']}]"
            if citation_marker in line:
                affected.add(current_section)

    return sorted(affected)


def list_stale_command(directory: str = ".") -> list[dict]:
    """List all monitored reports with stale sources in a directory."""
    directory = os.path.abspath(directory)
    stale_reports = []

    for root, _dirs, files in os.walk(directory):
        for fname in files:
            if fname.endswith(".sources.json"):
                manifest_path = os.path.join(root, fname)
                try:
                    with open(manifest_path, "r", encoding="utf-8") as f:
                        manifest = json.load(f)

                    changed_count = sum(
                        1 for s in manifest.get("sources", [])
                        if s.get("status") == "changed"
                    )

                    if changed_count > 0:
                        stale_reports.append({
                            "report": manifest.get("report", manifest_path),
                            "manifest": manifest_path,
                            "stale_sources": changed_count,
                            "total_sources": len(manifest.get("sources", [])),
                            "last_checked": manifest.get("last_checked", "unknown"),
                        })
                except (json.JSONDecodeError, KeyError):
                    continue

    result = {
        "success": True,
        "directory": directory,
        "stale_reports": stale_reports,
        "total_stale": len(stale_reports),
    }
    print(json.dumps(result, indent=2))
    return stale_reports


def update_command(markdown_path: str) -> dict:
    """Re-extract sources and update hashes (after a report refresh)."""
    markdown_path = os.path.abspath(markdown_path)
    manifest_path = get_manifest_path(markdown_path)

    if not os.path.isfile(manifest_path):
        # No existing manifest — just extract fresh
        return extract_command(markdown_path, fetch_hashes=True)

    # Re-extract and re-hash, preserving monitored_since
    with open(manifest_path, "r", encoding="utf-8") as f:
        old_manifest = json.load(f)

    monitored_since = old_manifest.get("monitored_since")

    manifest = extract_command(markdown_path, fetch_hashes=True)

    # Restore original monitoring date
    if monitored_since:
        with open(manifest_path, "r", encoding="utf-8") as f:
            new_manifest = json.load(f)
        new_manifest["monitored_since"] = monitored_since
        with open(manifest_path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(new_manifest, f, indent=2)

    return manifest


def main():
    parser = argparse.ArgumentParser(
        description="GerdsenAI Source Tracker — monitor report source freshness"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # extract
    p_extract = subparsers.add_parser("extract", help="Extract sources and create manifest")
    p_extract.add_argument("report", help="Path to markdown report")
    p_extract.add_argument("--no-fetch", action="store_true", help="Skip fetching content hashes")

    # check
    p_check = subparsers.add_parser("check", help="Check for stale sources")
    p_check.add_argument("report", help="Path to markdown report")

    # update
    p_update = subparsers.add_parser("update", help="Update manifest after report refresh")
    p_update.add_argument("report", help="Path to markdown report")

    # list-stale
    p_list = subparsers.add_parser("list-stale", help="List reports with stale sources")
    p_list.add_argument("directory", nargs="?", default=".", help="Directory to scan")

    args = parser.parse_args()

    if args.command == "extract":
        extract_command(args.report, fetch_hashes=not args.no_fetch)
    elif args.command == "check":
        check_command(args.report)
    elif args.command == "update":
        update_command(args.report)
    elif args.command == "list-stale":
        list_stale_command(args.directory)


if __name__ == "__main__":
    main()
