# Learnings: running rubygems.org locally

A running log of failure modes encountered while bringing up rubygems.org and the fixes that worked. **This file exists so the skill can learn.** When `smoke.sh` fails:

1. **Read this file first** — someone may have already solved it (Ctrl-F your error string).
2. **Read `tmp/run-skill/diagnostic.txt`** — `smoke.sh` writes a structured snapshot of the environment whenever it fails (ports, docker state, rails log tail, ruby/bundle versions).
3. **Fix the issue.** Note the exact command(s) that worked.
4. **Add an entry below.** Use the template. Be specific — future-you / future-agent reads this cold and needs to act on it.
5. **Graduate stable fixes.** If the failure is likely to recur (not a one-off environment quirk), do one or both:
   - Add a row to `SKILL.md` > Troubleshooting (symptom → fix).
   - Update `smoke.sh` to auto-detect or auto-recover.
   - Then mark the entry below "**Status:** graduated" with a link to the commit/PR.

Don't skip step 4 even if you graduated immediately — this file is the *why* behind the SKILL changes.

## Entry template

Copy this block to the top of "Entries" and fill it in:

```markdown
## YYYY-MM-DD — short title

**Environment:** macOS arm64 14.5 / Ubuntu 22.04 / Linux container / etc.
**Triggered by:** `./.agents/skills/run-rubygems-org/smoke.sh` (or the specific command, if narrower)
**Symptom:** one-line error + where it appeared (stderr, `tmp/run-skill/rails.log`, `tmp/run-skill/diagnostic.txt`)
**Root cause:** the actual reason (not just the surface error)
**Fix:** the exact command(s) that worked, in order
**Status:** in-the-wild  |  graduated (link to commit/PR)
```

## Entries

_None yet. First entry will live here. Add new entries at the top so the most recent is easiest to find._
