#!/usr/bin/env python3
# /// script
# requires-python = ">=3.8"
# dependencies = []
# ///
"""Validate a Claude Code MCP configuration file (.mcp.json, or a plugin.json's
"mcpServers" block).

Checks performed:
  - JSON syntax is well-formed.
  - The file resolves to a server-name -> server-config map (either the file's
    top-level object directly, as used in .mcp.json, or a top-level
    "mcpServers" object, as used in plugin.json).
  - Each server config has the fields required for its transport:
      * stdio  -- requires "command" (string); optional "args" (list of
        strings) and "env" (object of string -> string).
      * sse / http / ws (and the "streamable-http" alias for http) --
        require "url" (string) and an explicit "type"; optional "headers"
        (object of string -> string).
  - Flags insecure URLs: "http://" or "ws://" instead of "https://"/"wss://".
  - Flags the deprecated "sse" transport (Claude Code recommends "http").
  - Flags "${VAR}" references that look like Claude-provided variables
    (a "CLAUDE_*" name) but aren't among the documented set:
    CLAUDE_PLUGIN_ROOT, CLAUDE_PROJECT_DIR, CLAUDE_PLUGIN_DATA. Ordinary user
    environment variables (e.g. ${API_TOKEN}) are never flagged.

Output:
  - A single JSON document is written to stdout describing the result for
    every file passed on the command line.
  - Progress and human-readable diagnostics are written to stderr.

Exit codes:
  0  All files parsed and passed validation (no errors; warnings allowed
     unless --strict was given).
  1  At least one file parsed but failed validation (schema errors, or
     warnings while --strict was given).
  2  At least one file could not be read or was not valid JSON / did not
     resolve to a server map (parse error). Takes precedence over exit
     code 1 if both occur across multiple files.
  3  Usage error (bad arguments, no files given).

Examples:
  scripts/validate-mcp-config.py .mcp.json
  scripts/validate-mcp-config.py examples/*.json
  scripts/validate-mcp-config.py --strict .mcp.json
"""

import argparse
import json
import re
import sys
from typing import Any, Dict, List, Tuple

DOCUMENTED_CLAUDE_VARS = {
    "CLAUDE_PLUGIN_ROOT",
    "CLAUDE_PROJECT_DIR",
    "CLAUDE_PLUGIN_DATA",
}

STDIO_TYPES = {None, "stdio"}
REMOTE_TYPE_ALIASES = {
    "sse": "sse",
    "http": "http",
    "streamable-http": "http",
    "ws": "ws",
    "websocket": "ws",
}
DEPRECATED_TYPES = {"sse"}

VAR_PATTERN = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")

EXIT_OK = 0
EXIT_VALIDATION_FAILED = 1
EXIT_PARSE_ERROR = 2
EXIT_USAGE_ERROR = 3


def log(message: str) -> None:
    print(message, file=sys.stderr)


def find_vars(value: Any, found: List[str]) -> None:
    """Recursively collect ${VAR} references from strings nested in value."""
    if isinstance(value, str):
        found.extend(VAR_PATTERN.findall(value))
    elif isinstance(value, dict):
        for v in value.values():
            find_vars(v, found)
    elif isinstance(value, list):
        for v in value:
            find_vars(v, found)


def check_undocumented_claude_vars(config: Any) -> List[str]:
    found: List[str] = []
    find_vars(config, found)
    warnings = []
    seen = set()
    for var in found:
        if var in seen:
            continue
        seen.add(var)
        if var.startswith("CLAUDE_") and var not in DOCUMENTED_CLAUDE_VARS:
            warnings.append(
                f"references undocumented variable '${{{var}}}'; documented "
                f"Claude-provided variables are: "
                f"{', '.join(sorted(DOCUMENTED_CLAUDE_VARS))}"
            )
    return warnings


def is_insecure_url(url: str) -> bool:
    return url.startswith("http://") or url.startswith("ws://")


def validate_server(name: str, config: Any) -> Dict[str, Any]:
    errors: List[str] = []
    warnings: List[str] = []
    detected_type = None

    if not isinstance(config, dict):
        errors.append("server config must be a JSON object")
        return {
            "name": name,
            "type": None,
            "errors": errors,
            "warnings": warnings,
        }

    raw_type = config.get("type")
    has_command = "command" in config

    if raw_type is None and has_command:
        detected_type = "stdio"
    elif raw_type in STDIO_TYPES:
        detected_type = "stdio"
        if raw_type is not None and has_command is False:
            pass  # handled below as missing "command"
    elif raw_type in REMOTE_TYPE_ALIASES:
        detected_type = REMOTE_TYPE_ALIASES[raw_type]
        if raw_type in DEPRECATED_TYPES:
            warnings.append(
                "type 'sse' is deprecated; use type: \"http\" instead "
                "(see references/server-types.md)"
            )
    else:
        errors.append(
            f"unknown type '{raw_type}'; expected one of: stdio, http, "
            f"streamable-http, sse (deprecated), ws"
        )

    if detected_type == "stdio":
        command = config.get("command")
        if not command:
            errors.append("stdio servers require a non-empty 'command' string")
        elif not isinstance(command, str):
            errors.append("'command' must be a string")

        args = config.get("args")
        if args is not None and not (
            isinstance(args, list) and all(isinstance(a, str) for a in args)
        ):
            errors.append("'args' must be a list of strings")

        env = config.get("env")
        if env is not None and not (
            isinstance(env, dict)
            and all(isinstance(v, str) for v in env.values())
        ):
            errors.append("'env' must be an object mapping names to strings")

        if "url" in config:
            warnings.append(
                "stdio server config includes 'url', which is unused for "
                "this transport"
            )

    elif detected_type in ("http", "sse", "ws"):
        url = config.get("url")
        if not url:
            errors.append(f"{detected_type} servers require a non-empty 'url' string")
        elif not isinstance(url, str):
            errors.append("'url' must be a string")
        else:
            if is_insecure_url(url):
                scheme = "https://" if url.startswith("http://") else "wss://"
                errors.append(
                    f"insecure URL '{url}' -- use {scheme} instead of a "
                    f"plaintext connection"
                )

        headers = config.get("headers")
        if headers is not None and not (
            isinstance(headers, dict)
            and all(isinstance(v, str) for v in headers.values())
        ):
            errors.append("'headers' must be an object mapping names to strings")

        if "command" in config:
            errors.append(
                f"'{detected_type}' servers should not specify 'command' "
                f"(that field is only for stdio servers)"
            )

    warnings.extend(check_undocumented_claude_vars(config))

    return {
        "name": name,
        "type": detected_type,
        "errors": errors,
        "warnings": warnings,
    }


def extract_server_map(document: Any) -> Tuple[Dict[str, Any], str]:
    """Return (server_map, source_description) or raise ValueError."""
    if not isinstance(document, dict):
        raise ValueError("top-level JSON value must be an object")

    if "mcpServers" in document:
        servers = document["mcpServers"]
        if not isinstance(servers, dict):
            raise ValueError("'mcpServers' must be an object")
        return servers, "mcpServers"

    # .mcp.json style: the top-level object *is* the server map. Keys
    # starting with "_" are treated as documentation/comments, not servers.
    servers = {k: v for k, v in document.items() if not k.startswith("_")}
    return servers, "root"


def validate_file(path: str, strict: bool) -> Dict[str, Any]:
    result: Dict[str, Any] = {
        "file": path,
        "parse_error": None,
        "source": None,
        "servers": [],
        "valid": False,
    }

    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except OSError as exc:
        result["parse_error"] = f"could not read file: {exc}"
        log(f"[error] {path}: could not read file: {exc}")
        return result

    try:
        document = json.loads(text)
    except json.JSONDecodeError as exc:
        result["parse_error"] = f"invalid JSON: {exc}"
        log(f"[error] {path}: invalid JSON: {exc}")
        return result

    try:
        server_map, source = extract_server_map(document)
    except ValueError as exc:
        result["parse_error"] = str(exc)
        log(f"[error] {path}: {exc}")
        return result

    result["source"] = source
    log(f"[info] {path}: found {len(server_map)} server(s) via '{source}'")

    total_errors = 0
    total_warnings = 0
    for name, config in server_map.items():
        server_result = validate_server(name, config)
        result["servers"].append(server_result)
        total_errors += len(server_result["errors"])
        total_warnings += len(server_result["warnings"])
        for err in server_result["errors"]:
            log(f"[error] {path}: server '{name}': {err}")
        for warn in server_result["warnings"]:
            log(f"[warn]  {path}: server '{name}': {warn}")

    if len(server_map) == 0:
        log(f"[warn]  {path}: no servers found")

    result["valid"] = total_errors == 0 and not (strict and total_warnings > 0)
    return result


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="validate-mcp-config.py",
        description=(
            "Validate .mcp.json / mcpServers configuration files: JSON "
            "syntax, required fields per transport type, insecure URLs, "
            "and undocumented ${CLAUDE_*} variable references."
        ),
        epilog=(
            "Examples:\n"
            "  validate-mcp-config.py .mcp.json\n"
            "  validate-mcp-config.py examples/*.json\n"
            "  validate-mcp-config.py --strict .mcp.json\n\n"
            "Exit codes:\n"
            "  0  all files valid\n"
            "  1  at least one file failed validation\n"
            "  2  at least one file had a JSON parse / structure error\n"
            "  3  usage error"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="Path(s) to .mcp.json or plugin.json files to validate",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings (e.g. deprecated 'sse' transport) as failures",
    )
    args = parser.parse_args(argv)

    results = []
    had_parse_error = False
    had_validation_failure = False

    for path in args.files:
        result = validate_file(path, args.strict)
        results.append(result)
        if result["parse_error"] is not None:
            had_parse_error = True
        elif not result["valid"]:
            had_validation_failure = True

    summary = {
        "files_checked": len(results),
        "files_with_parse_errors": sum(
            1 for r in results if r["parse_error"] is not None
        ),
        "files_valid": sum(
            1 for r in results if r["parse_error"] is None and r["valid"]
        ),
        "files_invalid": sum(
            1
            for r in results
            if r["parse_error"] is None and not r["valid"]
        ),
    }

    output = {"results": results, "summary": summary, "strict": args.strict}
    print(json.dumps(output, indent=2))

    if had_parse_error:
        log("[fatal] one or more files had JSON parse/structure errors")
        return EXIT_PARSE_ERROR
    if had_validation_failure:
        log("[fatal] one or more files failed validation")
        return EXIT_VALIDATION_FAILED
    log("[info] all files valid")
    return EXIT_OK


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        log("[fatal] interrupted")
        sys.exit(EXIT_USAGE_ERROR)
