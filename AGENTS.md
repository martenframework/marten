# Marten Codebase Guide for AI Coding Agents

This is the codebase of **Marten**, a batteries-included web framework for Crystal.

For the full contributor guide (development environment, test project setup, security reporting), see [docs/docs/the-marten-project/contributing.md](docs/docs/the-marten-project/contributing.md).

## Architecture Overview

Marten is a **single unified codebase**. All production code lives under `src/marten/` and mirrors the public API surface.

| Module | Path | Responsibility |
|--------|------|----------------|
| **Database / ORM** | `src/marten/db/` | Models, queries, migrations, schema editors, field types |
| **Handlers** | `src/marten/handlers/` | Request processing, generic CRUD handlers, defaults |
| **HTTP** | `src/marten/http/` | Requests, responses, cookies, sessions, flash |
| **Routing** | `src/marten/routing/` | URL maps, route parameters, reverse URL resolution |
| **Templates** | `src/marten/template/` | Template engine, tags, filters, loaders |
| **Schemas** | `src/marten/schema/` | Form validation and bound fields |
| **Middleware** | `src/marten/middleware/` | Request/response pipeline |
| **Emailing** | `src/marten/emailing/` | Email backends and delivery |
| **Cache** | `src/marten/cache/` | Cache stores |
| **Assets** | `src/marten/asset/` | Asset pipeline |
| **CLI** | `src/marten/cli/` | Generators, management commands, project scaffolding |
| **Configuration** | `src/marten/conf/` | Settings and environment configuration |
| **Core** | `src/marten/core/` | Validators, storage, shared utilities |
| **Apps** | `src/marten/apps/` | App registry and associations |
| **Server** | `src/marten/server/` | HTTP server integration |
| **Spec helpers** | `src/marten/spec/` | Test client and framework spec utilities |
| **Locales** | `src/marten/locales/` | I18n translations |

Entry points:

- `src/marten.cr` — main framework require
- `src/marten_cli.cr` — CLI binary (`crystal build src/marten_cli.cr -o bin/marten`)

**Key principle**: framework specs (`spec/` at repo root) test the framework itself. User-facing testing docs under `docs/docs/development/testing.md` describe how **applications** test against Marten — do not confuse the two.

The framework spec suite bootstraps an internal test project defined in `spec/test_project/` (configured via `spec/test_project.cr` and `.spec.env.json`).

## Testing Commands

Framework specs use Crystal's built-in [`spec`](https://crystal-lang.org/reference/guides/testing.html) module.

### Run the full suite

```bash
make tests          # equivalent to: crystal spec --error-trace
```

### Run a subset

```bash
crystal spec spec/marten/template/tag_spec.cr
crystal spec spec/marten/db/
crystal spec spec/marten/handlers/record_list_spec.cr:41   # specific example (line of the `it` block)
```

### Database backends

By default, specs run against an **in-memory SQLite** database. To test against other backends:

```bash
MARTEN_SPEC_DB_CONNECTION=postgresql make tests
MARTEN_SPEC_DB_CONNECTION=mysql make tests
MARTEN_SPEC_DB_CONNECTION=mariadb make tests
```

Backend credentials are configured in `.spec.env.json` (generated from `.spec.env.json.example` by `make init`). Each non-SQLite backend requires **two database names** per backend — specs cover multi-database configurations.

### Batched specs (CI-style, lower memory)

Compiling the full suite in one process can require a lot of memory. CI runs specs in batches:

```bash
scripts/run_batched_specs
```

The `MARTEN_SPEC_DB_CONNECTION` environment variable works with this script as well.

### Spec helpers and macros

- Top-level helper: `spec/spec_helper.cr` — sets `MARTEN_ENV=test`, requires framework and test project
- Nested helpers: `spec/marten/**/spec_helper.cr` — each requires the helper from its parent directory
- Backend-specific helpers: `for_postgresql`, `for_mysql`, `for_mariadb_only`, `for_sqlite`, etc. (defined in `spec/spec_helper.cr`)
- Common testing macros (defined in `spec/spec_helper.cr`):
  - `with_overridden_setting(setting_name, value) { ... }` — temporarily override a Marten setting
  - `with_installed_apps(*apps) { ... }` — register additional apps for a spec
  - `with_main_app_location(location) { ... }` — override the main app location

**Requires libvips** to compile the spec suite. Supported Crystal versions are listed in the [release notes for the version under development](docs/docs/the-marten-project/release-notes.md).

## Quality Assurance

```bash
make qa              # format checks + ameba + typos
make lint            # ameba only (config: .ameba.yml)
make format_checks   # crystal tool format --check
make format          # apply crystal tool format (excludes tmp/)
make typos           # spelling checks (requires typos CLI)
```

Follow [Crystal's style guide](https://crystal-lang.org/reference/conventions/coding_style.html). CI runs these checks on every pull request.

## Code Conventions

### Spec files

- Live in `spec/` at the repo root, mirroring `src/marten/` structure
- Named `*_spec.cr`
- Always require the appropriate `spec_helper.cr`
- Use descriptive example names: `it "returns the expected redirect response"`

### User-facing changes

When adding or changing user-visible behavior:

1. Add specs in `spec/marten/<module>/`
2. Update the relevant guide in `docs/docs/`
3. Add an entry to the release notes file for the version under development (see [release notes index](docs/docs/the-marten-project/release-notes.md))

### Documentation

- **User guides**: `docs/docs/` (Docusaurus, live preview via `cd docs && npm run start`)
- **API reference**: generated with `make docs_api` → `docs/static/api/dev/`
- **Versioned docs**: `docs/versioned_docs/` — update `docs/docs/` for the current development version; versioned snapshots are maintained separately

## Common Development Workflows

### Finding related code

| Task | Where to look |
|------|---------------|
| Model / query behavior | `src/marten/db/` + `spec/marten/db/` |
| Handler changes | `src/marten/handlers/` + `spec/marten/handlers/` |
| Route / URL behavior | `src/marten/routing/` + `spec/marten/routing/` |
| Template tags / filters | `src/marten/template/tag/`, `src/marten/template/filter/` |
| Form validation | `src/marten/schema/` + `spec/marten/schema/` |
| Settings / configuration | `src/marten/conf/` + `spec/marten/conf/` |
| CLI / generators | `src/marten/cli/` + `spec/marten/cli/` |
| Middleware | `src/marten/middleware/` + `spec/marten/middleware/` |

When fixing behavior in one area, grep for similar patterns in the same module directory before implementing.

### Local test project

To exercise changes against a real Marten application:

```bash
crystal build src/marten_cli.cr -o bin/marten
./bin/marten new project test-project
```

Point the test project at your local checkout via `shard.override.yml` (see the [contributing guide](docs/docs/the-marten-project/contributing.md#setting-up-a-test-project-with-marten)).

### Initialization

```bash
make init           # default target; also runnable as: make
```

Installs Crystal shards, Node.js dependencies (for docs), and generates `.spec.env.json`. Requires Node.js and libvips on your system (see the [contributing guide](docs/docs/the-marten-project/contributing.md#development-environment)).

## Issue References and Pull Requests

- Reference issue numbers in commits when applicable
- Do not open GitHub issues for security vulnerabilities — email `security@martenframework.com`
- Pull requests should include specs; CI must pass (`.github/workflows/specs.yml`, `.github/workflows/qa.yml`)

## File Organization

```
src/marten/     Production code
spec/           Framework specs (NOT application specs)
docs/           Docusaurus documentation site
lib/            Vendored shards and tools (ameba, timecop, etc.)
scripts/        Development scripts (batched specs, etc.)
```
