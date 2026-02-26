# Agent-Skills

A curated repository of agent skills for GitHub Copilot CLI, following the open [Agent Skills](https://agentskills.io) standard.

Skills are folders of instructions, scripts, and resources that Copilot loads dynamically to improve performance on specialized tasks. Each skill contains a `SKILL.md` file with YAML frontmatter and markdown instructions.

## Quick Install

### Personal Skills (shared across all projects)

**PowerShell (Windows):**
```powershell
.\install.ps1 -Target personal
```

**Bash (macOS/Linux):**
```bash
./install.sh personal
```

This copies all skills to `~/.copilot/skills/`.

### Project Skills (specific to a repository)

**PowerShell (Windows):**
```powershell
.\install.ps1 -Target project
```

**Bash (macOS/Linux):**
```bash
./install.sh project
```

This copies all skills to `.github/skills/` in your current repository.

### Manual Install

Copy individual skill folders into either location:
```bash
# Personal (all projects)
cp -r skills/frontend-design ~/.copilot/skills/

# Project (single repo)
cp -r skills/frontend-design .github/skills/
```

## Using Skills

Skills are activated automatically by Copilot CLI based on your prompt and the skill's description. You can also invoke a skill explicitly:

```
Use the /frontend-design skill to create a responsive navigation bar.
```

### Skills Commands

| Command | Description |
|---------|-------------|
| `/skills list` | List available skills |
| `/skills` | Toggle skills on/off |
| `/skills info` | Details about a skill |
| `/skills reload` | Reload after adding skills |

## Skill Catalog

### Creative & Design
| Skill | Description |
|-------|-------------|
| [algorithmic-art](skills/algorithmic-art/) | Create generative algorithmic art and creative coding projects |
| [brand-guidelines](skills/brand-guidelines/) | Apply brand guidelines to designs and content |
| [canvas-design](skills/canvas-design/) | Design canvas-based visual layouts and compositions |
| [frontend-design](skills/frontend-design/) | Create distinctive, production-grade frontend interfaces |
| [slack-gif-creator](skills/slack-gif-creator/) | Create custom animated GIFs for Slack |
| [theme-factory](skills/theme-factory/) | Generate cohesive design themes and style systems |
| [web-artifacts-builder](skills/web-artifacts-builder/) | Build interactive web artifacts and components |

### Document Skills
| Skill | Description |
|-------|-------------|
| [docx](skills/docx/) | Create and edit Word documents programmatically |
| [pdf](skills/pdf/) | Create, edit, and extract data from PDF files |
| [pdftk-server](skills/pdftk-server/) | Merge, split, rotate, encrypt PDFs with PDFtk |
| [pptx](skills/pptx/) | Create and edit PowerPoint presentations |
| [xlsx](skills/xlsx/) | Create and edit Excel spreadsheets |

### Development & Technical
| Skill | Description |
|-------|-------------|
| [gh-cli](skills/gh-cli/) | Comprehensive GitHub CLI (gh) reference |
| [mcp-builder](skills/mcp-builder/) | Build MCP servers for LLM tool integration |
| [webapp-testing](skills/webapp-testing/) | Test web applications with Playwright automation |

### Data & Analytics
| Skill | Description |
|-------|-------------|
| [power-bi-dax-optimization](skills/power-bi-dax-optimization/) | Optimize Power BI DAX formulas for performance |
| [power-bi-model-design-review](skills/power-bi-model-design-review/) | Review Power BI data model architecture |
| [power-bi-report-design-consultation](skills/power-bi-report-design-consultation/) | Design effective Power BI report visualizations |
| [powerbi-modeling](skills/powerbi-modeling/) | Build optimized Power BI semantic models |

### Database
| Skill | Description |
|-------|-------------|
| [sql-code-review](skills/sql-code-review/) | SQL code review for security, performance, quality |
| [sql-optimization](skills/sql-optimization/) | SQL query performance optimization across all databases |

### Healthcare / EDW
| Skill | Description |
|-------|-------------|
| [costanduse-insights](skills/costanduse-insights/) | Analyze Evolent PSA Cost & Use data, variance decomposition, driver classification, and monthly narrative generation |
| [costanduse-reporting](skills/costanduse-reporting/) | Build and maintain Evolent PSA Cost & Use dashboards (Power BI and Streamlit) with metrics, DAX patterns, and data models |
| [edw-auth-reporting](skills/edw-auth-reporting/) | Navigate EDW Auth reporting views, CIR tables, membership/eligibility, QPP scoring, and drug pricing |
| [edw-cost-and-use](skills/edw-cost-and-use/) | EDW expert for Cost & Use oncology BI reporting — AllPayers claims/membership tables, per-client pipelines, VBI logic, and benchmarks |

### Enterprise & Communication
| Skill | Description |
|-------|-------------|
| [doc-coauthoring](skills/doc-coauthoring/) | Collaborative document authoring workflows |
| [internal-comms](skills/internal-comms/) | Draft internal communications and announcements |
| [prd](skills/prd/) | Generate Product Requirements Documents |

### Meta / Tooling
| Skill | Description |
|-------|-------------|
| [skill-creator](skills/skill-creator/) | Create, test, and improve new skills for Copilot CLI |

## Sources & Attribution

Skills in this repository are curated from:
- [anthropics/skills](https://github.com/anthropics/skills) — Anthropic's official skill examples (Apache 2.0, except document skills which are source-available)
- [github/awesome-copilot](https://github.com/github/awesome-copilot) — Community collection for GitHub Copilot (MIT)
- [Agent Skills Standard](https://agentskills.io) — Open format specification

## License

Skills sourced from `anthropics/skills` retain their original licenses (Apache 2.0 for most; see individual LICENSE.txt files for document skills). Skills from `github/awesome-copilot` are under MIT. See individual skill directories for details.
