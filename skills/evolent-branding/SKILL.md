---
name: evolent-branding
description: >
  Evolent Health (NYSE: EVH) corporate brand system for creating on-brand deliverables.
  Use this skill whenever creating presentations, documents, reports, slides, HTML pages,
  emails, one-pagers, executive summaries, analytics deliverables, or any visual/written
  content that should follow Evolent's brand identity. Trigger on any mention of "Evolent,"
  "Evolent-branded," "EVH," "on-brand for Evolent," "company template," "Evolent deck,"
  "Evolent slide," or when the user is known to work at Evolent and requests professional
  deliverables. Also use when the user asks about Evolent's colors, fonts, logo usage,
  brand guidelines, or visual identity. Even if the user just says "make it look like our
  other decks" or "use the company branding" and they work at Evolent, use this skill.
---

# Evolent Brand System

Evolent rebranded in July 2023, unifying legacy sub-brands (New Century Health, NIA, IPG, Vital Decisions) under one identity. The brand communicates clinical authority, technological sophistication, and connected care across specialties.

**Tagline:** Specializing in Connected Care™

This skill covers everything needed to produce on-brand Evolent deliverables: color palette, typography, gradient system, slide design, document formatting, and tone of voice.

## Color Palette

### Primary Colors

| Role | Name | Hex | RGB | Usage |
|------|------|-----|-----|-------|
| **Primary Dark** | Evolent Navy | `#020623` | 2, 6, 35 | Headings, primary text, dark backgrounds, title slides |
| **White** | White | `#FFFFFF` | 255, 255, 255 | Content backgrounds, reversed text on dark |
| **Brand Purple** | Evolent Plum | `#7B1C92` | 123, 28, 146 | Secondary accent, followed hyperlinks, callout backgrounds |
| **Cool Gray** | Evolent Gray | `#9FA7AE` | 159, 167, 174 | Subtitle text, light 2 theme role |
| **Footer Gray** | Mid Gray | `#89898C` | 137, 137, 140 | Footer text, confidentiality notices, muted captions |

### The Signature Gradient Ramp

The gradient is Evolent's most distinctive visual element — a smooth left-to-right progression from deep purple through blues to cyan/mint. It appears as a thin accent bar across the top of slides and as a decorative element in digital materials.

**Gradient stops (left → right):**

| Position | Hex | Color Name |
|----------|-----|------------|
| 0% | `#5D3791` | Deep Purple (Accent 1) |
| ~15% | `#692483` | Purple (intermediate) |
| ~25% | `#7B1C92` | Plum (Dark 2) |
| ~35% | `#4C51A6` | Purple-Blue (Accent 2) |
| ~50% | `#3475C1` | Medium Blue (Accent 3) |
| ~65% | `#17A5E6` | Sky Blue (Accent 4) |
| ~75% | `#09C9EE` | Light Cyan (intermediate) |
| ~85% | `#08DCE2` | Cyan (Accent 5) |
| 100% | `#08F0D4` | Mint/Aqua (Accent 6) |

**CSS gradient equivalent:**
```css
background: linear-gradient(to right, #5D3791, #692483, #4C51A6, #3475C1, #17A5E6, #09C9EE, #08DCE2, #08F0D4);
```

**When to use the gradient:**
- Thin top bar on presentation slides (the primary application)
- Section dividers in long documents
- Header accents on HTML reports and dashboards
- Background accent on title/cover slides

**When NOT to use the gradient:**
- As a background behind body text (readability issues)
- On every element (overuse dilutes impact)
- Vertically (the brand uses it horizontally, left to right)

### Accent Colors for Charts & Data Visualization

When building charts, tables, or data callouts, use the accent colors in order of priority:

1. `#5D3791` Deep Purple — primary data series
2. `#3475C1` Medium Blue — secondary data series
3. `#17A5E6` Sky Blue — tertiary data series
4. `#08DCE2` Cyan — quaternary data series
5. `#4C51A6` Purple-Blue — fifth series
6. `#08F0D4` Mint — sixth series
7. `#7B1C92` Plum — for emphasis callouts or negative/alert values
8. `#89898C` Mid Gray — benchmark lines, axis labels, gridlines

For positive/negative indicators, use `#08F0D4` (mint) for positive and `#7B1C92` (plum) for negative or caution.

## Typography

| Element | Font | Weight | Size (presentations) | Size (documents) |
|---------|------|--------|---------------------|-------------------|
| Slide title | Arial | Bold | 36–44pt | — |
| Section header | Arial | Bold | 20–24pt | 16–18pt |
| Body text | Arial | Regular | 14–16pt | 11pt |
| Captions / footnotes | Arial | Regular | 10–12pt | 9pt |
| Footer / confidentiality | Arial | Regular | 8–10pt | 8pt |
| Large stat callouts | Arial | Bold | 48–72pt | — |

Both heading and body fonts are **Arial** — no exceptions. The brand does not use serif fonts, decorative fonts, or font substitutes like Helvetica or Calibri in final deliverables.

## Presentation Design

### Template Asset

A branded Evolent PPTX template is bundled at `assets/evolent-template.pptx`. It contains 26 slide layouts with the gradient bar, footer, and color scheme pre-configured. When creating presentations, use this template as a base whenever possible (read the pptx skill's editing.md for template-based workflows).

### Slide Architecture

**Standard slide anatomy:**
- **Top gradient bar:** Thin (approximately 8px height) full-width gradient strip at the very top edge of every slide
- **Content area:** White background, generous margins (0.5"+ from edges)
- **Footer:** Right-aligned, bottom of slide: `Evolent  |  Confidential—Do not distribute  |  [page#]` in `#89898C` at 8–10pt

**Title/cover slides:**
- Can use the dark navy `#020623` as a full background
- White text for headings
- Gradient bar still appears at top
- Logo placement: lower-left or centered

**Content slides:**
- White background
- Heading in `#020623` Evolent Navy, left-aligned
- Body text in `#020623` or `#89898C` for secondary
- Use accent colors for emphasis, not for body text

**Data/analytics slides:**
- Lead with a large stat callout (48–72pt bold number in deep purple or navy)
- Supporting context in 14–16pt below
- Charts use the accent color sequence defined above
- Source citations in `#89898C` at 8–10pt, bottom of chart area

### Layout Variety

Avoid repeating the same layout. Rotate through these patterns:
- Two-column: text left, visual right (or inverted)
- Icon + text rows: colored circle icon, bold header, description
- 2×2 or 2×3 grid: info cards with subtle borders
- Large stat + context: oversized number with supporting detail
- Full-width table: for comparison data
- Timeline / process flow: numbered steps with accent color markers

### Things to Avoid in Presentations

- Accent lines under titles (looks generic/AI-generated)
- Centered body text (left-align paragraphs; center only titles)
- All-white text-only slides with no visual elements
- Using colors outside the defined palette
- Calibri, Aptos, or any non-Arial font
- Placing content over the gradient bar
- Excessive bold or ALL CAPS in body text

## Document Design (Word, PDF, Markdown)

### Headers and Structure

- Document title: Arial Bold, 24pt, `#020623`
- H1 / Section headers: Arial Bold, 16–18pt, `#020623`
- H2 / Subsection: Arial Bold, 13–14pt, `#5D3791` (deep purple)
- Body: Arial Regular, 11pt, `#020623`
- Captions and footnotes: Arial Regular, 9pt, `#89898C`

### Page Elements

- **Header bar:** A thin gradient line (matching the presentation gradient) can be placed at the top of the first page or as a section divider
- **Footer:** "Evolent | Confidential—Do not distribute" left-aligned, page number right-aligned, in `#89898C`
- **Tables:** Header row in `#020623` background with white text; alternating row shading in very light gray (`#F5F5F7`) and white; border color `#9FA7AE`
- **Hyperlinks:** `#3475C1` (medium blue), matching the theme hyperlink color

### Confidentiality Notice

All external-facing documents should include:
```
Evolent  |  Confidential—Do not distribute
```
Internal documents may omit this if explicitly marked for internal circulation only.

## HTML & Digital Design

When creating HTML artifacts, dashboards, or web-based reports:

```css
:root {
  /* Primary */
  --evolent-navy: #020623;
  --evolent-white: #FFFFFF;
  --evolent-plum: #7B1C92;
  --evolent-gray: #9FA7AE;
  --evolent-mid-gray: #89898C;

  /* Gradient accent ramp */
  --evolent-deep-purple: #5D3791;
  --evolent-purple-blue: #4C51A6;
  --evolent-blue: #3475C1;
  --evolent-sky-blue: #17A5E6;
  --evolent-cyan: #08DCE2;
  --evolent-mint: #08F0D4;

  /* Functional */
  --evolent-link: #3475C1;
  --evolent-positive: #08F0D4;
  --evolent-caution: #7B1C92;
  --evolent-border: #9FA7AE;
  --evolent-bg-alt: #F5F5F7;

  /* Typography */
  --font-primary: Arial, Helvetica, sans-serif;
}

/* Gradient bar utility */
.evolent-gradient-bar {
  height: 4px;
  background: linear-gradient(to right, #5D3791, #692483, #4C51A6, #3475C1, #17A5E6, #09C9EE, #08DCE2, #08F0D4);
}
```

### HTML/React Patterns

- Use `font-family: Arial, Helvetica, sans-serif` (Helvetica as web fallback only)
- Page background: white; dark navy for hero sections or footers
- The gradient bar works well as a 4px top border on cards, a page-top accent, or a progress indicator
- For Tailwind users: configure custom colors matching the palette above; the gradient stops require `bg-gradient-to-r` with custom color stops

## Tone of Voice

Evolent's written voice is:
- **Clinical authority with warmth** — technically precise but not cold or jargon-heavy
- **Outcome-focused** — lead with results, savings, and patient impact
- **Collaborative** — "we" and "our" when discussing work with partners; never adversarial toward providers or plans
- **Measured confidence** — assert expertise without arrogance; back claims with data
- **Active voice preferred** — "Evolent reduces costs" not "costs are reduced by Evolent"

### Common Phrasing

| Use | Avoid |
|-----|-------|
| health plan members | patients (when referring to plan context) |
| clinical pathways | clinical protocols (pathways is the brand term) |
| value-based specialty care | managed care (unless quoting external sources) |
| health outcomes | clinical outcomes (unless specifically clinical) |
| connected care | integrated care (connected is the brand term) |
| Evolent (standalone) | Evolent Health (retired in 2023 rebrand) |

### Analytics Deliverables

When producing analytics reports, performance summaries, or opportunity analyses for Evolent:
- Lead with the business impact (dollars, percentages, member counts)
- Use the defined chart color sequence for consistency across deliverables
- Include methodology footnotes for any projected or modeled figures
- Label data sources explicitly
- Use the confidentiality footer on every page/slide

## Quick Reference Card

**Must-haves for any Evolent deliverable:**
1. Arial font throughout (no exceptions)
2. Gradient bar accent (top of slides, top of first page, or section divider)
3. Color palette adherence (navy, purple-to-mint gradient, grays)
4. Confidentiality footer on external materials
5. "Evolent" (not "Evolent Health") in all new materials

**Color cheat sheet for rapid use:**
- Navy (text/headings): `#020623`
- Deep purple (accent 1): `#5D3791`
- Blue (links/accent 3): `#3475C1`
- Cyan (accent 5): `#08DCE2`
- Mint (accent 6): `#08F0D4`
- Footer gray: `#89898C`
- Cool gray: `#9FA7AE`
