# Stella's Alex AI Financial Advisor — Week 4 Project

**Student:** Stella Achar Oiro (Igniters cohort)  
**Repo:** https://github.com/Stella-Achar-Oiro/alex-financial-advisor  
**Live URL:** https://dzbkw0e9qk4mc.cloudfront.net

---

## What it does

A production-grade AI financial advisor powered by a multi-agent orchestra. Users manage investment portfolios across multiple accounts and trigger AI analysis that runs five specialized agents in parallel, producing portfolio reports, interactive charts, and retirement projections.

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Next.js 15 (Pages Router), TypeScript, Tailwind CSS, Recharts, Clerk auth |
| API | FastAPI on AWS Lambda + API Gateway |
| Agent framework | OpenAI Agents SDK + LiteLLM (Bedrock backend) |
| AI model | Amazon Nova Pro (`us.amazon.nova-pro-v1:0`) via Bedrock (us-west-2) |
| Embeddings | SageMaker Serverless endpoint (`all-MiniLM-L6-v2`, 384 dims) |
| Vector store | AWS S3 Vectors (s3vectors) |
| Database | Aurora Serverless v2 PostgreSQL with Data API |
| Queue | SQS (triggers planner Lambda) |
| CDN | CloudFront + S3 static hosting |
| Observability | LangFuse (full agent tracing) + CloudWatch dashboards |
| Infrastructure | Terraform across all 8 deployment stages |

## Agent architecture

```
User triggers analysis
        │
        ▼
    SQS Queue
        │
        ▼
  Financial Planner (Orchestrator Lambda)
        ├── InstrumentTagger  ← classifies ETFs with rationale logging
        ├── Portfolio Analyst ← markdown report + S3 Vectors RAG
        ├── Chart Specialist  ← 5 Recharts-compatible JSON visualizations
        └── Retirement Planner ← Monte Carlo projections
        │
        ▼
   Aurora DB → CloudFront → User
```

## Key features

- **Multi-agent orchestration** — 5 Lambda-based agents coordinated via SQS
- **Explainability** — tagger logs structured rationale for every classification decision
- **LangFuse observability** — full traces, token usage, and latency for every agent run
- **Sidebar UI** — collapsible sidebar with lucide-react icons (no emojis)
- **CloudWatch dashboards** — Bedrock/SageMaker metrics + agent performance monitoring
- **Scale to zero** — fully serverless, costs ~$0 when idle

## Infrastructure deployed

- Guide 2: SageMaker Serverless embedding endpoint
- Guide 3: Ingestion pipeline (Lambda + API Gateway + S3 Vectors)
- Guide 4: Researcher agent (App Runner + OpenAI Agents SDK)
- Guide 5: Aurora Serverless v2 + Data API (22 ETFs seeded)
- Guide 6: Agent orchestra (5 Lambdas + SQS + IAM)
- Guide 7: Frontend (CloudFront + S3 + API Lambda + Clerk auth)
- Guide 8: Enterprise (CloudWatch dashboards, explainability, LangFuse observability)
