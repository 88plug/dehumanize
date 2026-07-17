# dehumanize — Plugin Status

**Status:** ready for publish  
**Plugin:** dehumanize  
**Manifest:** `.claude-plugin/plugin.json` only (no root `plugin.json`)  
**Regime:** rolling (no `version` field; hub computes `YEAR.MONTH.<commit-count>`)

## Ship bar (local)

- [x] Single manifest at `.claude-plugin/plugin.json`
- [x] Keywords = 20, no `version`
- [x] License FSL-1.1-ALv2, author 88plug
- [x] Hooks: SessionStart / Stop / UserPromptSubmit via `${CLAUDE_PLUGIN_ROOT}`
- [x] T1 `scripts/run-python.sh` for audit tooling (thin PATH OK)
- [x] `tests/smoke.sh` fleet bar green
- [x] `.ci/validate_plugin.py` present
- [x] CI: `plugin-validate.yml` + `pages.yml` + Dependabot
- [x] README hub-first install (`88plug/claude-code-plugins` + `dehumanize@88plug`)
- [x] `marketplace-entry.json` source = `url` → `https://github.com/88plug/dehumanize.git`
- [x] MkDocs Material + `docs/` + DeepWiki badge
- [x] `.gitignore`: `site/`, `__pycache__/`, `.venv/`, `sweep_r*`, `eval_run*`

## Surfaces

| Surface | Path |
| --- | --- |
| SessionStart | `hooks/session-init.sh` |
| Stop | `hooks/capture-stop.sh` |
| UserPromptSubmit | `hooks/inject-correction.sh` |
| Detector | `hooks/lib/detect-human-framing.sh` + `hooks/lib/patterns.sh` |
| Commands | `audit`, `status`, `patterns`, `fix` |
| Skill | `skills/dehumanize/SKILL.md` |

## Anti-patterns (5)

1. Human time estimates / labor units  
2. Asking for accessible data (paste/send/attach)  
3. Emotional labor / filler  
4. Serial narration instead of parallel fan-out  
5. Effort theater ("this is complex")  

## Post-publish checklist (skill: 88plug-plugin)

Run once after first `git push -u origin main`:

1. **Enable GitHub Pages** (one-time, before first Pages deploy):
   ```bash
   gh api -X POST repos/88plug/dehumanize/pages -f build_type=workflow
   ```

2. **Add to central marketplace registry** (one-time; plugins are not auto-added):
   - Edit `88plug/claude-code-plugins` `.claude-plugin/marketplace.json`
   - Entry: name `dehumanize`, source `url` → `https://github.com/88plug/dehumanize.git`
   - Do **not** set `version` (rolling)

3. **Trigger DeepWiki indexing** (one-time, public repo):
   - Use `/deepwiki-index` skill (Chrome via screen-mcp; reCAPTCHA)
   - Badge: https://deepwiki.com/88plug/dehumanize

4. **Set GitHub repo topics** (aim 18–20):
   ```bash
   gh api 'search/repositories?q=topic:<x>' -q .total_count   # traffic check
   gh api --method PUT repos/88plug/dehumanize/topics \
     -f 'names[]=claude-code' -f 'names[]=claude-code-plugin' # …fill to ≤20
   ```

5. **Set repo About description** — keyword-front-loaded one-liner matching plugin.json description.

## Directive (UserPromptSubmit)

> You are AI, not a person. Access files directly, never ask for them. Fan out in parallel, never serialize. No human time units, no emotional filler, no "this is complex." Compute and act now.
