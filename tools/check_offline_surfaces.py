#!/usr/bin/env python3
"""Report potential runtime network surfaces in TARVOKA's Godot sources.

Static inspection only: a clean result does not prove zero network traffic.
Run: python3 tools/check_offline_surfaces.py .
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re

TOKENS = re.compile(
    r"\b(?:HTTPRequest|HTTPClient|WebSocketPeer|WebSocketMultiplayerPeer|"
    r"ENetMultiplayerPeer|PacketPeerUDP|TCPServer|StreamPeerTCP|UPNP|WebRTCPeerConnection|WebRTCDataChannel|PacketPeerDTLS|StreamPeerTLS|MultiplayerPeerExtension|MultiplayerAPI|SceneMultiplayer|MultiplayerSpawner|MultiplayerSynchronizer|ENetConnection|JavaScriptBridge)\b"
)
SHELL_EXEC = re.compile(r"\bOS\s*\.\s*(?:execute|create_process|create_instance)\s*\(")
SCENE_NODE = re.compile(r'^\s*\[node\b[^\]]*\btype="HTTPRequest"')
EXCLUDED = {".git", ".godot", ".import", "__pycache__"}


def scan(root: Path) -> list[str]:
    findings: list[str] = []
    for path in sorted(root.rglob("*")):
        # Never follow links outside the checkout (including links to other repos).
        # Resolve only candidate sources, avoiding unnecessary filesystem work.
        if path.suffix not in {".gd", ".tscn"}:
            continue
        if path.is_symlink():
            continue
        if not path.is_file():
            continue
        if any(part in EXCLUDED for part in path.relative_to(root).parts):
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError) as exc:
            findings.append(f"{path.relative_to(root)}: unreadable ({type(exc).__name__})")
            continue
        for number, line in enumerate(lines, 1):
            # Remove GDScript comments without mistaking # inside quoted strings
            # for a comment delimiter. This is a conservative lexical filter,
            # not a complete GDScript parser.
            code = []
            quote = None
            escaped = False
            for char in line:
                if quote is not None:
                    code.append(char)
                    if escaped:
                        escaped = False
                    elif char == "\\":
                        escaped = True
                    elif char == quote:
                        quote = None
                elif char in ("\u0027", '"'):
                    quote = char
                    code.append(char)
                elif char == "#":
                    break
                else:
                    code.append(char)
            line_to_check = "".join(code)
            if not line_to_check.strip() or line_to_check.lstrip().startswith(";"):
                continue
            # Strings containing documentation examples are not definitive proof
            # of network use; findings require manual review.
            if TOKENS.search(line_to_check) or SHELL_EXEC.search(line_to_check) or (path.suffix == ".tscn" and SCENE_NODE.search(line_to_check)):
                findings.append(f"{path.relative_to(root)}:{number}: {line.strip()[:180]}")
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".")
    parser.add_argument("--fail-on-findings", action="store_true",
                        help="Optional CI gate after existing findings are reviewed")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if not root.is_dir():
        parser.error("root must be an existing directory")
    findings = scan(root)
    for finding in findings:
        print(finding)
    print(f"Offline surface audit: {len(findings)} potential network references")
    return 1 if findings and args.fail_on_findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
