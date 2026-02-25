# OpenCortex Architecture Reference

## Why This Exists

Default OpenClaw memory is a flat MEMORY.md that grows unbounded. Context fills up, compaction loses information, the agent forgets what it learned. OpenCortex solves this with:

1. **Separation of concerns** — different files for different purposes
2. **Nightly distillation** — raw daily logs → permanent structured knowledge
3. **Weekly synthesis** — pattern detection across days
4. **Principles** — enforced habits that prevent knowledge loss
5. **Sub-agent debrief loop** — delegated work feeds back into memory

## File Purposes

| File | Loaded at boot? | Purpose | Size target |
|------|-----------------|---------|-------------|
| MEMORY.md | Yes | Principles + index only | < 3KB |
| TOOLS.md | Yes | Tool/API catalog with abilities | Grows with tools |
| INFRA.md | Yes | Infrastructure reference | Grows with infra |
| SOUL.md | Yes | Identity, personality | < 1KB |
| AGENTS.md | Yes | Operating protocol | < 1KB |
| USER.md | Yes | Human's preferences | < 1KB |
| BOOTSTRAP.md | Yes | Session startup checklist | < 0.5KB |
| memory/projects/*.md | On demand | Per-project knowledge | Any |
| memory/contacts/*.md | On demand | Per-person/org knowledge | Any |
| memory/workflows/*.md | On demand | Per-workflow/pipeline knowledge | Any |
| memory/preferences.md | On demand | Cross-cutting user preferences by category | Any |
| memory/runbooks/*.md | On demand | Procedures for sub-agents | Any |
| memory/YYYY-MM-DD.md | Current day | Working log | Any |
| memory/archive/*.md | Via search | Historical logs | Any |

## Distillation Routes

The nightly cron reads daily logs and routes each piece of information:

| Information type | Destination |
|-----------------|-------------|
| Project work, features, bugs | memory/projects/{project}.md |
| New tool descriptions and capabilities | TOOLS.md (sensitive values → vault) |
| Infrastructure changes | INFRA.md (if OPENCORTEX_INFRA_COLLECT=1) |
| People and organizations mentioned | memory/contacts/{name}.md |
| Workflows and pipelines described | memory/workflows/{name}.md |
| Stated preferences and opinions | memory/preferences.md (categorized) |
| Decisions and architectural directions | Relevant project file or MEMORY.md |
| New principles, lessons | MEMORY.md |
| User info and communication style | USER.md |
| Scheduled job changes | MEMORY.md jobs table |
| Repeatable procedures | memory/runbooks/ |

## Preference Categories

Preferences in `memory/preferences.md` are organized by category:

| Category | Examples |
|----------|---------|
| Communication | "No verbose explanations", "Direct messages only" |
| Code & Technical | "Detailed commit messages", "Prefer TypeScript" |
| Workflow & Process | "Check for messages before pushing", "Batch commits" |
| Scheduling & Time | "Don't schedule before 9 AM", "Prefer async" |
| Tools & Services | "Use VS Code over Vim", "Prefer Brave over Chrome" |
| Content & Media | "720p minimum", "No dubbed content" |
| Environment & Setup | "Dark mode everywhere", "Dual monitor layout" |

Format: `**Preference:** [what] — [context/reasoning] (date)`

Preferences are auto-captured from conversation when the user says "I prefer", "always do", "I don't like", etc. Contradicted preferences are updated (not duplicated).

## Compounding Effect

```
Week 1:  Agent knows basics, asks lots of questions
Week 4:  Agent has project history, knows tools, follows decisions, remembers preferences
Week 12: Agent has deep institutional knowledge, patterns, runbooks, contact history
Week 52: Agent knows more about the setup than most humans would remember
```

The key insight: **daily distillation + weekly synthesis + decision/preference capture** means the agent gets better at a rate proportional to how much it's used. Unlike raw log accumulation which just fills context, structured knowledge compounds.

## Common Customizations

### Adding delegation tiers
Edit MEMORY.md P1 to adjust which model handles what complexity.

### Changing distillation schedule
`openclaw cron edit <id> --cron "0 10 * * *" --tz "Your/Timezone"`

### Adding domain-specific principles
Append to MEMORY.md 🔴 PRINCIPLES. Keep each principle to 1-2 sentences.

### Multi-bot setups
Each bot gets its own OpenCortex install. Share knowledge via:
- Common git repo (read-only for non-primary bots)
- SSH-based management (primary bot propagates changes)
- Shared NFS/SMB mount for common reference docs
