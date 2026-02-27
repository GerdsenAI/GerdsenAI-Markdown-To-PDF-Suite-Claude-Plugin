# Mermaid Diagram Reference

All supported diagram types, when to use them, and syntax templates. The Document Builder renders mermaid diagrams locally via Playwright + Chromium.

## When to Create Diagrams

Proactively include mermaid diagrams when they communicate more effectively than text. Use them for:

- **Processes and workflows** - flowcharts, state diagrams
- **System architecture** - C4 context, class diagrams, block diagrams
- **Data relationships** - ER diagrams, class diagrams
- **Timelines and planning** - gantt charts, timelines
- **Comparisons and analysis** - quadrant charts, pie charts, XY charts
- **User experience** - journey maps, sequence diagrams
- **Project structure** - mindmaps, requirement diagrams
- **Version control flows** - git graphs
- **Resource flows** - sankey diagrams

Do NOT ask the user if they want a diagram. If the content benefits from visual representation, include it.

---

## Diagram Types

### 1. Flowchart

**Use when:** Showing processes, decision trees, workflows, algorithms, or any step-by-step logic with branching.

```mermaid
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action One]
    B -->|No| D[Action Two]
    C --> E[End]
    D --> E
```

Directions: `TD` (top-down), `LR` (left-right), `TB` (top-bottom), `BT` (bottom-top), `RL` (right-left).

Node shapes:
- `[text]` rectangle
- `(text)` rounded
- `([text])` stadium
- `[[text]]` subroutine
- `[(text)]` cylinder/database
- `((text))` circle
- `{text}` rhombus/decision
- `{{text}}` hexagon
- `>text]` asymmetric/flag

Link types:
- `-->` solid arrow
- `---` solid line
- `-.->` dotted arrow
- `==>` thick arrow
- `-->|label|` arrow with label

Subgraphs group related nodes:
```mermaid
flowchart TD
    subgraph Backend
        API[API Server] --> DB[(Database)]
    end
    subgraph Frontend
        UI[Web App] --> API
    end
```

### 2. Sequence Diagram

**Use when:** Showing interactions between systems/actors over time, API flows, authentication sequences, or request-response patterns.

```mermaid
sequenceDiagram
    participant U as User
    participant S as Server
    participant D as Database
    U->>S: POST /api/data
    S->>D: INSERT query
    D-->>S: Success
    S-->>U: 201 Created
```

Arrow types:
- `->>` synchronous (solid)
- `-->>` return/response (dashed)
- `-)` async (open arrow)

Blocks:
- `loop` - repeating actions
- `alt` / `else` - conditional branches
- `opt` - optional actions
- `par` - parallel execution
- `Note over A,B: text` - annotations

### 3. State Diagram

**Use when:** Modeling object lifecycles, status transitions, FSMs, or any entity with distinct states and transitions between them.

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Review
    Review --> Approved
    Review --> Draft : Changes Requested
    Approved --> Published
    Published --> [*]
```

Features:
- `[*]` for start/end states
- `state "Name" as alias` for long names
- Composite states with nested `state Parent { ... }`
- `<<choice>>` for decision points
- `--` separator for concurrent regions

### 4. Class Diagram

**Use when:** Documenting object-oriented design, API data models, type hierarchies, or interface contracts.

```mermaid
classDiagram
    class User {
        +String name
        +String email
        +login() bool
        +logout() void
    }
    class Admin {
        +manageUsers() void
    }
    User <|-- Admin : inherits
    User "1" --> "*" Order : places
```

Visibility: `+` public, `-` private, `#` protected.

Relationships:
- `<|--` inheritance
- `*--` composition
- `o--` aggregation
- `-->` association
- `..>` dependency

Stereotypes: `<<interface>>`, `<<abstract>>`, `<<service>>`.

### 5. Entity Relationship Diagram

**Use when:** Documenting database schemas, data models, or entity relationships with cardinality.

```mermaid
erDiagram
    USER {
        uuid id PK
        string name
        string email
        datetime created_at
    }
    ORDER {
        uuid id PK
        uuid user_id FK
        float total
        string status
    }
    USER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
```

Cardinality:
- `||--||` one-to-one
- `||--o{` one-to-many
- `}o--||` many-to-one
- `}o--o{` many-to-many

### 6. Gantt Chart

**Use when:** Project timelines, sprint planning, release schedules, or any time-based task breakdown.

```mermaid
gantt
    title Project Timeline
    dateFormat YYYY-MM-DD
    section Design
        Wireframes     :done, a1, 2026-01-01, 14d
        Prototypes     :active, a2, after a1, 7d
    section Build
        Backend        :b1, after a2, 21d
        Frontend       :b2, after a2, 21d
    section Test
        QA Testing     :crit, c1, after b1, 14d
```

Task states: `done`, `active`, `crit` (critical path). Use `after taskId` for dependencies. Milestones are 0-duration tasks.

### 7. Pie Chart

**Use when:** Showing proportional breakdowns, market share, resource allocation, or survey results.

```mermaid
pie title Budget Allocation
    "Engineering" : 45
    "Marketing" : 25
    "Operations" : 20
    "Research" : 10
```

### 8. Git Graph

**Use when:** Illustrating branching strategies, release workflows, or explaining git history.

```mermaid
gitGraph
    commit id: "init"
    branch develop
    checkout develop
    commit id: "feature-a"
    branch feature/auth
    checkout feature/auth
    commit id: "add-login"
    commit id: "add-signup"
    checkout develop
    merge feature/auth tag: "v0.2.0"
    checkout main
    merge develop tag: "v1.0.0"
```

### 9. Mindmap

**Use when:** Brainstorming, topic exploration, concept mapping, feature breakdowns, or hierarchical idea organization.

```mermaid
mindmap
    root((Project))
        Frontend
            React
            TypeScript
            Tailwind
        Backend
            Node.js
            PostgreSQL
            Redis
        Infrastructure
            Docker
            Kubernetes
            CI/CD
```

### 10. Timeline

**Use when:** Historical overviews, roadmaps, milestone tracking, or chronological event sequences.

```mermaid
timeline
    title Product Roadmap 2026
    section Q1
        January : MVP Launch
                : Core API Complete
        February : Mobile App Beta
        March : Public Beta
    section Q2
        April : GA Release
        May : Enterprise Features
        June : International Launch
```

### 11. User Journey

**Use when:** Mapping user experience flows, identifying pain points, onboarding sequences, or customer satisfaction analysis.

```mermaid
journey
    title User Onboarding
    section Discovery
        Visit landing page: 5: User
        Read documentation: 3: User
    section Sign Up
        Create account: 4: User
        Verify email: 2: User
    section First Use
        Complete tutorial: 4: User, Support
        Build first project: 5: User
```

Scores range from 1 (frustrating) to 5 (delightful). Multiple actors can be listed per task.

### 12. Quadrant Chart

**Use when:** Prioritization matrices (effort vs impact), competitive analysis, risk assessment, or any two-axis comparison.

```mermaid
quadrantChart
    title Feature Prioritization
    x-axis Low Effort --> High Effort
    y-axis Low Impact --> High Impact
    quadrant-1 Do First
    quadrant-2 Plan Carefully
    quadrant-3 Delegate
    quadrant-4 Eliminate
    Auth Improvements: [0.3, 0.9]
    Dark Mode: [0.2, 0.4]
    API Rewrite: [0.8, 0.85]
    Logo Refresh: [0.1, 0.15]
```

### 13. C4 Context Diagram

**Use when:** High-level system architecture showing users, systems, and their interactions. Ideal for architecture documentation and system overviews.

```mermaid
C4Context
    title System Context Diagram
    Person(user, "End User", "Uses the application")
    System(app, "Web Application", "Main product")
    SystemDb(db, "Database", "PostgreSQL")
    System_Ext(email, "Email Service", "SendGrid")

    Rel(user, app, "Uses", "HTTPS")
    Rel(app, db, "Reads/Writes", "TCP/5432")
    Rel(app, email, "Sends emails", "SMTP")
```

Elements: `Person`, `System`, `SystemDb`, `SystemQueue`, `System_Ext`, `Boundary`.

### 14. XY Chart

**Use when:** Plotting numerical data, performance metrics over time, benchmarks, or any line/bar chart visualization.

```mermaid
xychart
    title "Response Times (ms)"
    x-axis [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    y-axis "Latency" 0 --> 500
    line [45, 52, 48, 95, 120, 85, 60, 55, 50, 48, 45]
    bar [30, 35, 32, 60, 80, 55, 40, 38, 35, 33, 30]
```

### 15. Requirement Diagram

**Use when:** Documenting system requirements, traceability matrices, or showing how requirements relate to components.

```mermaid
requirementDiagram
    requirement "User Authentication" {
        id: REQ-001
        text: "System shall authenticate users via OAuth 2.0"
        risk: medium
        verifymethod: test
    }
    functionalRequirement "Session Management" {
        id: REQ-002
        text: "Sessions expire after 30 minutes of inactivity"
        risk: low
        verifymethod: test
    }
    element "Auth Service" {
        type: "software"
        docRef: "auth-service-v2"
    }
    "Auth Service" - satisfies -> "User Authentication"
    "Session Management" - derives -> "User Authentication"
```

Requirement types: `requirement`, `functionalRequirement`, `performanceRequirement`, `interfaceRequirement`.
Relationships: `satisfies`, `derives`, `traces`, `contains`, `refines`, `copies`, `verifies`.

### 16. Sankey Diagram

**Use when:** Visualizing resource flows, energy distribution, budget allocation flows, or data pipeline throughput.

```mermaid
sankey
    Revenue,Engineering,450000
    Revenue,Marketing,250000
    Revenue,Operations,200000
    Engineering,Frontend,200000
    Engineering,Backend,150000
    Engineering,Infrastructure,100000
```

### 17. Block Diagram (Beta)

**Use when:** System block diagrams, hardware architecture, or component layouts with spatial arrangement.

```mermaid
block-beta
    columns 3
    Frontend:3
    block:backend:2
        API["API Gateway"]
        Auth["Auth Service"]
    end
    DB[("Database")]
    Frontend --> API
    API --> Auth
    API --> DB
```

---

## Syntax Rules

1. **Labels under 80 characters** - use `<br>` for line breaks within nodes
2. **Avoid special characters** in labels: `"`, `<`, `>`, `{`, `}` - use parentheses or brackets instead
3. **No double-arrow edge labels** - use single direction arrows with labels
4. **No spaces before pipe** in arrow labels - `-->|label|` not `--> |label|`
5. **Theme is set in config.yaml** - do not use `%%{init:...}%%` directives (the builder handles theming)
6. **Fallback behavior** - if rendering fails, the builder shows the diagram as a code block (configurable)

## Choosing the Right Diagram

| Need | Diagram Type |
|------|-------------|
| Process with decisions | Flowchart |
| API/system interactions over time | Sequence |
| Object/entity lifecycle | State |
| OOP design, type hierarchy | Class |
| Database schema | ER |
| Project schedule | Gantt |
| Proportional breakdown | Pie |
| Branching/release strategy | Git Graph |
| Brainstorm/concept map | Mindmap |
| Chronological milestones | Timeline |
| UX flow with satisfaction | Journey |
| Priority/comparison matrix | Quadrant |
| High-level architecture | C4 Context |
| Numerical data plots | XY Chart |
| Formal requirements | Requirement |
| Resource/data flows | Sankey |
| Component spatial layout | Block |
