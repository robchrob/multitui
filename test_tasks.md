# Test Implementation Tasks

## Status Legend
- [ ] Not started
- [ ] In progress
- [x] Completed

## Phase 1: Infrastructure

### 1.1 Directory Structure
- [x] Create `tests/e2e/lib/` directory
- [x] Create `tests/e2e/test/` directory
- [x] Create `tests/e2e/README.md`

### 1.2 Helper Libraries
- [x] `tests/e2e/lib/docker.sh` - Docker test helpers
- [x] `tests/e2e/lib/mtui.sh` - mtui CLI wrapper
- [x] `tests/e2e/lib/opencode.sh` - OpenCode helpers
- [x] `tests/e2e/lib/fixtures.sh` - Fixture generators

### 1.3 Test Runner
- [x] `tests/e2e/test/run.sh` - Master test runner

## Phase 2: Core Tests

### 2.1 Setup Tests
- [x] `tests/e2e/test/mtui_setup.sh` - Global installation tests
  - [x] setup_install
  - [x] setup_links

### 2.2 Build Tests
- [x] `tests/e2e/test/mtui_build.sh` - Docker image build tests
  - [x] build_image
  - [x] build_cached
  - [x] build_no_cache

### 2.3 Container Tests
- [x] `tests/e2e/test/mtui_container.sh` - Container lifecycle tests
  - [x] container_start
  - [x] container_status
  - [x] container_list
  - [x] container_stop

## Phase 3: Workflow Tests

### 3.1 Init Tests
- [x] `tests/e2e/test/mtui_init.sh` - Project init tests (JS/Python)
  - [x] init_js_project
  - [x] init_py_project
  - [x] init_agents_md
  - [x] init_dockerfile
  - [x] init_compose

### 3.2 Bootstrap Tests
- [x] `tests/e2e/test/mtui_bootstrap.sh` - Project bootstrap tests
  - [x] bootstrap_js
  - [x] bootstrap_py
  - [x] bootstrap_agents_md

### 3.3 OpenCode Tests
- [x] `tests/e2e/test/mtui_opencode.sh` - OpenCode flow tests
  - [x] opencode_starts
  - [x] opencode_tools
  - [x] opencode_mcp

## Phase 4: Documentation

### 4.1 Documentation
- [x] Update `tests/e2e/README.md` with execution instructions
- [x] Document environment requirements

## Dependencies

- [x] Docker daemon running
- [ ] `OPENROUTER_API_KEY` set (required for AI tests)
- [ ] `GITHUB_TOKEN` (optional)
- [ ] `EXA_API_KEY` (optional)

## Files Created

```
tests/e2e/
├── lib/
│   ├── docker.sh          # Docker helpers (105 lines)
│   ├── mtui.sh            # mtui CLI wrapper (105 lines)
│   ├── fixtures.sh        # Fixture generators (155 lines)
│   └── opencode.sh        # OpenCode helpers (95 lines)
├── test/
│   ├── run.sh             # Master runner (110 lines)
│   ├── mtui_setup.sh      # Setup tests (75 lines)
│   ├── mtui_build.sh      # Build tests (105 lines)
│   ├── mtui_init.sh       # Init tests (125 lines)
│   ├── mtui_bootstrap.sh # Bootstrap tests (115 lines)
│   ├── mtui_container.sh # Container tests (145 lines)
│   └── mtui_opencode.sh  # OpenCode tests (165 lines)
└── README.md              # Test documentation
```

## Usage

```bash
# Run all tests
tests/e2e/test/run.sh

# Run specific test
tests/e2e/test/mtui_build.sh

# With verbose
MTUI_TEST_VERBOSE=1 tests/e2e/test/run.sh
```

## Notes

- All tests are ephemeral - cleanup after each test
- Use temporary directories for isolation
- Generate fixtures on-the-fly (not pre-built)
- Test both JavaScript/bun and Python/uv stacks
