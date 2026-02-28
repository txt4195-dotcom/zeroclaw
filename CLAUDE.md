# CLAUDE.md — ZeroClaw Agent Engineering Protocol

This file defines the default working protocol for Claude agents in this repository.
Scope: entire repository.

## 1) Project Snapshot (Read First)

ZeroClaw is a Rust-first autonomous agent runtime optimized for:

- high performance
- high efficiency
- high stability
- high extensibility
- high sustainability
- high security

Core architecture is trait-driven and modular. Most extension work should be done by implementing traits and registering in factory modules.

Key extension points:

- `src/providers/traits.rs` (`Provider`)
- `src/channels/traits.rs` (`Channel`)
- `src/tools/traits.rs` (`Tool`)
- `src/memory/traits.rs` (`Memory`)
- `src/observability/traits.rs` (`Observer`)
- `src/runtime/traits.rs` (`RuntimeAdapter`)
- `src/peripherals/traits.rs` (`Peripheral`) — hardware boards (STM32, RPi GPIO)

## 2) Deep Architecture Observations (Why This Protocol Exists)

These codebase realities should drive every design decision:

1. **Trait + factory architecture is the stability backbone**
    - Extension points are intentionally explicit and swappable.
    - Most features should be added via trait implementation + factory registration, not cross-cutting rewrites.
2. **Security-critical surfaces are first-class and internet-adjacent**
    - `src/gateway/`, `src/security/`, `src/tools/`, `src/runtime/` carry high blast radius.
    - Defaults already lean secure-by-default (pairing, bind safety, limits, secret handling); keep it that way.
3. **Performance and binary size are product goals, not nice-to-have**
    - `Cargo.toml` release profile and dependency choices optimize for size and determinism.
    - Convenience dependencies and broad abstractions can silently regress these goals.
4. **Config and runtime contracts are user-facing API**
    - `src/config/schema.rs` and CLI commands are effectively public interfaces.
    - Backward compatibility and explicit migration matter.
5. **The project now runs in high-concurrency collaboration mode**
    - CI + docs governance + label routing are part of the product delivery system.
    - PR throughput is a design constraint; not just a maintainer inconvenience.

## 3) Engineering Principles (Normative)

These principles are mandatory by default. They are not slogans; they are implementation constraints.

### 3.1 KISS (Keep It Simple, Stupid)

**Why here:** Runtime + security behavior must stay auditable under pressure.

Required:

- Prefer straightforward control flow over clever meta-programming.
- Prefer explicit match branches and typed structs over hidden dynamic behavior.
- Keep error paths obvious and localized.

### 3.2 YAGNI (You Aren't Gonna Need It)

**Why here:** Premature features increase attack surface and maintenance burden.

Required:

- Do not add new config keys, trait methods, feature flags, or workflow branches without a concrete accepted use case.
- Do not introduce speculative “future-proof” abstractions without at least one current caller.
- Keep unsupported paths explicit (error out) rather than adding partial fake support.

### 3.3 DRY + Rule of Three

**Why here:** Naive DRY can create brittle shared abstractions across providers/channels/tools.

Required:

- Duplicate small, local logic when it preserves clarity.
- Extract shared utilities only after repeated, stable patterns (rule-of-three).
- When extracting, preserve module boundaries and avoid hidden coupling.

### 3.4 SRP + ISP (Single Responsibility + Interface Segregation)

**Why here:** Trait-driven architecture already encodes subsystem boundaries.

Required:

- Keep each module focused on one concern.
- Extend behavior by implementing existing narrow traits whenever possible.
- Avoid fat interfaces and “god modules” that mix policy + transport + storage.

### 3.5 Fail Fast + Explicit Errors

**Why here:** Silent fallback in agent runtimes can create unsafe or costly behavior.

Required:

- Prefer explicit `bail!`/errors for unsupported or unsafe states.
- Never silently broaden permissions/capabilities.
- Document fallback behavior when fallback is intentional and safe.

### 3.6 Secure by Default + Least Privilege

**Why here:** Gateway/tools/runtime can execute actions with real-world side effects.

Required:

- Deny-by-default for access and exposure boundaries.
- Never log secrets, raw tokens, or sensitive payloads.
- Keep network/filesystem/shell scope as narrow as possible unless explicitly justified.

### 3.7 Determinism + Reproducibility

**Why here:** Reliable CI and low-latency triage depend on deterministic behavior.

Required:

- Prefer reproducible commands and locked dependency behavior in CI-sensitive paths.
- Keep tests deterministic (no flaky timing/network dependence without guardrails).
- Ensure local validation commands map to CI expectations.

### 3.8 Reversibility + Rollback-First Thinking

**Why here:** Fast recovery is mandatory under high PR volume.

Required:

- Keep changes easy to revert (small scope, clear blast radius).
- For risky changes, define rollback path before merge.
- Avoid mixed mega-patches that block safe rollback.

## 4) Repository Map (High-Level)

- `src/main.rs` — CLI entrypoint and command routing
- `src/lib.rs` — module exports and shared command enums
- `src/config/` — schema + config loading/merging
- `src/agent/` — orchestration loop
- `src/gateway/` — webhook/gateway server
- `src/security/` — policy, pairing, secret store
- `src/memory/` — markdown/sqlite memory backends + embeddings/vector merge
- `src/providers/` — model providers and resilient wrapper
- `src/channels/` — Telegram/Discord/Slack/etc channels
- `src/tools/` — tool execution surface (shell, file, memory, browser)
- `src/peripherals/` — hardware peripherals (STM32, RPi GPIO); see `docs/hardware-peripherals-design.md`
- `src/runtime/` — runtime adapters (currently native)
- `docs/` — task-oriented documentation system (hubs, unified TOC, references, operations, security proposals, multilingual guides)
- `.github/` — CI, templates, automation workflows

## 4.1 Documentation System Contract (Required)

Treat documentation as a first-class product surface, not a post-merge artifact.

Canonical entry points:

- repository landing + localized hubs: `README.md`, `docs/i18n/zh-CN/README.md`, `docs/i18n/ja/README.md`, `docs/i18n/ru/README.md`, `docs/i18n/fr/README.md`, `docs/i18n/vi/README.md`, `docs/i18n/el/README.md`
- docs hubs: `docs/README.md`, `docs/i18n/zh-CN/README.md`, `docs/i18n/ja/README.md`, `docs/i18n/ru/README.md`, `docs/i18n/fr/README.md`, `docs/i18n/vi/README.md`, `docs/i18n/el/README.md`
- unified TOC: `docs/SUMMARY.md`
- i18n governance docs: `docs/i18n-guide.md`, `docs/i18n/README.md`, `docs/i18n-coverage.md`

Supported locales (current contract):

- `en`, `zh-CN`, `ja`, `ru`, `fr`, `vi`, `el`

Collection indexes (category navigation):

- `docs/getting-started/README.md`
- `docs/reference/README.md`
- `docs/operations/README.md`
- `docs/security/README.md`
- `docs/hardware/README.md`
- `docs/contributing/README.md`
- `docs/project/README.md`

Runtime-contract references (must track behavior changes):

- `docs/commands-reference.md`
- `docs/providers-reference.md`
- `docs/channels-reference.md`
- `docs/config-reference.md`
- `docs/operations-runbook.md`
- `docs/troubleshooting.md`
- `docs/one-click-bootstrap.md`

Required docs governance rules:

- Keep README/hub top navigation and quick routes intuitive and non-duplicative.
- Keep entry-point parity across all supported locales (`en`, `zh-CN`, `ja`, `ru`, `fr`, `vi`, `el`) when changing navigation architecture.
- If a change touches docs IA, runtime-contract references, or user-facing wording in shared docs, perform i18n follow-through for currently supported locales in the same PR:
  - Update locale navigation links (`README*`, `docs/README*`, `docs/SUMMARY.md`).
  - Update canonical locale hubs and summaries under `docs/i18n/<locale>/` for every supported locale.
  - Update localized runtime-contract docs where equivalents exist (currently full trees for `vi` and `el`; do not regress `zh-CN`/`ja`/`ru`/`fr` hub parity).
  - Keep `docs/*.<locale>.md` compatibility shims aligned if present.
- Follow `docs/i18n-guide.md` as the mandatory completion checklist when docs navigation or shared wording changes.
- Keep proposal/roadmap docs explicitly labeled; avoid mixing proposal text into runtime-contract docs.
- Keep project snapshots date-stamped and immutable once superseded by a newer date.

### 4.2 Docs i18n Completion Gate (Required)

For any PR that changes docs IA, locale navigation, or shared docs wording:

1. Complete i18n follow-through in the same PR using `docs/i18n-guide.md`.
2. Keep all supported locale hubs/summaries navigable through canonical `docs/i18n/<locale>/` paths.
3. Update `docs/i18n-coverage.md` when coverage status or locale topology changes.
4. If any translation must be deferred, record explicit owner + follow-up issue/PR in the PR description.

## 5) Risk Tiers by Path (Review Depth Contract)

Use these tiers when deciding validation depth and review rigor.

- **Low risk**: docs/chore/tests-only changes
- **Medium risk**: most `src/**` behavior changes without boundary/security impact
- **High risk**: `src/security/**`, `src/runtime/**`, `src/gateway/**`, `src/tools/**`, `.github/workflows/**`, access-control boundaries

When uncertain, classify as higher risk.

## 6) Agent Workflow (Required)

1. **Read before write**
    - Inspect existing module, factory wiring, and adjacent tests before editing.
2. **Define scope boundary**
    - One concern per PR; avoid mixed feature+refactor+infra patches.
3. **Implement minimal patch**
    - Apply KISS/YAGNI/DRY rule-of-three explicitly.
4. **Validate by risk tier**
    - Docs-only: lightweight checks.
    - Code/risky changes: full relevant checks and focused scenarios.
5. **Document impact**
    - Update docs/PR notes for behavior, risk, side effects, and rollback.
    - If CLI/config/provider/channel behavior changed, update corresponding runtime-contract references.
    - If docs entry points changed, keep all supported locale README/docs-hub navigation aligned (`en`, `zh-CN`, `ja`, `ru`, `fr`, `vi`, `el`).
    - Run through `docs/i18n-guide.md` and record any explicit i18n deferrals in the PR summary.
6. **Respect queue hygiene**
    - If stacked PR: declare `Depends on #...`.
    - If replacing old PR: declare `Supersedes #...`.

### 6.1 Branch / Commit / PR Flow (Required)

All contributors (human or agent) must follow the same collaboration flow:

- Create and work from a non-`main` branch.
- Commit changes to that branch with clear, scoped commit messages.
- Open a PR to `main` by default (`dev` is optional for integration batching); do not push directly to `dev` or `main`.
- `main` accepts direct PR merges after required checks and review policy pass.
- Wait for required checks and review outcomes before merging.
- Merge via PR controls (squash/rebase/merge as repository policy allows).
- After merge/close, clean up task branches/worktrees that are no longer needed.
- Keep long-lived branches only when intentionally maintained with clear owner and purpose.

### 6.1A PR Disposition and Workflow Authority (Required)

- Decide merge/close outcomes from repository-local authority in this order: `.github/workflows/**`, GitHub branch protection/rulesets, `docs/pr-workflow.md`, then this `CLAUDE.md`.
- External agent skills/templates are execution aids only; they must not override repository-local policy.
- A normal contributor PR targeting `main` is valid under the main-first flow when required checks and review policy are satisfied; use `dev` only for explicit integration batching.
- Direct-close the PR (do not supersede/replay) when high-confidence integrity-risk signals exist:
  - unapproved or unrelated repository rebranding attempts (for example replacing project logo/identity assets)
  - unauthorized platform-surface expansion (for example introducing `web` apps, dashboards, frontend stacks, or UI surfaces not requested by maintainers)
  - title/scope deception that hides high-risk code changes (for example `docs:` title with broad `src/**` changes)
  - spam-like or intentionally harmful payload patterns
  - multi-domain dirty-bundle changes with no safe, auditable isolation path
- If unauthorized platform-surface expansion is detected during review/implementation, report to maintainers immediately and pause further execution until explicit direction is given.
- Use supersede flow only when maintainers explicitly want to preserve valid work and attribution.
- In public PR close/block comments, state only direct actionable reasons; do not include internal decision-process narration or "non-reason" qualifiers.

### 6.1B Assignee-First Gate (Required)

- For any GitHub issue or PR selected for active handling, the first action is to ensure `@chumyin` is an assignee.
- This is additive ownership: keep existing assignees and add `@chumyin` if missing.
- Do not start triage/review/implementation/merge work before assignee assignment is confirmed.
- Queue safety rule: assign only the currently active target; do not pre-assign future queued targets.

### 6.2 Worktree Workflow (Required for All Task Streams)

Use Git worktrees to isolate every active task stream safely and predictably:

- Use one dedicated worktree per active branch/PR stream; do not implement directly in a shared default workspace.
- Keep each worktree on a single branch and a single concern; do not mix unrelated edits in one worktree.
- Before each commit/push, verify commit hygiene in that worktree (`git status --short` and `git diff --cached`) so only scoped files are included.
- Run validation commands inside the corresponding worktree before commit/PR.
- Name worktrees clearly by scope (for example: `wt/ci-hardening`, `wt/provider-fix`).
- After PR merge/close (or task abandonment), remove stale worktrees/branches and prune refs (`git worktree prune`, `git fetch --prune`).
- Local Codex automation may use one-command cleanup helper: `~/.codex/skills/zeroclaw-pr-issue-automation/scripts/cleanup_track.sh --repo-dir <repo_dir> --worktree <worktree_path> --branch <branch_name>`.
- PR checkpoint rules from section 6.1 still apply to worktree-based development.

### 6.3 Code Naming Contract (Required)

Apply these naming rules for all code changes unless a subsystem has a stronger existing pattern.

- Use Rust standard casing consistently: modules/files `snake_case`, types/traits/enums `PascalCase`, functions/variables `snake_case`, constants/statics `SCREAMING_SNAKE_CASE`.
- Name types and modules by domain role, not implementation detail (for example `DiscordChannel`, `SecurityPolicy`, `MemoryStore` over vague names like `Manager`/`Helper`).
- Keep trait implementer naming explicit and predictable: `<ProviderName>Provider`, `<ChannelName>Channel`, `<ToolName>Tool`, `<BackendName>Memory`.
- Keep factory registration keys stable, lowercase, and user-facing (for example `"openai"`, `"discord"`, `"shell"`), and avoid alias sprawl without migration need.
- Name tests by behavior/outcome (`<subject>_<expected_behavior>`) and keep fixture identifiers neutral/project-scoped.
- If identity-like naming is required in tests/examples, use ZeroClaw-native labels only (`ZeroClawAgent`, `zeroclaw_user`, `zeroclaw_node`).

### 6.4 Architecture Boundary Contract (Required)

Use these rules to keep the trait/factory architecture stable under growth.

- Extend capabilities by adding trait implementations + factory wiring first; avoid cross-module rewrites for isolated features.
- Keep dependency direction inward to contracts: concrete integrations depend on trait/config/util layers, not on other concrete integrations.
- Avoid creating cross-subsystem coupling (for example provider code importing channel internals, tool code mutating gateway policy directly).
- Keep module responsibilities single-purpose: orchestration in `agent/`, transport in `channels/`, model I/O in `providers/`, policy in `security/`, execution in `tools/`.
- Introduce new shared abstractions only after repeated use (rule-of-three), with at least one real caller in current scope.
- For config/schema changes, treat keys as public contract: document defaults, compatibility impact, and migration/rollback path.

## 7) Change Playbooks

### 7.1 Adding a Provider

- Implement `Provider` in `src/providers/`.
- Register in `src/providers/mod.rs` factory.
- Add focused tests for factory wiring and error paths.
- Avoid provider-specific behavior leaks into shared orchestration code.

### 7.2 Adding a Channel

- Implement `Channel` in `src/channels/`.
- Keep `send`, `listen`, `health_check`, typing semantics consistent.
- Cover auth/allowlist/health behavior with tests.

### 7.3 Adding a Tool

- Implement `Tool` in `src/tools/` with strict parameter schema.
- Validate and sanitize all inputs.
- Return structured `ToolResult`; avoid panics in runtime path.

### 7.4 Adding a Peripheral

- Implement `Peripheral` in `src/peripherals/`.
- Peripherals expose `tools()` — each tool delegates to the hardware (GPIO, sensors, etc.).
- Register board type in config schema if needed.
- See `docs/hardware-peripherals-design.md` for protocol and firmware notes.

### 7.5 Security / Runtime / Gateway Changes

- Include threat/risk notes and rollback strategy.
- Add/update tests or validation evidence for failure modes and boundaries.
- Keep observability useful but non-sensitive.
- For `.github/workflows/**` changes, include Actions allowlist impact in PR notes and update `docs/actions-source-policy.md` when sources change.

### 7.6 Docs System / README / IA Changes

- Treat docs navigation as product UX: preserve clear pathing from README -> docs hub -> SUMMARY -> category index.
- Keep top-level nav concise; avoid duplicative links across adjacent nav blocks.
- When runtime surfaces change, update related references (`commands/providers/channels/config/runbook/troubleshooting`).
- Keep multilingual entry-point parity for all supported locales (`en`, `zh-CN`, `ja`, `ru`, `fr`, `vi`, `el`) when nav or key wording changes.
- When shared docs wording changes, sync corresponding localized docs for supported locales in the same PR (or explicitly document deferral and follow-up PR).
- Treat `docs/i18n/<locale>/**` as canonical for localized hubs/summaries; keep docs-root compatibility shims aligned when edited.
- Apply `docs/i18n-guide.md` completion checklist before merge and include i18n status in PR notes.
- For docs snapshots, add new date-stamped files for new sprints rather than rewriting historical context.

## 8) Validation Matrix

Default local checks for code changes:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets -- -D warnings
cargo test
```

Preferred local pre-PR validation path (recommended, not required):

```bash
./dev/ci.sh all
```

Notes:

- Local Docker-based CI is strongly recommended when Docker is available.
- Contributors are not blocked from opening a PR if local Docker CI is unavailable; in that case run the most relevant native checks and document what was run.

Additional expectations by change type:

- **Docs/template-only**:
    - run markdown lint and link-integrity checks
    - if touching README/docs-hub/SUMMARY/collection indexes, verify EN/ZH-CN/JA/RU/FR/VI/EL navigation parity
    - if touching bootstrap docs/scripts, run `bash -n bootstrap.sh scripts/bootstrap.sh scripts/install.sh`
- **Workflow changes**: validate YAML syntax; run workflow lint/sanity checks when available.
- **Security/runtime/gateway/tools**: include at least one boundary/failure-mode validation.

If full checks are impractical, run the most relevant subset and document what was skipped and why.

## 9) Collaboration and PR Discipline

- Follow `.github/pull_request_template.md` fully (including side effects / blast radius).
- Keep PR descriptions concrete: problem, change, non-goals, risk, rollback.
- For issue-driven work, add explicit issue-closing keywords in the **PR body** for every resolved issue (for example `Closes #1502`).
- Do not rely on issue comments alone for linkage visibility; comments are supplemental, not a substitute for PR-body closing references.
- Default to one issue per clean commit/PR track. For multiple issues, split into separate clean commits/PRs unless there is clear technical coupling.
- If multiple issues are intentionally bundled in one PR, document the coupling rationale explicitly in the PR summary.
- Commit hygiene is mandatory: stage only task-scoped files and split unrelated changes into separate commits/worktrees.
- Completion hygiene is mandatory: after merge/close, clean stale local branches/worktrees before starting the next track.
- Use conventional commit titles.
- Prefer small PRs (`size: XS/S/M`) when possible.
- Agent-assisted PRs are welcome, **but contributors remain accountable for understanding what their code will do**.

### 9.1 Privacy/Sensitive Data and Neutral Wording (Required)

Treat privacy and neutrality as merge gates, not best-effort guidelines.

- Never commit personal or sensitive data in code, docs, tests, fixtures, snapshots, logs, examples, or commit messages.
- Prohibited data includes (non-exhaustive): real names, personal emails, phone numbers, addresses, access tokens, API keys, credentials, IDs, and private URLs.
- Use neutral project-scoped placeholders (for example: `user_a`, `test_user`, `project_bot`, `example.com`) instead of real identity data.
- Test names/messages/fixtures must be impersonal and system-focused; avoid first-person or identity-specific language.
- If identity-like context is unavoidable, use ZeroClaw-scoped roles/labels only (for example: `ZeroClawAgent`, `ZeroClawOperator`, `zeroclaw_user`) and avoid real-world personas.
- Recommended identity-safe naming palette (use when identity-like context is required):
    - actor labels: `ZeroClawAgent`, `ZeroClawOperator`, `ZeroClawMaintainer`, `zeroclaw_user`
    - service/runtime labels: `zeroclaw_bot`, `zeroclaw_service`, `zeroclaw_runtime`, `zeroclaw_node`
    - environment labels: `zeroclaw_project`, `zeroclaw_workspace`, `zeroclaw_channel`
- If reproducing external incidents, redact and anonymize all payloads before committing.
- Before push, review `git diff --cached` specifically for accidental sensitive strings and identity leakage.

### 9.2 Superseded-PR Attribution (Required)

When a PR supersedes another contributor's PR and carries forward substantive code or design decisions, preserve authorship explicitly.

- In the integrating commit message, add one `Co-authored-by: Name <email>` trailer per superseded contributor whose work is materially incorporated.
- Use a GitHub-recognized email (`<login@users.noreply.github.com>` or the contributor's verified commit email) so attribution is rendered correctly.
- Keep trailers on their own lines after a blank line at commit-message end; never encode them as escaped `\\n` text.
- In the PR body, list superseded PR links and briefly state what was incorporated from each.
- If no actual code/design was incorporated (only inspiration), do not use `Co-authored-by`; give credit in PR notes instead.

### 9.3 Superseded-PR PR Template (Recommended)

When superseding multiple PRs, use a consistent title/body structure to reduce reviewer ambiguity.

- Recommended title format: `feat(<scope>): unify and supersede #<pr_a>, #<pr_b> [and #<pr_n>]`
- If this is docs/chore/meta only, keep the same supersede suffix and use the appropriate conventional-commit type.
- In the PR body, include the following template (fill placeholders, remove non-applicable lines):

```md
## Supersedes
- #<pr_a> by @<author_a>
- #<pr_b> by @<author_b>
- #<pr_n> by @<author_n>

## Integrated Scope
- From #<pr_a>: <what was materially incorporated>
- From #<pr_b>: <what was materially incorporated>
- From #<pr_n>: <what was materially incorporated>

## Attribution
- Co-authored-by trailers added for materially incorporated contributors: Yes/No
- If No, explain why (for example: no direct code/design carry-over)

## Non-goals
- <explicitly list what was not carried over>

## Risk and Rollback
- Risk: <summary>
- Rollback: <revert commit/PR strategy>
```

### 9.4 Superseded-PR Commit Template (Recommended)

When a commit unifies or supersedes prior PR work, use a deterministic commit message layout so attribution is machine-parsed and reviewer-friendly.

- Keep one blank line between message sections, and exactly one blank line before trailer lines.
- Keep each trailer on its own line; do not wrap, indent, or encode as escaped `\n` text.
- Add one `Co-authored-by` trailer per materially incorporated contributor, using GitHub-recognized email.
- If no direct code/design is carried over, omit `Co-authored-by` and explain attribution in the PR body instead.

```text
feat(<scope>): unify and supersede #<pr_a>, #<pr_b> [and #<pr_n>]

<one-paragraph summary of integrated outcome>

Supersedes:
- #<pr_a> by @<author_a>
- #<pr_b> by @<author_b>
- #<pr_n> by @<author_n>

Integrated scope:
- <subsystem_or_feature_a>: from #<pr_x>
- <subsystem_or_feature_b>: from #<pr_y>

Co-authored-by: <Name A> <login_a@users.noreply.github.com>
Co-authored-by: <Name B> <login_b@users.noreply.github.com>
```

Reference docs:

- `CONTRIBUTING.md`
- `docs/README.md`
- `docs/SUMMARY.md`
- `docs/i18n-guide.md`
- `docs/i18n/README.md`
- `docs/i18n-coverage.md`
- `docs/docs-inventory.md`
- `docs/commands-reference.md`
- `docs/providers-reference.md`
- `docs/channels-reference.md`
- `docs/config-reference.md`
- `docs/operations-runbook.md`
- `docs/troubleshooting.md`
- `docs/one-click-bootstrap.md`
- `docs/pr-workflow.md`
- `docs/reviewer-playbook.md`
- `docs/ci-map.md`
- `docs/actions-source-policy.md`

## 10) Anti-Patterns (Do Not)

- Do not add heavy dependencies for minor convenience.
- Do not silently weaken security policy or access constraints.
- Do not add speculative config/feature flags “just in case”.
- Do not mix massive formatting-only changes with functional changes.
- Do not modify unrelated modules “while here”.
- Do not bypass failing checks without explicit explanation.
- Do not hide behavior-changing side effects in refactor commits.
- Do not include personal identity or sensitive information in test data, examples, docs, or commits.
- Do not attempt repository rebranding/identity replacement unless maintainers explicitly requested it in the current scope.
- Do not introduce new platform surfaces (for example `web` apps, dashboards, frontend stacks, or UI portals) unless maintainers explicitly requested them in the current scope.

## 11) Handoff Template (Agent -> Agent / Maintainer)

When handing off work, include:

1. What changed
2. What did not change
3. Validation run and results
4. Remaining risks / unknowns
5. Next recommended action

## 12) Vibe Coding Guardrails

When working in fast iterative mode:

- Keep each iteration reversible (small commits, clear rollback).
- Validate assumptions with code search before implementing.
- Prefer deterministic behavior over clever shortcuts.
- Do not “ship and hope” on security-sensitive paths.
- If uncertain, leave a concrete TODO with verification context, not a hidden guess.

---

## 13) Fork: Spore Deployment (txt4195-dotcom/zeroclaw)

Fork-specific. Upstream: `zeroclaw-labs/zeroclaw`.

### 13.1 Deploy Flow

```
push to main → GHA builds → GHCR push → serviceInstanceUpdate(@digest) → serviceInstanceDeployV2 → Railway fresh pull
```

- Image: `ghcr.io/txt4195-dotcom/zeroclaw:spore`
- Railway service: `zeroclaw-spore-v2` (GHCR image source)
- Volume: `/zeroclaw-data` (config, workspace, Chrome profile, SQLite)
- Railway IDs: serviceId=`496f96fe-9871-490a-87c1-33e75a136262`, environmentId=`71a5fa95-c9a5-4c32-8861-6105c472d8b6`

#### 자동 배포 (CI)

main에 push하면 GHA가 자동으로 빌드 → GHCR push → Railway deploy까지 처리.
`build-spore.yml`의 "Deploy to Railway" step이 digest 기반으로 `serviceInstanceUpdate` + `serviceInstanceDeployV2` 호출.

```bash
# 빌드 상태 확인
gh run list -R txt4195-dotcom/zeroclaw --workflow build-spore.yml --limit 3
```

#### 수동 배포 (Railway API)

Railway는 mutable tag (`:spore`)를 re-resolve하지 않음. **반드시 digest를 지정**해야 새 이미지를 pull.

```bash
# 1. serviceInstanceUpdate로 image source를 digest로 변경
curl -sf -X POST https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $RAILWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { serviceInstanceUpdate(serviceId: \"<SVC_ID>\", environmentId: \"<ENV_ID>\", input: { source: { image: \"ghcr.io/txt4195-dotcom/zeroclaw@sha256:<DIGEST>\" } }) }"}'

# 2. serviceInstanceDeployV2로 새 deployment 생성
curl -sf -X POST https://backboard.railway.com/graphql/v2 \
  -H "Authorization: Bearer $RAILWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { serviceInstanceDeployV2(serviceId: \"<SVC_ID>\", environmentId: \"<ENV_ID>\") }"}'
```

주의: `railway redeploy` (CLI/대시보드)는 기존 deployment를 재사용하며 이미지를 다시 pull하지 않음.

#### 컨테이너 접속

```bash
railway ssh              # SSH 접속
railway ssh -- <command> # 단일 명령 실행
```

#### VS Code Remote Tunnel

`start-spore.sh`에서 자동 시작. 최초 실행 시 GitHub device flow 인증 필요 (로그 확인).

```bash
# 브라우저: https://vscode.dev/tunnel/zeroclaw-spore
# 로컬 VS Code: Remote Tunnels 확장 → zeroclaw-spore 선택
```

### 13.2 Spore Files

| File | Role |
|------|------|
| `start-spore.sh` | Entrypoint: Xvfb → VNC → noVNC → nginx → VS Code tunnel → `zeroclaw daemon` |
| `nginx-spore.conf` | :8080 → gateway (:42617) + noVNC (:6080) |
| `railway.toml` | Volume mount config |
| `Dockerfile` (stage `spore`) | FROM dev + Chromium + Xvfb + VNC + nginx |
| `.github/workflows/build-spore.yml` | Build & push to GHCR |

### 13.3 Config & Secrets

No config in image. All via CLI:

```bash
railway shell
zeroclaw onboard    # API key, provider, Telegram, etc.
```

Persists in volume. Env var overrides: `ZEROCLAW_API_KEY`, `ZEROCLAW_PROVIDER`, `ZEROCLAW_MODEL`.

### 13.4 VNC (Chrome Login)

`https://<railway-url>/vnc/` — Chrome GUI for Google login. Session in `/zeroclaw-data/chrome-storage/`.

### 13.5 Upstream Sync

```bash
git fetch upstream main && git rebase upstream/main && git push origin main --force-with-lease
```

Always `cargo check` after sync.

### 13.6 Post-Deploy

1. `railway shell` → `zeroclaw onboard`
2. `/vnc/` → Chrome Google 로그인
3. Telegram bot 테스트
4. Restart → 볼륨 persist 확인

---

## 14) Quick Lookup Index

질문 → 어디를 봐야 하는지.

### 설정/Config

| 질문 | 찾는 곳 |
|------|---------|
| 설정 키 전체 목록 | `docs/config-reference.md` |
| 설정 스키마 (코드) | `src/config/schema.rs` |
| 환경변수 오버라이드 | `docs/config-reference.md` (각 섹션별 env override 항목) |
| 설정 검증 | `zeroclaw status`, `zeroclaw doctor` |

### CLI 명령어

| 질문 | 찾는 곳 |
|------|---------|
| 명령어 전체 목록 | `docs/commands-reference.md` |
| 명령어 구현/라우팅 | `src/main.rs` |

### Provider (LLM)

| 질문 | 찾는 곳 |
|------|---------|
| 지원 provider 목록 | `docs/providers-reference.md` |
| 커스텀 provider 설정 | `docs/custom-providers.md` |
| provider trait/구현 | `src/providers/traits.rs`, `src/providers/` |
| 모델 라우팅 (hint) | `docs/config-reference.md` → `[[model_routes]]`, `[query_classification]` |

### 채널 (Telegram/Discord 등)

| 질문 | 찾는 곳 |
|------|---------|
| 채널 설정 매트릭스 | `docs/channels-reference.md` |
| 채널 config 키 | `docs/config-reference.md` → `[channels_config.*]` |
| 채널 코드/시스템 프롬프트 빌드 | `src/channels/mod.rs` |
| 그룹챗 정책 | `docs/channels-reference.md` (group_reply, mention_only) |
| allowlist/승인 관리 | `docs/config-reference.md` → `[autonomy]` (non_cli_*, /approve) |

### 도구 (Tools)

| 질문 | 찾는 곳 |
|------|---------|
| 기본 제공 도구 목록 | `src/tools/` (각 파일이 도구 하나) |
| 도구 차단/허용 (비CLI) | `docs/config-reference.md` → `[autonomy].non_cli_excluded_tools` |
| WASM 커스텀 도구 | `docs/wasm-tools-guide.md` |
| 외부 API 호출 (credential) | `docs/config-reference.md` → `[http_request.credential_profiles]` |
| 도구 trait | `src/tools/traits.rs` |

### 에이전트/위임

| 질문 | 찾는 곳 |
|------|---------|
| delegate 서브에이전트 | `docs/config-reference.md` → `[agents.<name>]` |
| delegate 코드 | `src/tools/delegate.rs` |
| 에이전트 간 IPC | `docs/config-reference.md` → `[agents_ipc]` |
| IPC 코드 (SQLite) | `src/tools/agents_ipc.rs` |

### 메모리

| 질문 | 찾는 곳 |
|------|---------|
| 메모리 backend 설정 | `docs/config-reference.md` → `[memory]` |
| 메모리 trait/구현 | `src/memory/traits.rs`, `src/memory/` |
| 임베딩 라우팅 | `docs/config-reference.md` → `[[embedding_routes]]` |
| 정체성 파일 (IDENTITY.md 등) | workspace 루트 `.md` 파일들, `src/channels/mod.rs` → `load_openclaw_bootstrap_files()` |

### 보안

| 질문 | 찾는 곳 |
|------|---------|
| OTP/estop/URL정책 | `docs/config-reference.md` → `[security.*]` |
| 보안 코드 | `src/security/` |
| 보안 로드맵 (proposal) | `docs/security-roadmap.md` |
| 샌드박싱 옵션 | `docs/sandboxing.md` |
| 감사 로깅 | `docs/audit-logging.md`, `docs/audit-event-schema.md` |

### 웹/브라우저

| 질문 | 찾는 곳 |
|------|---------|
| 브라우저 자동화 | `docs/config-reference.md` → `[browser]` |
| 웹 검색 설정 | `docs/config-reference.md` → `[web_search]` |
| 웹 페이지 추출 | `docs/config-reference.md` → `[web_fetch]` |
| HTTP 요청 도구 | `docs/config-reference.md` → `[http_request]` |

### 배포/운영

| 질문 | 찾는 곳 |
|------|---------|
| Spore (Railway) 배포 | 이 문서 Section 13 |
| Docker 셋업 | `docs/docker-setup.md` |
| 운영 런북 | `docs/operations-runbook.md` |
| 트러블슈팅 | `docs/troubleshooting.md` |
| 네트워크 배포 (RPi) | `docs/network-deployment.md` |
| CI 워크플로우 맵 | `docs/ci-map.md` |

### 하드웨어

| 질문 | 찾는 곳 |
|------|---------|
| 주변장치 설계 | `docs/hardware-peripherals-design.md` |
| 보드 추가 방법 | `docs/adding-boards-and-tools.md` |
| 데이터시트 (핀맵) | `docs/datasheets/` |
| peripheral trait | `src/peripherals/traits.rs` |

### 플러그인/확장

| 질문 | 찾는 곳 |
|------|---------|
| 플러그인 시스템 | `docs/PLUGINS.md` |
| 스킬 설정 | `docs/config-reference.md` → `[skills]` |
| 크론 스케줄링 | `docs/cron-scheduling.md` |
| Composio OAuth | `docs/config-reference.md` → `[composio]` |
| Gateway REST API | `src/gateway/mod.rs`, `src/gateway/api.rs` |

### 멀티봇 아키텍처 (코드 수정 없이 가능)

한 컨테이너에서 `--config-dir`로 여러 인스턴스 실행:

```
zeroclaw daemon --config-dir /zeroclaw-data/bot-observer  # gateway :42617
zeroclaw daemon --config-dir /zeroclaw-data/bot-personal  # gateway :42618
```

- 각 인스턴스: 별도 config.toml, 별도 Telegram bot token, 별도 gateway port
- 공유: `agents_ipc.db_path` (같은 SQLite → 서로 발견/통신/상태 공유)

| 기능 | 설정만으로 가능 | 어디서 |
|------|:---:|---------|
| 멀티봇 (관찰 + 1:1) | O | `--config-dir` |
| 봇 간 통신/상태 공유 | O | `[agents_ipc]` → `state_get/set`, `agents_send/inbox` |
| 메시지별 모델 자동 전환 | O | `[query_classification]` + `[[model_routes]]` |
| 응답 전 자동 조사 | O | `[research]` |
| 서브에이전트 위임 | O | `[agents.<name>]` + delegate |
| 외부 API 호출 | O | `[http_request]` + `credential_profiles` |
| 스케줄 작업 | O | cron |
| 웹 검색/페이지 읽기 | O | `[web_search]` + `[web_fetch]` |
| 브라우저 자동화 | O | `[browser]` |
| 도구 실행 권한 관리 | O | `[autonomy]` |
| 그룹 대화 통째로 기억 | △ | conversation history가 per-user. 관찰봇이 `memory_store`로 우회 가능 |

### 인증 체계

| 레이어 | 목적 | 방식 |
|--------|------|------|
| Gateway pairing | API 접근 권한 (대시보드/REST) | 1회 6자리 코드 → bearer token 교환 |
| Security OTP | 위험 도구 실행 허가 | TOTP (Google Authenticator 등) |
| Channel allowlist | 채널 사용자 허가 | `allowed_users` (deny-by-default) |

원격 zeroclaw 간 통신: gateway HTTP + `credential_profiles`로 bearer token 주입.
같은 머신: IPC (무료, 비동기) + gateway HTTP (LLM 비용 발생) 병용.
