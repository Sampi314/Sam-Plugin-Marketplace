---
name: wt-ai-search
description: >
  Search for AI news, tool updates, model releases, and builder commentary as input to a daily AI blog. Pulls from the curated `follow-builders` daily digest (X posts and podcast transcripts from top AI builders) and optionally tops up with focused web searches to verify facts or surface a contrary view. Returns RAW findings as a structured shortlist — does not pick a topic, does not present options to the user, does not draft prose. Use this skill whenever the user wants to "find AI news for the blog", "fetch today's AI digest", "search for AI updates", "pull follow-builders", "what's new in AI today", "get raw AI news", "look up more info on X for the AI blog", or any request to gather AI news findings as input to the writing pipeline. Hand findings to `wt-ai-plan` (for tickable option selection) or pass directly to `wt-ai-write` if the topic is already chosen.
---

# wt-ai-search — Search Skill for Daily AI Blog

## Role

The information-gathering end of the AI-blog pipeline. Pulls the curated builder digest (and optionally tops up with web searches) and returns RAW findings — no curation beyond theme-fit, no editorial decisions, no prose.

Pipeline position:

- **`wt-ai-search` — this skill** — gather raw findings
- `wt-ai-plan` — turn findings into an agreed brief via tickable options
- `wt-ai-write` — turn the brief into the final article + visuals

## What this skill returns

A shortlist of 5–8 candidate findings, each structured as:

```
N. Source:   <builder + platform>   (e.g. "@karpathy on X", "Latent Space podcast")
   Freshness: <today | yesterday | this week>
   Topic:    <one-line summary in your own words>
   Quote:    <paraphrased excerpt + link to original>
   Possible audience angle: <one sentence — finance/audit/modelling relevance>
   Theme fit: <which of the 5 editorial themes this maps to>
```

The five editorial themes (filter candidates against these — only theme-fitting findings make the shortlist):

1. Finance, audit, or consulting sector news.
2. New features in AI coding or agent tools.
3. New concepts worth explaining to beginners.
4. New model releases.
5. Beginner-friendly explainers.

Reject celebrity drama, lawsuits, burnout posts, personal-life updates, unrelated political content, funding rumours without product substance.

## Prerequisites — auto-install `follow-builders`

Before fetching, verify the `follow-builders` skill is installed. If not, clone and install it.

```bash
if [ ! -d "$HOME/.claude/skills/follow-builders/scripts" ]; then
  echo "follow-builders not found — installing now..."
  git clone https://github.com/zarazhangrui/follow-builders.git "$HOME/.claude/skills/follow-builders"
  cd "$HOME/.claude/skills/follow-builders/scripts" && npm install
  echo "follow-builders installed."
else
  echo "follow-builders already installed."
fi
```

If the install fails (no network, no git, no npm), stop and tell the user what is missing. Do not proceed.

## How to fetch

1. **Pull today's digest:**
   ```bash
   cd "$HOME/.claude/skills/follow-builders/scripts" && node prepare-digest.js
   ```
2. **Parse the raw output** — X posts + podcast transcript snippets + blog links from roughly 25 curated AI builders, updated daily.
3. **Apply the five-theme filter** — discard anything that does not fit.
4. **Extract 5–8 candidate findings** in the structured format above.
5. **Optional top-up search** (only when called for verification or to flesh out a single candidate):
   - One web search of the original source (official announcement, paper, or builder's own post) to verify facts.
   - One search for any contrary view or community reaction.
   - Keep it tight — daily-brief depth, not weekly long-form.
6. **Return the shortlist** to the caller.

## Re-search trigger from `wt-ai-plan`

`wt-ai-plan` may call this skill again mid-flow with a refined query — e.g. "find more options on the Claude Skills release", "look for a contrary view on the GPT-5 benchmark claim", or "any beginner-friendly explainers of MCP today?". Treat each re-search as a focused top-up, not a full digest re-pull.

When called this way, return only the new findings (do not repeat the prior shortlist).

## What this skill does NOT do

- Does **not** pick the topic.
- Does **not** present findings as user-tickable options (that is `wt-ai-plan`).
- Does **not** draft any prose or visuals (that is `wt-ai-write`).
- Does **not** decide which of the 5 themes the topic ultimately belongs to — it labels a likely theme but final selection is editorial.

## See also

- `wt-ai-plan` — consumer of these findings; presents them as tickable options to the user.
- `wt-ai-write` — turns the agreed brief into prose, image, and flow chart.
- `wt-writing-auditor` — voice and style authority for the blog (relevant once writing begins).
