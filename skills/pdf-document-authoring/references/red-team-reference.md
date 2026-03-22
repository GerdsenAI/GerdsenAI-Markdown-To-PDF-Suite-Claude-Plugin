# Red Team Review Reference

Adversarial quality assurance protocol for AI-generated documents. The red team agent applies dialectical reasoning to challenge factual claims, identify logical weaknesses, and verify citation integrity before a document is built to PDF.

## Challenge Categories

The red team reviewer evaluates a document across six categories, in order of severity:

### 1. Factual Accuracy

Challenge any claim that:
- States a specific number, percentage, date, or measurement without a citation
- Attributes a position or quote to a named person or organization without a source
- Makes a comparative claim ("X is faster than Y") without quantitative evidence
- Presents a prediction or forecast without identifying its source methodology

**Verification method**: Search the web for the specific claim. If the claim cannot be corroborated by at least one independent source, flag it.

### 2. Logical Consistency

Challenge any reasoning that:
- Draws a conclusion that does not follow from the stated premises (non sequitur)
- Generalizes from a single example or anecdote to a broad claim (hasty generalization)
- Presents a false dichotomy (only two options when more exist)
- Uses circular reasoning (the conclusion restates a premise)
- Conflates correlation with causation
- Contains contradictions between sections (Section 3 says X, Section 7 says not-X)

**Verification method**: Read the argument structure. Map premises to conclusions. Flag gaps.

### 3. Source Quality

Challenge any citation that:
- Comes from a press release, marketing material, or vendor white paper presented as objective analysis
- Is more than 3 years old for fast-moving topics (technology, markets, policy)
- Is a blog post or social media post used as the sole source for a major claim
- Is from a source with an obvious conflict of interest (vendor recommending their own product)
- Cannot be verified (URL is malformed, domain does not exist, paywalled with no summary)

**Verification method**: Evaluate each citation against the source quality rubric below.

### 4. Citation Completeness

Challenge any section that:
- Contains factual claims with no in-text citation
- References a source number `[N]` that does not exist in Sources & References
- Has orphan citations (defined in References but never cited in text)
- Uses non-sequential citation numbering
- Has a source appearing multiple times under different citation numbers

**Verification method**: Cross-reference all `[N]` markers against the References section. Count uncited claims per section.

### 5. Unsupported Generalizations

Challenge any statement that:
- Uses absolute language ("always", "never", "all", "none") without exhaustive evidence
- Claims consensus ("experts agree", "the industry has concluded") without survey or meta-analysis data
- Extrapolates a trend beyond the data range without acknowledging uncertainty
- Presents an opinion as fact without attribution

**Verification method**: Flag absolute language. Check whether the evidence supports the strength of the claim.

### 6. Statistical Claims

Challenge any use of statistics that:
- Presents a percentage without a base (denominator) -- "40% of users" (of how many?)
- Compares numbers from different time periods or methodologies without noting the difference
- Uses averages without indicating variance or distribution shape
- Cites a projected figure as if it were an observed measurement
- Cherry-picks a favorable time window for trend data

**Verification method**: Check that every statistic has a source, a base, and a time frame.

---

## Severity Levels

Each challenge is assigned one of three severity levels:

### BLOCK

The document MUST NOT be built until this challenge is resolved. Reserved for:
- A factual claim that is demonstrably false based on available evidence
- A citation that does not exist or points to a completely unrelated source
- A logical contradiction between two sections of the same document
- A statistical claim with no source that is central to a recommendation

**Resolution requirement**: The authoring agent must either correct the claim, add a supporting citation, or remove the claim entirely.

### WARN

The document may be built, but the affected passage should be annotated. Reserved for:
- A claim supported by only a single source (could be more robust)
- A source that is borderline quality (vendor-adjacent but contains real data)
- A generalization that is reasonable but uses stronger language than the evidence supports
- A minor logical gap that does not undermine the overall argument

**Resolution requirement**: The authoring agent should add a qualifying phrase (e.g., "based on limited available data") or add a second source. If neither is possible, note the limitation in the Methodology section.

### NOTE

No action required before building. Informational feedback for quality improvement. Reserved for:
- Stylistic suggestions (a claim could be stated more precisely)
- Minor source recency concerns (source is 2-3 years old but the topic is not fast-moving)
- Opportunities to add a visualization that would strengthen the argument
- Section balance observations (one section is significantly longer/shorter than peers)

---

## Review Output Format

The red team agent produces a structured review with the following format:

```
## Red Team Review Summary

- **Total challenges**: N
- **BLOCK**: N (must fix)
- **WARN**: N (should address)
- **NOTE**: N (informational)
- **Sections reviewed**: N of N
- **Claims verified against external sources**: N

## BLOCK Challenges

### [B1] Section: <section name>
**Category**: <Factual Accuracy | Logical Consistency | Source Quality | Citation Completeness | Unsupported Generalization | Statistical Claim>
**Claim**: "<exact text of the challenged claim>"
**Challenge**: <why this claim is problematic>
**Evidence**: <what the reviewer found when checking>
**Suggested fix**: <specific revision or action>

### [B2] ...

## WARN Challenges

### [W1] Section: <section name>
**Category**: <category>
**Claim**: "<exact text>"
**Challenge**: <why this is a concern>
**Suggested fix**: <specific revision>

### [W2] ...

## NOTE Observations

### [N1] <observation>
### [N2] ...
```

---

## Source Quality Rubric

Rate each cited source on a 1-5 scale:

| Score | Label | Criteria |
|-------|-------|----------|
| 5 | Authoritative | Peer-reviewed journal, government agency, established research institution |
| 4 | Reliable | Major news outlet, established industry analyst (Gartner, Forrester), official documentation |
| 3 | Credible | Well-known technology blog, conference proceedings, reputable trade publication |
| 2 | Marginal | Personal blog with expertise indicators, vendor white paper with data, social media by known expert |
| 1 | Weak | Anonymous post, marketing material, unverifiable claim, dead link |

**Minimum standards for research reports:**
- Average source quality score across all citations should be >= 3.0
- No BLOCK-severity claim should rely solely on sources scored 1 or 2
- At least 30% of sources should score 4 or 5

---

## Review Methodology Section

When red team review is performed, the following subsection is added to the report's Methodology section:

```markdown
### Adversarial Quality Review

This report underwent automated adversarial review prior to publication. A separate
review agent independently evaluated all factual claims, logical arguments, source
quality, citation completeness, and statistical assertions. N challenges were raised
across N categories. All BLOCK-severity challenges were resolved before publication.
N claims were revised, N sources were added, and N unsupported assertions were removed
during the review process.
```

---

## Integration with Research Pipeline

The red team review step occurs between Step 5 (quality checklist pass) and Step 6 (build PDF) in the document builder agent workflow:

1. Authoring agent completes the markdown draft
2. Authoring agent runs the standard quality checklist (front matter, heading hierarchy, Mermaid labels, etc.)
3. **Red team reviewer agent** reads the completed draft
4. Reviewer produces the structured review output
5. Authoring agent receives the review and addresses:
   - All BLOCK challenges (mandatory -- revise, cite, or remove)
   - WARN challenges where feasible (add qualifiers, second sources)
   - Updates the Methodology section with the review summary
6. Build the revised PDF

The red team reviewer does NOT modify the document directly. It produces challenges. The authoring agent decides how to resolve each one.

---

## Standalone Red Team Command

The `/gerdsenai:red-team <file.md>` command runs the review against any markdown file, not just research reports. In standalone mode:

- The reviewer reads the file and produces the structured review output
- No automatic resolution occurs -- the review is presented to the user
- The user decides which challenges to address
- The user can then run `/gerdsenai:build` when satisfied

This enables red-teaming of user-authored documents, not just agent-authored ones.
