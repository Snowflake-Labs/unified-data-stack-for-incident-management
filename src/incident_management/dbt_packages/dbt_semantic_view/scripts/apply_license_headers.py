#!/usr/bin/env python3
# Copyright 2025 Snowflake Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import os
import sys
from typing import List, Tuple

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))

LICENSE_TEXT = (
    "Copyright 2025 Snowflake Inc. \n"
    "SPDX-License-Identifier: Apache-2.0\n"
    "\n"
    "Licensed under the Apache License, Version 2.0 (the \"License\");\n"
    "you may not use this file except in compliance with the License.\n"
    "You may obtain a copy of the License at\n"
    "\n"
    "http://www.apache.org/licenses/LICENSE-2.0\n"
    "\n"
    "Unless required by applicable law or agreed to in writing, software\n"
    "distributed under the License is distributed on an \"AS IS\" BASIS,\n"
    "WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n"
    "See the License for the specific language governing permissions and\n"
    "limitations under the License.\n"
)

SKIP_EXTENSIONS = {".json", ".csv"}
TARGET_EXTENSIONS = {".py", ".sql", ".yml", ".html"}

HEADER_SENTINEL = "SPDX-License-Identifier: Apache-2.0"


def format_comment_block_for_hash(text: str) -> str:
    lines = text.splitlines()
    commented = [f"# {line}" if line.strip() else "#" for line in lines]
    return "\n".join(commented) + "\n\n"


def format_comment_block_for_sql(text: str) -> str:
    lines = text.splitlines()
    commented = [f"-- {line}" if line.strip() else "--" for line in lines]
    return "\n".join(commented) + "\n\n"


def format_comment_block_for_html(text: str) -> str:
    return "<!--\n" + text + "-->\n\n"


def has_header(contents: str) -> bool:
    # Keep it simple: if the SPDX sentinel is anywhere in the first ~50 lines, assume present
    head = "\n".join(contents.splitlines()[:50])
    return HEADER_SENTINEL in head


def insert_after_shebang_and_encoding(lines: List[str]) -> int:
    idx = 0
    if idx < len(lines) and lines[idx].startswith("#!"):
        idx += 1
    # Handle encoding declaration (PEP 263)
    if idx < len(lines) and ("coding=" in lines[idx] or "coding:" in lines[idx]):
        idx += 1
    return idx


def insert_after_doctype(lines: List[str]) -> int:
    idx = 0
    # Keep XML prolog or doctype at very top
    while idx < len(lines) and lines[idx].lstrip().startswith(("<!DOCTYPE", "<?xml")):
        idx += 1
    return idx


def prepare_header_for_ext(ext: str) -> str:
    if ext in (".py", ".yml"):
        return format_comment_block_for_hash(LICENSE_TEXT)
    if ext == ".sql":
        return format_comment_block_for_sql(LICENSE_TEXT)
    if ext == ".html":
        return format_comment_block_for_html(LICENSE_TEXT)
    raise ValueError(f"Unsupported extension: {ext}")


def apply_header_to_file(path: str) -> Tuple[bool, str]:
    ext = os.path.splitext(path)[1].lower()
    if ext in SKIP_EXTENSIONS or ext not in TARGET_EXTENSIONS:
        return False, "skipped_ext"

    try:
        with open(path, "r", encoding="utf-8") as f:
            contents = f.read()
    except UnicodeDecodeError:
        return False, "binary_or_non_utf8"

    if has_header(contents):
        return False, "already_has_header"

    header = prepare_header_for_ext(ext)
    lines = contents.splitlines(keepends=True)

    insert_idx = 0
    if ext == ".py":
        insert_idx = insert_after_shebang_and_encoding(lines)
    elif ext == ".html":
        insert_idx = insert_after_doctype(lines)

    new_contents = "".join(lines[:insert_idx]) + header + "".join(lines[insert_idx:])

    with open(path, "w", encoding="utf-8") as f:
        f.write(new_contents)

    return True, "updated"


def should_skip_path(path: str) -> bool:
    # Skip common build artifacts or virtual envs if present
    parts = set(path.split(os.sep))
    skip_dirs = {".git", ".venv", "venv", "node_modules", "dist", "build", "__pycache__"}
    return not parts.isdisjoint(skip_dirs)


def main() -> int:
    root = REPO_ROOT
    changed = 0
    processed = 0
    skipped = 0
    for dirpath, dirnames, filenames in os.walk(root):
        # Prune skip directories
        dirnames[:] = [d for d in dirnames if not should_skip_path(os.path.join(dirpath, d))]
        for filename in filenames:
            path = os.path.join(dirpath, filename)
            # Don't modify this script file itself if extension matches
            if os.path.abspath(path) == os.path.abspath(__file__):
                continue
            ext = os.path.splitext(filename)[1].lower()
            if ext in SKIP_EXTENSIONS or ext in TARGET_EXTENSIONS:
                updated, reason = apply_header_to_file(path)
                if updated:
                    changed += 1
                else:
                    if reason != "skipped_ext":
                        skipped += 1
                processed += 1
    print(f"Processed: {processed}, Updated: {changed}, Skipped: {skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
