# ALEX — Consolidated Summary of enhancements to the lab foundations

_Last updated: Dec 18, 2025_

---

## Overview

**ALEX (Agentic Learning Equities eXplainer)** is an agentic, event‑driven investment intelligence system built on AWS. It combines multiple AI agents (Planner, Reporter, Charter, Retirement, Researcher) with real‑time data, research pipelines, and a user‑facing Alerts & Tasks experience.

This document summarises all of the enhancements to the original lab project.

---

## Architecture (High level)

- **Planner Lambda** — Orchestrates agent runs
- **Reporter / Charter / Retirement Lambdas** — Domain‑specific analysis agents
- **Researcher App Runner** — Web + market research (Playwright MCP server)
- **Aurora (Data API)** — Accounts, Positions, Instruments, Users
- **API Gateway (HTTP API)** — Backend API
- **CloudFront + S3** — Frontend hosting
- **Frontend (Next.js)** — Dashboard, Accounts, Analysis, Advisor team tabs 
  - Analysis provides Overview, Charts and Retirement Projection

## ENHANCEMENTS
- **Daily price_refresher Lambda** using Polygon EOD prices 

- **Symbol Research Pipeline** — Symbol research using SQS and parallel async processing integrated into Researcher as new endpoint
  - Calls Brave web search tool
  - Reuses ingest pipeline to store result in S3 vector

- **Aurora (Data API)** — Schema extensions for Alerts, Todos, JobTracker

- **Frontend (Next.js)** enhancements
  — Added Alerts & Tasks tabs to UI, 
  - Report now include up‑to‑date market pricing with price lookup tool added to **Reporter**

- **Backend APIs**:
  - `GET /api/alerts` (for Alerts)
  - `GET /api/todos` (for Tasks)

- Parallel **fan‑out / fan‑in** research architecture:
  - Reporter extracts symbols
  - SQS enqueues per‑symbol jobs
  - Worker Lambda calls Researcher App Runner invoking symbol research endpoint
  - JobTracker tracks `pending → running → done`
  - 2 new tools available to Reporter
    - submit_portfolio_research_job(symbols)
    - check_research_job_status() that checks completion of all submitted symbol_research worker jobs

- Researcher App Runner stabilised:
  - FastAPI + uv
  - Brave‑first discovery (had to use base plan instead of free tier)
  - Playwright optional (system Chromium)

- **Actionable Alerts Engine**
  - Event abstraction:
    - `AlertContext`
    - `EngineResult`
    - `TodoSpec`
  - Producers & bridges for Reporter and Retirement
  - Alert & Todo deduplication logic
  - Planner → agent orchestration hardened, extended timeout from 60s to 300s to avoid spawning multiple reporter agents

- **Alerts Lifecycle**
  - Status flow:
    - `new → read → dismissed`
    - “Mark as read” works end‑to‑end

- **Tasks Lifecycle**
  - Schema‑aligned status model:
    - `open → in_progress → done`
  - Frontend UX finalised:
    - **Start / In Progress** action
    - **In Progress** shown as a non‑clickable state badge
    - **Done** remains actionable

- Lambda packaging fixes/additions:
  - `database/src` explicitly copied into ZIPs
  - `backend/common` folder holds tools, utility and helper functions
  - Missing deps allow‑listed

## Planned Enhancements (technical debt)

- **Parallel Agent Execution**

    Run the following agents **in parallel** instead of sequentially:

    - Reporter
    - Charter
    - Retirement

    Implementation options:

    - `InvocationType = Event` with job‑state tracking
    - OR Step Functions orchestration

    Goals:
      - Reduce end‑to‑end latency
      - Better reflect true agentic execution
      - Prepare for scaling and scheduling

Link to git repo: https://github.com/samsriram712/alex

About the journey, refer LinkedIn post @ https://www.linkedin.com/posts/activity-7403260759692259328-WE11?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAAiJDYBT2gXFLwL6-EHWK3kVqnGRi5M1sc

