# Formatting Guide

Detailed examples of formatting elements supported by the GerdsenAI Document Builder.

## Code Block Examples

### Diff Block
```diff
- removed line (red text on dark background)
+ added line (green text on dark background)
  context line (gray text)
@@ -1,3 +1,4 @@ hunk header (blue text)
```

### Tree/Directory Block
```tree
project/
  src/
    main.py
    utils/
      helpers.py
  tests/
    test_main.py
  README.md
```

Directories are displayed in yellow, files in gray, tree characters (`/`, `|`, etc.) in blue.

### Shell/Terminal Block
```shell
$ pip install gerdsenai-builder
Installing collected packages: gerdsenai-builder
Successfully installed gerdsenai-builder-1.0.0
```

Green prompt (`$`), green commands, teal output on a black background.

### Python Block
```python
def build_document(path: str) -> str:
    """Build a PDF from a markdown file."""
    builder = DocumentBuilder()
    return builder.build(path)
```

### YAML Block
```yaml
config:
  page_size: A4
  margins:
    top: 25
    bottom: 25
```

### JSON Block
```json
{
  "name": "example",
  "version": "1.0.0",
  "dependencies": {}
}
```

## Mermaid Diagram Examples

### Flowchart
```mermaid
flowchart TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great]
    B -->|No| D[Debug]
    D --> B
    C --> E[Ship it]
```

### Sequence Diagram
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

### Gantt Chart
```mermaid
gantt
    title Project Timeline
    dateFormat YYYY-MM-DD
    section Design
    Wireframes     :a1, 2026-01-01, 14d
    Prototypes     :a2, after a1, 7d
    section Build
    Backend        :b1, after a2, 21d
    Frontend       :b2, after a2, 21d
    section Test
    QA Testing     :c1, after b1, 14d
```

### Pie Chart
```mermaid
pie title Traffic Sources
    "Organic Search" : 45
    "Direct" : 25
    "Social Media" : 20
    "Referral" : 10
```

### State Diagram
```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Review
    Review --> Approved
    Review --> Draft : Changes Requested
    Approved --> Published
    Published --> [*]
```

### Entity Relationship
```mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
    PRODUCT ||--o{ LINE_ITEM : "ordered in"
```

### User Journey
```mermaid
journey
    title User Onboarding
    section Sign Up
      Visit site: 5: User
      Fill form: 3: User
      Verify email: 2: User
    section First Use
      Dashboard tour: 4: User
      Create first item: 5: User
```

### Class Diagram
```mermaid
classDiagram
    class User {
        +String name
        +String email
        +login() bool
    }
    class Admin {
        +manageUsers() void
    }
    User <|-- Admin : inherits
    User "1" --> "*" Order : places
```

### Mindmap
```mermaid
mindmap
    root((Project))
        Frontend
            React
            TypeScript
        Backend
            Node.js
            PostgreSQL
        Infrastructure
            Docker
            CI/CD
```

### Timeline
```mermaid
timeline
    title Product Roadmap 2026
    section Q1
        January : MVP Launch
        March : Public Beta
    section Q2
        April : GA Release
        June : International Launch
```

### Git Graph
```mermaid
gitGraph
    commit id: "init"
    branch develop
    commit id: "feature-a"
    checkout main
    merge develop tag: "v1.0.0"
```

### Quadrant Chart
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
    API Rewrite: [0.8, 0.85]
    Dark Mode: [0.2, 0.4]
```

### C4 Context Diagram
```mermaid
C4Context
    title System Context
    Person(user, "End User", "Uses the app")
    System(app, "Web App", "Main product")
    SystemDb(db, "Database", "PostgreSQL")
    Rel(user, app, "Uses", "HTTPS")
    Rel(app, db, "Reads/Writes", "TCP")
```

### XY Chart
```mermaid
xychart
    title "Monthly Revenue (K)"
    x-axis [Jan, Feb, Mar, Apr, May, Jun]
    y-axis "Revenue" 0 --> 100
    bar [45, 52, 48, 65, 72, 85]
    line [45, 52, 48, 65, 72, 85]
```

### Requirement Diagram
```mermaid
requirementDiagram
    requirement "User Auth" {
        id: REQ-001
        text: "Authenticate via OAuth 2.0"
        risk: medium
        verifymethod: test
    }
    element "Auth Service" {
        type: "software"
    }
    "Auth Service" - satisfies -> "User Auth"
```

### Sankey Diagram
```mermaid
sankey
    Revenue,Engineering,450
    Revenue,Marketing,250
    Revenue,Operations,200
    Engineering,Frontend,200
    Engineering,Backend,250
```

### Block Diagram (Beta)
```mermaid
block-beta
    columns 3
    Frontend:3
    block:backend:2
        API["API Gateway"]
        Auth["Auth Service"]
    end
    DB[("Database")]
```

## Table Formatting

### Simple Table
```markdown
| Feature | Status | Notes |
|---------|--------|-------|
| Auth | Done | OAuth 2.0 |
| API | In Progress | REST endpoints |
| UI | Planned | React frontend |
```

### Wide Table
Keep total column widths reasonable. The builder wraps text within cells, but very wide tables may be compressed. Prefer 3-5 columns.

## Image Inclusion

```markdown
![Architecture Diagram](Assets/architecture.png)
```

- Supported formats: PNG, JPG, JPEG, SVG
- Images are scaled to fit within page margins
- Place images in the Document Builder's `Assets/` directory or use absolute paths
- SVG images are converted to raster for PDF embedding

## Horizontal Rules and Page Breaks

A horizontal rule (`---`) creates a visual separator but does NOT force a page break when used within the document body (it only acts as front matter delimiters at the very start of the file).

To force a page break:
```markdown
<!-- pagebreak -->
```

## Text Formatting

Standard markdown inline formatting works:
- **Bold**: `**text**`
- *Italic*: `*text*`
- `Inline code`: `` `code` ``
- [Links](url): `[text](url)` - rendered in the accent color (default: `#3498db`)
- ~~Strikethrough~~: `~~text~~`

## Blockquotes

```markdown
> This is a blockquote. It will be rendered with a left border
> and slightly indented from the main text.
```
