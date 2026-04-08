#!/bin/bash
# Fixture generators for MultiTUI e2e tests

set -Eeuo pipefail

FIXTURE_DIR="${FIXTURE_DIR:-/tmp/mtui-test-fixtures}"

init_git_repo() {
    local dir="$1"
    git init -q "$dir"
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "Test User"
}

create_minimal_js() {
    local dir="$1"
    mkdir -p "$dir"
    init_git_repo "$dir"

    cat > "$dir/package.json" << 'INNER'
{
  "name": "test-js-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest run"
  },
  "devDependencies": {
    "vite": "^5.4.0",
    "vitest": "^2.0.0"
  }
}
INNER

    cat > "$dir/index.js" << 'INNER'
export function add(a, b) { return a + b; }
INNER

    echo "$dir"
}

create_minimal_py() {
    local dir="$1"
    mkdir -p "$dir"
    init_git_repo "$dir"

    cat > "$dir/pyproject.toml" << 'INNER'
[project]
name = "test-py-project"
version = "1.0.0"
requires-python = ">=3.13"
dependencies = []

[project.optional-dependencies]
dev = ["pytest>=8.0.0"]

[tool.pytest.ini_options]
testpaths = ["tests"]
INNER

    cat > "$dir/main.py" << 'INNER'
def add(a: int, b: int) -> int:
    return a + b
INNER

    mkdir -p "$dir/tests"
    touch "$dir/tests/__init__.py"
    cat > "$dir/tests/test_main.py" << 'INNER'
from main import add

def test_add():
    assert add(2, 3) == 5
INNER

    echo "$dir"
}
