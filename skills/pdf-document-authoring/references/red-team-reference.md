# Red Team Review Reference

Adversarial analysis engine for code, documents, repositories, security configurations, dependencies, architecture, and infrastructure. Applies Socratic reasoning chains to trace implications across the codebase when issues are found.

This reference covers 11 review domains, the Socratic reasoning protocol, the rabbit hole investigation protocol, severity assignment, and structured output formats.

---

## Part 1: Document Domain (Backward Compatible)

These 6 categories apply when reviewing markdown documents (research reports, white papers, technical docs). They are preserved from the original red-team reference for backward compatibility with research-report Phase 7.5 and document-builder Step 5.

### 1. Factual Accuracy

Challenge any claim that:
- States a specific number, percentage, date, or measurement without a citation
- Attributes a position or quote to a named person or organization without a source
- Makes a comparative claim ("X is faster than Y") without quantitative evidence
- Presents a prediction or forecast without identifying its source methodology

**Verification**: Search the web for the specific claim. If uncorroborated by at least one independent source, flag it.

### 2. Logical Consistency

Challenge any reasoning that:
- Draws a conclusion that does not follow from stated premises (non sequitur)
- Generalizes from a single example (hasty generalization)
- Presents a false dichotomy (only two options when more exist)
- Uses circular reasoning (conclusion restates a premise)
- Conflates correlation with causation
- Contains contradictions between sections

**Verification**: Map premises to conclusions. Flag gaps.

### 3. Source Quality

Challenge any citation that:
- Comes from marketing material presented as objective analysis
- Is more than 3 years old for fast-moving topics
- Is a blog post used as the sole source for a major claim
- Is from a source with obvious conflict of interest
- Cannot be verified (malformed URL, dead link)

**Verification**: Evaluate each citation against the Source Quality Rubric (Part 5).

### 4. Citation Completeness

Challenge any section that:
- Contains factual claims with no in-text citation
- References `[N]` that does not exist in Sources & References
- Has orphan citations (defined but never cited)
- Uses non-sequential citation numbering
- Has duplicate citations under different numbers

**Verification**: Cross-reference all `[N]` markers against References.

### 5. Unsupported Generalizations

Challenge any statement that:
- Uses absolute language ("always", "never") without exhaustive evidence
- Claims consensus without survey or meta-analysis data
- Extrapolates beyond the data range without acknowledging uncertainty
- Presents opinion as fact without attribution

**Verification**: Flag absolute language. Check evidence vs claim strength.

### 6. Statistical Claims

Challenge any statistics that:
- Present a percentage without a base (denominator)
- Compare numbers from different time periods without noting differences
- Use averages without indicating variance
- Cite projected figures as observed measurements
- Cherry-pick favorable time windows

**Verification**: Every statistic needs a source, a base, and a time frame.

---

## Part 2: Code and Technical Domains

These domains activate based on technology fingerprinting (see Domain Auto-Detection).

### 7. Code Quality

Checks extracted from QC Agent + Software Developer Agent patterns.

Challenge any code that:
- Contains logic errors (off-by-one, wrong operator, inverted condition)
- Has unchecked return values or silently swallowed exceptions
- Contains dead code (unreachable branches, unused imports, commented-out blocks)
- Violates DRY (significant duplicated logic across files)
- Uses inconsistent naming conventions within the project
- Has functions exceeding ~50 lines without clear justification
- Contains TODO/FIXME/HACK markers in production paths
- Makes assumptions about external state without validation

**Verification**: Read the code. Grep for patterns. Trace call paths.

### 8. Security

Checks derived from OWASP Top 10 (2021) + STRIDE threat model + QC Agent security review.

**A01 Broken Access Control**:
- Missing function-level access checks
- Insecure Direct Object References (IDOR)
- CORS misconfiguration (wildcard origins)
- Path traversal vulnerabilities
- Privilege escalation via role manipulation

**A02 Cryptographic Failures**:
- Sensitive data transmitted in plaintext
- Weak algorithms (MD5/SHA1 for passwords)
- Hardcoded keys, secrets, or API tokens in source
- Missing encryption at rest for PII/sensitive data

**A03 Injection**:
- SQL injection (string concatenation in queries)
- NoSQL injection (unsanitized query objects)
- Command injection (shell exec with user input)
- Cross-Site Scripting (reflected, stored, DOM-based)
- Template injection (unsanitized template variables)

**A04 Insecure Design**:
- Missing rate limiting on authentication endpoints
- No defense in depth (single layer of validation)
- Missing threat modeling for sensitive operations
- Business logic bypasses

**A05 Security Misconfiguration**:
- Default credentials in configuration
- Debug mode or verbose errors in production
- Missing security headers (CSP, HSTS, X-Frame-Options)
- Unnecessary features or services enabled

**A06 Vulnerable Components**:
- Dependencies with known CVEs
- Abandoned packages (no commits in 2+ years)
- Packages pulled from untrusted registries
- Missing lock file (non-deterministic installs)

**A07 Authentication Failures**:
- Weak password policies (no minimum length/complexity)
- Missing multi-factor authentication for sensitive ops
- Session tokens in URLs or logs
- Missing account lockout after failed attempts

**A08 Software/Data Integrity**:
- Deserialization of untrusted data
- CI/CD pipeline without integrity verification
- Missing Subresource Integrity (SRI) for CDN assets
- Unsigned software updates

**A09 Logging/Monitoring Failures**:
- Missing audit logs for security-relevant events
- PII or credentials appearing in logs
- No alerting on suspicious authentication activity
- Log injection vulnerabilities

**A10 SSRF**:
- Unvalidated URL fetching from user input
- Access to internal services or cloud metadata endpoints
- DNS rebinding vulnerabilities

**Verification**: Grep for anti-patterns. Trace data flow from user input to output. Use WebSearch for CVE databases.

### 9. Dependencies

Challenge any dependency that:
- Has a known CVE (search GitHub Advisory Database, NVD)
- Is more than 2 major versions behind current stable
- Has no commits in the last 2 years (abandoned)
- Has a license incompatible with the project license
- Is pulled from a non-standard registry without justification
- Has a very small user base for critical functionality (bus factor risk)
- Pins to an exact version without a lock file, or uses wildcard ranges

**Verification**: Read package manifest. Use `npm audit` / `pip audit` / `cargo audit` if available. WebSearch for CVEs.

### 10. Architecture

Checks derived from Senior Systems Engineer patterns.

Challenge any architecture that:
- Has high coupling between modules (changes in one require changes in many)
- Has low cohesion (modules that do unrelated things)
- Has no clear separation between layers (UI logic mixed with data access)
- Lacks error boundaries or fault isolation
- Has single points of failure without redundancy
- Contains circular dependencies between modules
- Uses inappropriate design patterns (over-engineered or under-engineered)
- Has significant technical debt without documentation or plan

**Verification**: Map module boundaries. Trace import/dependency graphs. Assess blast radius of changes.

### 11. Testing

Checks derived from QA Agent patterns.

Challenge any test suite that:
- Has critical business logic with zero test coverage
- Only tests happy paths (no error, edge, or boundary cases)
- Contains flaky tests (timing-dependent, order-dependent)
- Mocks so aggressively that tests verify mocks, not behavior
- Has no integration tests (only unit tests, or only E2E)
- Contains test code that is harder to read than the production code
- Is missing regression tests for known previous bugs

**Edge cases to verify**: Empty/null/undefined inputs, maximum/minimum values, concurrent access, network failures, malformed input, timezone boundaries, unicode/special characters.

**Verification**: Read test files. Compare test coverage to critical paths. Run tests if possible.

### 12. DevOps / CI/CD

Checks derived from DevOps Agent + Infrastructure Agent patterns.

Challenge any pipeline or deployment that:
- Contains hardcoded secrets or credentials
- Has no rollback mechanism for failed deployments
- Lacks staging or preview environments
- Has no automated tests in the CI pipeline
- Uses `latest` tags for Docker images in production
- Has overly permissive container permissions (running as root)
- Missing health checks for deployed services
- Has no monitoring or alerting configured

**Verification**: Read CI/CD configs, Dockerfiles, deployment scripts. Check for secrets patterns.

### 13. Database

Checks derived from Database Expert Agent patterns.

Challenge any database design that:
- Has queries that cause N+1 problems (ORM lazy loading in loops)
- Is missing indexes on frequently queried columns
- Has no foreign key constraints or referential integrity
- Uses schema migrations that are irreversible
- Stores sensitive data (passwords, tokens) without hashing/encryption
- Has unbounded queries (SELECT * without LIMIT on user-facing endpoints)
- Mixes DDL and DML in a single migration
- Has no backup or point-in-time recovery strategy

**Verification**: Read schema files, migrations, ORM configs. Grep for query patterns.

### 14. AI/ML

Checks derived from AIOps Agent patterns.

Challenge any AI/ML implementation that:
- Passes user input directly into prompts without sanitization (prompt injection)
- Has no output validation or guardrails on LLM responses
- Lacks cost tracking or monitoring for API calls
- Uses no evaluation framework (vibes-based quality assessment)
- Has no fallback when the AI service is unavailable
- Stores PII in prompts or training data without necessity
- Relies on a single provider with no failover
- Has no rate limiting on AI-powered endpoints

**Verification**: Read prompt templates, AI integration code, config files. Check for guardrails.

### 15. Accessibility

Checks derived from HIG/UI/UX Agent patterns. WCAG 2.1 AA compliance.

Challenge any frontend that:
- Has text with insufficient contrast ratio (< 4.5:1 for normal text, < 3:1 for large text)
- Has interactive elements not reachable via keyboard
- Is missing ARIA labels on non-text interactive elements
- Has no visible focus indicators
- Uses color alone to convey meaning (no text/icon alternative)
- Has form inputs without associated labels
- Is missing alt text on informational images
- Has auto-playing media without user control
- Has no skip-to-content link for screen readers
- Has layout shifts on loading (no skeleton screens or reserved space)

**Verification**: Read component code. Check for ARIA attributes. If Playwright is available, run automated checks.

### 16. Strategic

Checks derived from Project Manager + Leadership Agent patterns.

Challenge any strategic decision that:
- Solves a problem no one has (building features without user evidence)
- Uses a complex solution when a simpler one exists (over-engineering)
- Creates vendor lock-in without acknowledging the tradeoff
- Has no clear success criteria or measurable outcomes
- Ignores first-principles analysis (cargo-culting patterns from other projects)
- Has scope that exceeds available resources (team, time, budget)
- Makes build-vs-buy decisions without cost/maintenance analysis

**Verification**: Apply first-principles decomposition. Challenge every assumption about "requirements."

---

## Part 3: Socratic Reasoning Protocol

The Socratic Method is the core reasoning engine applied within every domain analysis. When examining any finding, the agent must work through all 5 stages:

### Stage 1: Clarification

"What exactly is happening here?"

- **Code**: What does this function do? What are its inputs, outputs, and side effects? What assumptions does it make?
- **Document**: What exactly does this sentence claim? Is the claim specific enough to be testable?
- **Security**: What data flows through this path? Where does user input enter and exit?
- **Architecture**: What is this component's single responsibility? What contracts does it enforce?

### Stage 2: Probing Reasoning

"Why was this done this way? What evidence supports or contradicts it?"

- **Code**: Why was this pattern chosen? Is there evidence in comments, commit history, or docs?
- **Document**: What evidence backs this claim? Is the evidence proportional to the claim's strength?
- **Security**: Why is this input trusted? What validation exists between entry and use?
- **Dependencies**: Why was this package chosen? Are there maintained alternatives?

### Stage 3: Implications

"If this is wrong here, where else could it be wrong?"

This stage triggers the Rabbit Hole Investigation Protocol (Part 4). The key question: **if this pattern is broken in one place, it is likely broken in others.**

- **Code**: If this function has a bug, what calls it? What downstream effects propagate?
- **Security**: If this auth check is bypassed, what data is exposed? What operations become available?
- **Dependencies**: If this package has a CVE, what other packages in the dependency tree are affected?
- **Architecture**: If this module has high coupling, what other modules share the same boundary violations?

### Stage 4: Alternative Perspectives

"What would a different expert say about this?"

For each finding, consider at least two perspectives:
- **Attacker perspective**: How would a malicious actor exploit this?
- **Maintainer perspective**: How will the next developer understand this in 6 months?
- **User perspective**: How does this affect the end user's experience?
- **Ethical perspective**: Does this raise privacy, bias, or fairness concerns?
- **Business perspective**: What is the cost of NOT fixing this vs. the cost of fixing it?

### Stage 5: Meta-Questioning

"Am I asking the right questions? What am I missing?"

Before concluding each domain analysis:
- What did I NOT check? What categories did I skip?
- What assumptions am I making about the codebase?
- What blind spots might I have based on the domains I analyzed?
- Are there cross-domain interactions I missed? (e.g., a security issue caused by a database design decision)

---

## Part 4: Rabbit Hole Investigation Protocol

When any analysis produces a WARN or BLOCK finding, trace its implications through these 4 steps:

### Step 1: Pattern Proliferation

"Where else does this exact pattern appear?"

Use Grep to search the entire codebase for the same anti-pattern.

Example:
```
Found SQL concatenation in users.py:47
→ Grep for similar patterns across all .py files
→ Found 3 more instances: orders.py:23, payments.py:89, admin.py:156
→ Total: 4 instances of the same vulnerability
```

### Step 2: Dependency Tracing

"What depends on this broken component?"

Find all callers and consumers of the affected function, module, or component.

Example:
```
getUserById() has no input validation
→ Grep for getUserById across codebase
→ Found 12 call sites
→ 3 of those pass user-controlled input directly (route handlers)
→ 9 pass internal IDs (lower risk but still unsafe)
```

### Step 3: Blast Radius Assessment

"What is the impact if this fails in production?"

Classify the blast radius:

| Level | Scope | Example |
|-------|-------|---------|
| **LOCAL** | Only this function/component | A utility function returns wrong value for edge case |
| **MODULE** | Entire feature degraded | Payment processing fails for one payment method |
| **SYSTEM** | Cross-cutting failure | Authentication bypass, data integrity corruption |
| **EXTERNAL** | Affects users, data, third parties | User PII leaked, third-party API abuse, data loss |

### Step 4: Threat Modeling (Security Findings Only)

"What would a malicious actor do with this?"

Apply the STRIDE model:

| Threat | Question | Example |
|--------|----------|---------|
| **S**poofing | Can identity be faked? | Missing auth on API endpoint |
| **T**ampering | Can data be modified? | Unsigned JWT, mutable shared state |
| **R**epudiation | Can actions be denied? | No audit log for admin operations |
| **I**nformation Disclosure | Can data leak? | Verbose error messages, PII in logs |
| **D**enial of Service | Can availability be degraded? | No rate limiting, unbounded queries |
| **E**levation of Privilege | Can access be escalated? | Role check only on frontend |

### Investigation Depth

- Default max depth: 5 levels (each step can reveal a new finding that triggers another investigation)
- `--depth shallow`: 1 level (pattern search only, no tracing)
- `--depth standard`: 3 levels (pattern + dependency + blast radius)
- `--depth deep`: 5 levels (full protocol including threat modeling)

---

## Part 5: Severity Assignment

### BLOCK — Must Fix

The target MUST NOT ship, merge, or be built until resolved.

| Domain | BLOCK Criteria |
|--------|----------------|
| document | Demonstrably false claim, broken citation, internal contradiction, unsourced stat central to recommendation |
| code | Active vulnerability, demonstrably wrong logic, unhandled crash in critical path |
| security | Exploitable vulnerability (injectable, hardcoded secrets, broken auth) |
| deps | Known CVE with exploit available, license incompatibility |
| architecture | Critical single point of failure in production path |
| testing | No tests for authentication, payment, or data-deletion logic |
| database | SQL injection via ORM, unencrypted passwords, irreversible migration already applied |
| aiml | Prompt injection vulnerability in user-facing endpoint |
| accessibility | Interactive elements completely unreachable via keyboard |

### WARN — Should Address

The target can proceed but these issues should be tracked and addressed.

| Domain | WARN Criteria |
|--------|---------------|
| document | Single-source claim, borderline-quality source, overstated language |
| code | Code smells, missing error handling, unchecked assumptions, DRY violations |
| security | Missing security headers, debug mode detectable, weak password policy |
| deps | Outdated packages (1+ major versions behind), abandoned maintainers (2+ years) |
| architecture | High coupling, technical debt without plan, inappropriate patterns |
| testing | Coverage gaps in non-critical paths, missing edge case tests |
| database | Missing indexes on queried columns, N+1 patterns, no backup strategy |
| aiml | No cost tracking, missing evaluation framework, no fallback |
| accessibility | Low contrast (below AA but not critical), missing alt text on decorative images |

### NOTE — Informational

No action required. Quality improvement suggestions.

| Domain | NOTE Criteria |
|--------|--------------|
| document | Stylistic suggestions, section balance, visualization opportunities |
| code | Style inconsistencies, minor refactoring opportunities, naming suggestions |
| security | Hardening opportunities, defense-in-depth additions |
| deps | Better alternatives available, minor version updates |
| architecture | Documentation gaps, module naming suggestions |
| testing | Additional edge cases to consider, test readability improvements |
| accessibility | Enhanced ARIA hints, mobile UX improvements |

---

## Part 6: Source Quality Rubric

Rate each cited source on a 1-5 scale:

| Score | Label | Criteria |
|-------|-------|----------|
| 5 | Authoritative | Peer-reviewed journal, government agency, established research institution |
| 4 | Reliable | Major news outlet, industry analyst (Gartner, Forrester), official documentation |
| 3 | Credible | Well-known tech blog, conference proceedings, reputable trade publication |
| 2 | Marginal | Personal blog with expertise, vendor white paper with data, expert social media |
| 1 | Weak | Anonymous post, marketing material, unverifiable claim, dead link |

**Minimum standards**:
- Average source quality >= 3.0
- No BLOCK claim relies solely on sources scored 1-2
- At least 30% of sources should score 4-5

---

## Part 7: Domain Auto-Detection

Technology fingerprinting determines which domains to activate:

| Indicator | Technology | Domains Activated |
|-----------|-----------|-------------------|
| `package.json`, `tsconfig.json` | Node.js / TypeScript | code, security, deps, testing, devops |
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python | code, security, deps, testing |
| `Cargo.toml` | Rust | code, deps, testing |
| `go.mod` | Go | code, security, deps, testing |
| `Dockerfile`, `docker-compose.yml` | Docker | devops, security |
| `*.tf`, `*.tfvars` | Terraform | devops, security |
| `.github/workflows/*` | GitHub Actions | devops |
| `*.test.*`, `*.spec.*`, `__tests__/` | Test suite | testing |
| `prisma/schema.prisma`, `*.sql`, `migrations/` | Database | database |
| `.env*`, `secrets.*`, `credentials.*` | Secrets | security (HIGH PRIORITY) |
| `*.md` with YAML frontmatter | Documents | document |
| `*.tsx`, `*.jsx`, `*.vue`, `*.svelte` | Frontend UI | code, accessibility |
| AI/ML libraries in deps | AI/ML | aiml |

The `--domains` flag overrides auto-detection (e.g., `--domains security,deps`).

---

## Part 8: Structured Output Format

### Multi-Domain Output

```
## Red Team Analysis Summary

- **Target**: <path>
- **Domains analyzed**: code, security, deps, architecture, testing
- **Domains skipped**: database (no schema), aiml (no AI deps), accessibility (no frontend)
- **Total findings**: N
- **BLOCK**: N | **WARN**: N | **NOTE**: N
- **Rabbit holes investigated**: N chains, deepest: M levels
- **Socratic reasoning chains**: N
- **Tools used**: [list]
- **Prior findings from vector DB**: N

## BLOCK Findings

### [B1] Domain: Security | File: src/users.py:47
**Category**: SQL Injection (OWASP A03)
**Finding**: Direct string concatenation in SQL query
**Code**: `cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")`
**Socratic Chain**:
  1. *Clarification*: Function constructs SQL from user-controlled input
  2. *Reasoning*: No input validation upstream (traced through route handler)
  3. *Implications*: Pattern found in 3 additional files
  4. *Perspectives*: Attacker can extract entire database via UNION injection
  5. *Meta*: Entire DB layer lacks parameterization — systemic issue
**Rabbit Hole**:
  - Pattern proliferation: 4 instances across codebase
  - Dependency trace: 12 callers, 3 pass user input directly
  - Blast radius: SYSTEM
  - STRIDE: Information Disclosure + Elevation of Privilege
**Suggested fix**: Use parameterized queries
**Estimated effort**: Low

## WARN Findings
### [W1] Domain: Dependencies | ...

## NOTE Observations
### [N1] Domain: Architecture | ...

## Domain Summaries
### Code Quality — N findings (B/W/N)
### Security — N findings (B/W/N)
...
```

### Document-Only Output (Backward Compatible)

When called with `domains: ["document"]` from research-report or document-builder, use the original simpler format from Part 1. The multi-domain output format is a superset — all original fields are preserved.

---

## Part 9: Integration Protocols

### Dispatch from Research-Report (Phase 7.5)

```
Task prompt: "You are the adversarial red-team reviewer. Analyze the markdown
report at '<path>'. Focus on document-relevant domains: document, strategic.
Read your full protocol at '${CLAUDE_PLUGIN_ROOT}/skills/pdf-document-authoring/references/red-team-reference.md'.
Return your structured review."
Sub-agent type: red-team-reviewer
```

### Dispatch from Document-Builder (Step 5)

Same as research-report. Document domain only.

### Dispatch from Sprint-Executor (Phase 6)

```
Task prompt: "You are the adversarial red-team reviewer. Analyze the code
changes from this sprint. Target: '<project_root>'.
Focus domains: code, security, testing, deps.
Read your full protocol at '${CLAUDE_PLUGIN_ROOT}/skills/pdf-document-authoring/references/red-team-reference.md'.
Return your structured review."
Sub-agent type: red-team-reviewer
```

### Standalone Command

The `/gerdsenai:red-team <target>` command runs the full review autonomously. The user decides which findings to address. Supports `--fix` flag for automated resolution.

---

## Part 10: Review Methodology Section

When red team review is performed on a document, add this to the Methodology section:

```markdown
### Adversarial Quality Review

This report underwent automated adversarial review prior to publication. A separate
review agent independently evaluated all factual claims, logical arguments, source
quality, citation completeness, and statistical assertions. N challenges were raised
across N categories. All BLOCK-severity challenges were resolved before publication.
N claims were revised, N sources were added, and N unsupported assertions were removed.
```

When red team review is performed on code, the methodology is included in the structured output summary, not embedded in source files.
