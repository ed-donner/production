# Week 3 Assignment — Alex Researcher: Agentic Enhancements

**Student:** Cynthia Omovoiye  
**Course:** AI in Production
**Week:** 3 — Research Infrastructure  
**GitHub Repo:** https://github.com/CynthiaOmovoiye/alex

---

## What I Built

I took the base Alex Researcher agent (App Runner + Bedrock Nova Pro + Playwright MCP) and added three enhancements for the Week 3 assignment:

### 1. To-Do List Tools — Structured Research Planning
The agent now creates and tracks its own research plan before doing any work. It calls `create_research_plan` first, then marks each step complete as it goes. This keeps the agent focused and prevents it from skipping steps or going in circles.

New tools added in `backend/researcher/todo_tools.py`:
- `create_research_plan(steps)` — agent writes its own 5-6 step plan
- `complete_step(step_number)` — marks progress turn by turn
- `get_plan_status()` — lets the agent check what's left

Backed by a `ResearchContext` dataclass passed through `RunContextWrapper` — the idiomatic OpenAI Agents SDK pattern for shared state within a run.

### 2. Polygon.io Integration — Real Price Data
The agent now verifies every price it mentions against live market data from Polygon.io (free plan). No more quoting prices from web page text alone.

New tools added in `backend/researcher/polygon_tools.py`:
- `get_stock_data(symbol)` — previous session OHLCV + day change %
- `get_multiple_stocks(symbols)` — batch price lookup for up to 8 tickers
- `get_market_status()` — checks if NYSE/NASDAQ are open or closed, so the agent frames its analysis correctly (intraday vs after-hours)

### 3. Context Engineering — Structured, Resilient Research
Rewrote the system prompt in `backend/researcher/context.py` with:
- A **mandatory workflow** (plan → market context → browse → price data → synthesize → save)
- **Resilience rules** — if a website blocks the agent, it moves to the next source immediately
- **Tiered source list** — Reuters, StockAnalysis, Finviz (reliable headless) before Yahoo/CNBC
- **Structured output format** — every saved document has the same sections (SUMMARY, KEY DATA POINTS, PRICE ACTION, ANALYSIS, INVESTMENT IMPLICATIONS, RISK FACTORS, TICKERS)
- **Hard completion requirement** — the agent cannot return without calling `ingest_financial_document`

---


## Key Files Changed

| File | Change |
|------|--------|
| `backend/researcher/todo_tools.py` | New — ResearchContext + 3 planning tools |
| `backend/researcher/polygon_tools.py` | New — 3 Polygon market data tools |
| `backend/researcher/context.py` | Rewritten — structured workflow, resilience rules, output format |
| `backend/researcher/server.py` | Updated — wires up all new tools + ResearchContext |
| `terraform/4_researcher/` | Updated — Polygon env vars added |

---

## Live Service

App Runner URL: `https://gvqci7bppf.us-east-1.awsapprunner.com`  
Health check: `https://gvqci7bppf.us-east-1.awsapprunner.com/health`  


---

