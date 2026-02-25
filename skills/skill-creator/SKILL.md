---
name: skill-creator
description: Create new skills for Copilot CLI, modify and improve existing skills, and measure skill quality. Use when users want to create a skill from scratch, update or optimize an existing skill, run test prompts to verify a skill, or optimize a skill's description for better triggering accuracy.
---

# Skill Creator

A skill for creating new skills for Copilot CLI and iteratively improving them.

At a high level, the process of creating a skill goes like this:

- Decide what you want the skill to do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run them with the skill loaded
- Help the user evaluate the results both qualitatively and quantitatively
  - While reviewing, draft some evaluation criteria if there aren't any. Then explain them to the user
  - Present the results directly in the conversation for the user to review, and also let them assess against the evaluation criteria
- Rewrite the skill based on feedback from the user's evaluation of the results
- Repeat until you're satisfied
- Expand the test set and try again at larger scale

Your job when using this skill is to figure out where the user is in this process and then jump in and help them progress through these stages. So for instance, maybe they're like "I want to make a skill for X". You can help narrow down what they mean, write a draft, write the test cases, figure out how they want to evaluate, run the prompts, and repeat.

On the other hand, maybe they already have a draft of the skill. In this case you can go straight to the eval/iterate part of the loop.

Of course, you should always be flexible and if the user is like "I don't need to run a bunch of evaluations, just vibe with me", you can do that instead.

Then after the skill is done (but again, the order is flexible), you can also help optimize the skill's description to improve triggering accuracy.

## Communicating with the user

The skill creator is liable to be used by people across a wide range of familiarity with coding jargon. There's a trend now where the power of AI assistants is inspiring plumbers to open up their terminals, parents and grandparents to google "how to install npm". On the other hand, the bulk of users are probably fairly computer-literate.

So please pay attention to context cues to understand how to phrase your communication! In the default case, just to give you some idea:

- "evaluation" and "benchmark" are borderline, but OK
- for "JSON" and "assertion" you want to see serious cues from the user that they know what those things are before using them without explaining them

It's OK to briefly explain terms if you're in doubt, and feel free to clarify terms with a short definition if you're unsure if the user will get it.

---

## Creating a skill

### Capture Intent

Start by understanding the user's intent. The current conversation might already contain a workflow the user wants to capture (e.g., they say "turn this into a skill"). If so, extract answers from the conversation history first — the tools used, the sequence of steps, corrections the user made, input/output formats observed. The user may need to fill the gaps, and should confirm before proceeding to the next step.

1. What should this skill enable Copilot to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases to verify the skill works? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, art) often don't need them. Suggest the appropriate default based on the skill type, but let the user decide.

### Interview and Research

Proactively ask questions about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until you've got this part ironed out.

If useful, research by searching docs, finding similar skills, or looking up best practices. Come prepared with context to reduce burden on the user.

### Write the SKILL.md

Based on the user interview, fill in these components:

- **name**: Skill identifier (lowercase, hyphens only, max 64 characters, must match directory name)
- **description**: When should this skill trigger? What does it do? (max 1024 characters). This is critical — it's what Copilot reads to decide whether to activate the skill
- **Body**: Step-by-step instructions, examples, edge cases, and any reference file pointers

Follow the [Agent Skills specification](https://agentskills.org) format:

```yaml
---
name: my-skill
description: Does X when user asks about Y. Use for Z scenarios.
---
```

Followed by Markdown body content with the skill's instructions.

#### Skill placement

Skills can be installed in two locations:

- **Personal skills**: `~/.copilot/skills/<name>/SKILL.md` — available to you in all projects
- **Project skills**: `.github/skills/<name>/SKILL.md` — shared with everyone working on the repo

Choose the appropriate location based on whether the skill is personal or team-wide.

#### Quality guidelines

Follow progressive disclosure to keep context usage efficient:

1. **Metadata** (~100 tokens): The `name` and `description` fields are loaded at startup for all skills
2. **Instructions** (< 5000 tokens recommended): The full `SKILL.md` body is loaded when the skill is activated
3. **Resources** (as needed): Files in `scripts/`, `references/`, or `assets/` are loaded only when required

Key rules:
- Keep `SKILL.md` under **500 lines**. Move detailed reference material to separate files (e.g., `references/REFERENCE.md`)
- Write a **good description** — it determines when the skill triggers. Include specific keywords and scenarios
- Use **relative paths** from the skill root when referencing other files
- Keep file references **one level deep** from `SKILL.md`

#### Optional directories

Your skill directory can include:

```
my-skill/
├── SKILL.md              # Required — instructions
├── scripts/              # Executable code the agent can run
├── references/           # Additional docs loaded on demand
└── assets/               # Templates, images, data files
```

### Writing the description

Descriptions should tell Copilot both **what the skill does** and **when to use it**. Include trigger phrases the user might say.

Good example:
```yaml
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.
```

Poor example:
```yaml
description: Helps with PDFs.
```

Tips for better descriptions:
- Include the main action verbs (extract, generate, convert, analyze)
- Mention specific file types, technologies, or domains
- Add "Use when..." clause with trigger scenarios
- Keep it natural — Copilot uses this to match user intent

---

## Testing the skill

### Create test prompts

Write 3–5 test prompts that cover the skill's core functionality:
- A straightforward happy-path case
- An edge case or unusual input
- A case that tests the skill's boundaries
- (Optional) A case that should NOT trigger the skill (to test description specificity)

### Running tests

To test a skill after writing it:

1. **Place the skill** in the appropriate directory (`~/.copilot/skills/<name>/` or `.github/skills/<name>/`)
2. **Reload skills**: Use `/skills reload` to pick up the new or modified skill
3. **Verify it loaded**: Use `/skills info` to confirm the skill appears and its description looks correct
4. **Run each test prompt**: Enter the test prompts in the conversation and observe whether:
   - The skill triggers when it should
   - The skill produces the expected output
   - The skill handles edge cases gracefully

### Reviewing results

For each test case, present the results directly in the conversation:
- Show the prompt and the output
- If the output is a file, save it and tell the user where it is so they can inspect it
- Ask for feedback inline: "How does this look? Anything you'd change?"

### Evaluation criteria

For skills with objectively verifiable outputs, define evaluation criteria:
- **Correctness**: Does the output match expected results?
- **Completeness**: Are all required elements present?
- **Format**: Does the output follow the specified format?
- **Edge cases**: Are unusual inputs handled gracefully?

Track results informally — a simple checklist or table in the conversation is fine.

---

## Iterating on the skill

### The improvement loop

1. Review test results and user feedback
2. Identify specific failure modes or areas for improvement
3. Make targeted edits to the SKILL.md (don't rewrite from scratch unless fundamentally broken)
4. Reload the skill with `/skills reload`
5. Re-run the failing test prompts
6. Repeat until the user is satisfied

### Common improvements

- **Skill doesn't trigger**: Improve the description with better keywords and trigger phrases
- **Output format wrong**: Add explicit format instructions and examples to the body
- **Missing edge cases**: Add handling instructions for the specific edge case
- **Too verbose/too terse**: Adjust the level of detail in instructions
- **Wrong tool usage**: Be more specific about which tools to use and when

### Description optimization

After the skill body is solid, optimize the description for triggering accuracy:

1. Collect examples of prompts that should trigger the skill
2. Collect examples of prompts that should NOT trigger it
3. Refine the description to maximize correct triggering and minimize false positives
4. Test with `/skills reload` and the collected prompts

---

## Sharing and packaging skills

### Sharing a personal skill

To share a skill you've created in `~/.copilot/skills/`:

1. Copy the entire skill directory (e.g., `my-skill/` with `SKILL.md` and any supporting files)
2. The recipient places it in their own `~/.copilot/skills/` directory
3. They run `/skills reload` to load it

### Adding a skill to a project

To make a skill available to everyone working on a repo:

1. Create the skill in `.github/skills/<name>/` in the repository
2. Commit and push the skill directory
3. Team members get the skill automatically when they pull the changes

### Skill directory checklist

Before sharing, verify:
- [ ] `SKILL.md` has valid YAML frontmatter with `name` and `description`
- [ ] `name` in frontmatter matches the directory name
- [ ] `name` is lowercase with hyphens only (no uppercase, spaces, or special characters)
- [ ] Description clearly explains what the skill does and when to trigger it
- [ ] `SKILL.md` is under 500 lines
- [ ] All referenced files (scripts, references, assets) are included in the directory
- [ ] File references use relative paths from the skill root

---

## Core loop summary

Repeating the core loop here for emphasis:

1. **Understand** — Figure out what the skill is about
2. **Draft** — Write or edit the SKILL.md
3. **Test** — Run test prompts with the skill loaded (use `/skills reload` to pick up changes)
4. **Review** — Present results to the user, gather feedback
5. **Iterate** — Improve the skill based on feedback
6. **Repeat** — Until you and the user are satisfied
7. **Share** — Place in `.github/skills/` for the team, or share the directory for personal use

Good luck!
