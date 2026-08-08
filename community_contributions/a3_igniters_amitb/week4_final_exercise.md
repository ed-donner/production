# Week 4 Final Exercise - Alex: AI Financial Planner (Multi-Agent)

**Repository:** https://github.com/SectumPsempra/production/tree/week3-exercise-local/alex_financial_planner/backend/agents  
**Deployed App:** https://alex-frontend-ajg5nndceq-uc.a.run.app

---

## What is Being Built

Alex is a cloud-native AI financial planning assistant built on a **multi-agent architecture**. Users sign in, register their investment accounts and holdings, and trigger a portfolio analysis. Rather than a single LLM call, the work is broken across five specialised agents that run concurrently, each with a focused responsibility. The results are stitched together by a Planner agent and written back to the database for the frontend to display.

A sixth agent - the Researcher - runs on a separate Cloud Run service on a scheduled basis, autonomously browsing the web and writing market research into a vector knowledge base. That knowledge base is retrieved at analysis time to ground the report in current financial context.

---

## The Six Agents

| Agent | Responsibility |
|---|---|
| **Planner** | Orchestrates the pipeline: loads portfolio data, fans out to the four specialist agents in parallel, merges results, writes the completed job to the database |
| **Instrument Tagger** | Classifies each holding by asset class, sector, and region using an LLM with structured output (Pydantic schema) |
| **Report Writer** | Generates the full written portfolio analysis, pulling relevant context from the pgvector knowledge base via semantic search |
| **Chart Maker** | Produces structured JSON describing allocation charts (asset class, region, sector breakdowns) ready for the frontend to render |
| **Retirement Specialist** | Projects retirement income based on current portfolio value, expected return, years to retirement, and withdrawal rate |
| **Researcher** | Runs on a schedule (every 2 hours via Cloud Scheduler), searches the web for relevant financial news, and stores embeddings into the knowledge base for retrieval by the Report Writer |

---

## Architecture and Services

| Layer | GCP Service Used | AWS Equivalent |
|---|---|---|
| Frontend (Next.js) | Cloud Run | Elastic Beanstalk / App Runner |
| REST API (FastAPI) | Cloud Run | API Gateway + Lambda / App Runner |
| Agents Worker - 5 agents (FastAPI) | Cloud Run | ECS Fargate |
| Researcher Agent (FastAPI) | Cloud Run (separate service) | ECS Fargate |
| Job Queue | Cloud Tasks | SQS |
| Scheduled Research Trigger | Cloud Scheduler | EventBridge Scheduler |
| Relational Database | Cloud SQL (PostgreSQL) | RDS PostgreSQL |
| Vector Store | pgvector extension on Cloud SQL | RDS + pgvector or OpenSearch |
| Secrets | Secret Manager | Secrets Manager |
| Container Registry | Artifact Registry | ECR |
| Authentication | Clerk (third-party, same on both) | Cognito |
| LLM Calls | OpenRouter API | Amazon Bedrock |
| Embeddings | OpenAI text-embedding-3-small | Amazon Titan Embeddings |

---

## How it Works End-to-End

1. The user logs in via Clerk and views their portfolio on the Next.js frontend (Cloud Run).
2. They click "Run Analysis". The frontend calls the FastAPI REST API.
3. The API creates a `pending` job record in Cloud SQL, then enqueues a task to **Cloud Tasks** (analogous to SQS). The response returns immediately with the job ID.
4. Cloud Tasks invokes the **Agents Worker** service with an OIDC-authenticated HTTP POST.
5. The **Planner** agent loads the user's full portfolio from Cloud SQL, then fans out to the four specialist agents concurrently using `asyncio.gather`:
   - Instrument Tagger classifies all holdings.
   - Report Writer retrieves relevant research from the pgvector knowledge base via cosine similarity search, then writes the full analysis.
   - Chart Maker generates chart-ready JSON for the UI.
   - Retirement Specialist calculates projected income.
6. The Planner merges all results and writes them back to the `jobs` table with status `completed`.
7. The frontend polls the API every 4 seconds until the job is complete, then renders the report, charts, and retirement projection.

In parallel, the **Researcher** service runs every 2 hours via **Cloud Scheduler**. It searches financial news sources, scrapes article text, generates embeddings via the OpenAI embeddings API, and stores them in the `knowledge_base` table - keeping the Report Writer's context current without any manual intervention.

All six services are containerised with Docker (`linux/amd64` for Cloud Run compatibility) and the entire infrastructure is defined in Terraform across four modules: database, researcher, agents, and frontend+API.
