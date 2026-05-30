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
4. **Existing copy** — Current site, marketing materials, internal docs
5. **Competitor pages** — Direct competitors' sites, their messaging, positioning, and gaps
6. **Data files** — Locations, pricing, FAQs, testimonials, team bios — anything structured
7. **Constraints** — Pre-launch? Pricing TBD? Missing photography? Legal requirements?

Sources: AGENTS.md, README.md, existing page files, data modules, brand guides,
and conversation context.

## Audience model

After gathering inputs, define the audience before writing a word. Produce a
short profile for each distinct audience segment the page must address:

- **Who they are** — Role, situation, level of awareness of the problem/product
- **What they already believe** — Assumptions, prior experiences, mental models
- **What objections they carry** — Reasons they might leave without acting
- **What language they use** — How they describe the problem in their own words

Reference the relevant audience segment in each section's intent annotation
(e.g., "This section targets first-time visitors who don't yet understand what
the product does"). If a section doesn't clearly serve at least one segment,
question whether it belongs.

## Voice calibration

Before drafting, establish the page's voice concretely — not just "casual" or
"professional," which mean different things to different people.

1. Write 3 sample sentences in the proposed voice, covering different tones the
   page will need (e.g., a hero headline, an explanatory paragraph, an FAQ
   answer).
2. Present these to the user for confirmation. Adjust until the voice feels
   right.
3. Write all copy in the calibrated voice. If voice drifts between sections,
   catch it in review.

## Competitive messaging analysis

If competitor pages are available (from inputs or by crawling), analyze them
before drafting:

1. Note each competitor's headline, value proposition, and primary CTA
2. Identify messaging patterns — what claims do they all make?
3. Find gaps — what do competitors fail to say, underemphasize, or get wrong?
4. Use this to sharpen the wireframe's positioning — lean into the gaps

Summarize findings in a short "Competitive landscape" section at the top of the
wireframe document, before the page sections begin. This gives the user context
for why certain messaging choices were made.

## Output format

Produce a single markdown file (e.g., `HOMEPAGE-WIREFRAME.md`) that reads top to
bottom like a visitor scrolling the page.

### Section template

Every section must have an intent annotation and real copy. The structure below
each intent adapts to the content type — not every section is headline + paragraph.

```markdown
## [N]. [Section Name]

> **Intent:** What is this section's job? What should the visitor understand,
> feel, or do after reading it? Which audience segment does this serve?
>
> **Density:** [Light | Medium | Dense] — see guidance below

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

#### Variant structures

Not all sections fit the headline → copy → CTA mold. Use the appropriate
structure for the content:

- **Data sections** (pricing, specs, comparisons): Use tables or structured
  lists. Write column headers, row labels, and footnotes as real copy.
- **Multi-item sections** (features, team members, locations): Write the
  section-level headline and intro, then each item as a named entry with its
  own copy.
- **Media-anchored sections** (hero image, video, demo): Describe the media
  asset needed (subject, mood, what it should communicate) and write any
  overlay text, captions, or surrounding copy.
- **Interactive sections** (calculators, configurators, maps): Describe the
  interaction, write all labels and microcopy, and note what inputs/outputs
  the user sees.

#### Copy density guidance

Match density to the section's job:

| Density | When to use | Typical length |
|---------|------------|----------------|
| **Light** | Hero, closing CTA, navigation — sections that rely on a few precise words | 1-2 sentences, a single headline, or just labels |
| **Medium** | Value proposition, how-it-works, about — sections that explain or persuade | 1-3 short paragraphs or a headline + supporting bullets |
| **Dense** | FAQ, pricing details, product specs — sections where visitors come to get answers | As long as needed, but structured with headers, tables, or lists |

### Sections to consider

Starting checklist — not a fixed template. Adapt aggressively based on the
page type. A SaaS landing page and a local restaurant homepage share almost
none of these in equal proportion.

**Load-bearing sections** — these carry the conversion argument. Spend the
most drafting effort here:

| Section | Job |
|---------|-----|
| Hero / Opening | Identify + hook — answer "what is this?" in 5 seconds |
| Value proposition | Why this company over alternatives |
| Closing CTA | Final conversion or connection push |

**Supporting sections** — these build toward conversion but don't carry it
alone. Include based on what the audience needs:

| Section | Job |
|---------|-----|
| Navigation | Orient visitors, surface the primary action |
| How it works | Reduce anxiety about the process |
| Product / Service details | Inform the purchase decision |
| Social proof | Build trust (testimonials, ratings, logos, history) |
| FAQ | Catch remaining objections |
| Story / About | Emotional connection and differentiation |

**Structural sections** — necessary but rarely decisive:

| Section | Job |
|---------|-----|
| Locations / Contact info | Logistics and reachability |
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
- **Consolidate proof points by default.** Prefer grouping trust signals so the
  case is made once, clearly. Exception: when a specific feature or claim
  benefits from an adjacent testimonial or data point, place it there and note
  why in the intent annotation.
- **SEO is out of scope.** This skill produces copy optimized for the reader,
  not for search engines. If keyword placement matters, flag it as an open
  decision for the user to address separately or with an SEO-focused tool.

## Workflow

### Phase 1: Research

1. Read all available context (project docs, existing pages, data files, brand guides)
2. Build the audience model (see above)
3. Analyze competitor messaging if competitor pages are available
4. Calibrate voice with sample sentences and get user confirmation

### Phase 2: Draft

1. Write the competitive landscape summary (if applicable)
2. Draft the wireframe following the section template above
3. Write real copy for every heading, paragraph, and CTA
4. Annotate each section with intent, audience segment, and density
5. Flag open decisions inline
6. Collect all open decisions into the closing checklist

### Phase 3: Review

Present the wireframe to the user. They read it, react, rewrite sections,
and resolve open decisions. Iterate until every word feels right and every
section earns its place.

Do not proceed to implementation until the user explicitly approves the copy.

### Handoff

Once approved, the wireframe is the spec for implementation. Hand it to the
design or implementation skill of your choice. The wireframe itself makes no
layout, visual, or code decisions — that's the implementer's job.

## Anti-patterns

- **Writing copy to fill a design.** The whole point of this exercise is to
  avoid that. If you catch yourself thinking about column counts or card
  layouts while writing copy, stop.
- **Skipping intent annotations.** These are the most valuable part. They
  force clarity about why each section exists.
- **Burying open questions.** Surface them inline AND in the collected list
  at the end. The user should never be surprised by an assumption you made.
- **Perfectionism in the first draft.** The draft is meant to be reacted to,
  not shipped. Write your best guess and let the user correct it.
