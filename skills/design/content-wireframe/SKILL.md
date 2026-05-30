---
name: content-wireframe
description: >-
  Draft a content wireframe for a website or page before any design or code.
  Produces a structured markdown document with real copy, section intent, and
  open decisions — approved by the user before implementation begins. Use when
  the user says "content first", "wireframe the copy", "words before design",
  "start with the content", "what should the page say", or when a website
  project lacks finalized copy and is jumping straight to visuals.
---

# Content Wireframe

Write every word a page needs — in order, with intent annotations — before
touching layout, color, or code. The wireframe is the blueprint; design follows.

## When to use

- New website or landing page where copy hasn't been written
- Redesign where the existing page was built design-outward and the words feel secondary
- Any project where the user is unhappy with the "feel" but can't articulate why (often a content problem, not a design problem)

## Inputs to gather

Before drafting, collect as much of the following as possible:

1. **Business context** — What does the company do? Who are the customers?
2. **Primary goal** — What is the single most important action a visitor should take?
3. **Brand voice** — Formal/casual? Technical/approachable? Any existing style guide?
4. **Existing copy** — Current site, competitor sites, marketing materials, internal docs
5. **Data files** — Locations, pricing, FAQs, testimonials, team bios — anything structured
6. **Constraints** — Pre-launch? Pricing TBD? Missing photography? Legal requirements?

Sources: AGENTS.md, README.md, existing page files, data modules, brand guides,
competitor crawls, and conversation context.

## Output format

Produce a single markdown file (e.g., `HOMEPAGE-WIREFRAME.md`) that reads top to
bottom like a visitor scrolling the page.

### Section template

For every section, include:

```markdown
## [N]. [Section Name]

> **Intent:** What is this section's job? What should the visitor understand,
> feel, or do after reading it?

### Headline

[The actual headline words]

### Copy

[The actual paragraphs, bullets, labels — real words, not lorem ipsum]

### CTA

[Exact button/link text] → [destination]

> **Open question:** [Any decision the user needs to make — phrasing alternatives,
> missing info, things to confirm with stakeholders]
>
> **Content note:** [Constraints, dependencies, or context that affects this section]
```

Omit sub-sections that don't apply (e.g., not every section has a CTA).

### Required sections to consider

These are common for most websites. Include or exclude based on the project:

| Section | Job |
|---------|-----|
| Navigation | Orient visitors, surface the primary action |
| Hero / Opening | Identify + hook — answer "what is this?" in 5 seconds |
| Value proposition | Why this company over alternatives |
| How it works | Reduce anxiety about the process |
| Product / Service details | Inform the purchase decision |
| Social proof | Build trust (testimonials, ratings, logos, history) |
| Locations / Contact info | Logistics and reachability |
| FAQ | Catch remaining objections |
| Story / About | Emotional connection and differentiation |
| Closing CTA | Final conversion or connection push |
| Footer | Reference info, legal, secondary links |

### End with collected decisions

Close the wireframe with a numbered list of every open question and content
decision surfaced throughout the document. This gives the user a single
checklist to work through.

```markdown
## Open decisions (collected)

1. **[Topic]:** [Question or choice to resolve]
2. **[Topic]:** [Question or choice to resolve]
...
```

## Principles

- **Real words only.** Never use placeholder text. If you don't know the right
  words yet, write your best guess and flag it as an open question.
- **No design decisions.** No colors, fonts, sizes, layouts, components, or
  code. The wireframe is a reading experience, not a visual one.
- **Every section earns its place.** If a section doesn't serve the primary
  goal or build toward conversion, question whether it belongs on this page.
- **Intent before content.** Write the intent annotation first. If you can't
  articulate what a section's job is, it probably shouldn't exist.
- **Flag, don't assume.** When you hit a decision that depends on the user's
  judgment (brand tone, pricing strategy, what photo to use), surface it as
  an open question rather than making the call silently.
- **Consolidate proof points.** Don't scatter trust signals across the page.
  Group them so the case is made once, clearly.

## Workflow

### Phase 1: Draft

1. Read all available context (project docs, existing pages, data files, brand guides)
2. Draft the wireframe following the section template above
3. Write real copy for every heading, paragraph, and CTA
4. Annotate each section with intent and flag open decisions
5. Collect all open decisions into the closing checklist

### Phase 2: Review

Present the wireframe to the user. They read it, react, rewrite sections,
and resolve open decisions. Iterate until every word feels right and every
section earns its place.

Do not proceed to implementation until the user explicitly approves the copy.

### Phase 3: Implement

Once approved:

1. Strip the target page down to a clean semantic skeleton
2. Drop in the approved copy with minimal, clean markup
3. Apply existing design tokens (typography, spacing, colors) without
   inventing new visual treatments
4. Let the content dictate the layout — not the other way around

## Anti-patterns

- **Writing copy to fill a design.** The whole point of this exercise is to
  avoid that. If you catch yourself thinking about column counts or card
  layouts while writing copy, stop.
- **Skipping intent annotations.** These are the most valuable part. They
  force clarity about why each section exists.
- **Burying open questions.** Surface them inline AND in the collected list
  at the end. The user should never be surprised by an assumption you made.
- **Perfectionism in Phase 1.** The first draft is meant to be reacted to,
  not shipped. Write your best guess and let the user correct it.
