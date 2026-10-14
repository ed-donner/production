# NESTOR: Next-gen Engine for Savings, Taxation & Optimized Retirement

**NESTOR** is an enterprise-grade, multi-agent financial planning SaaS platform deployed on AWS — a Java-focused variation of Alex's project. If you're a Java practitioner who wants to understand the course concepts through a Java lens, this repo is for you.

## What Makes It Different

- **Java 21 + Spring Boot 3.x backend** — all Lambda agents are written in Java using Spring Cloud Function, replacing the Python-based approach
- **Multi-agent orchestration** — planner, tagger, reporter, charter, and retirement agents coordinate via SQS and Bedrock tool-calling
- **India-localized retirement planning** — INR currency, Indian ETFs (NIFTYBEES, LIQUIDBEES, GOLDBEES), NPS/EPF account types, and India-specific retirement projections
- **Updated frontend** — NextJS React dashboard with Clerk auth, Recharts visualizations, and retirement planning tailored for India

## Architecture

| Layer | Tech |
|-------|------|
| Frontend | NextJS (Pages Router), React, Recharts, Clerk Auth |
| Backend (agents) | Java 21, Spring Boot 3.x, Spring Cloud Function |
| Shared library | nestor-common — Bedrock client, Data API client, models |
| LLM | AWS Bedrock (Nova Pro / OpenAI OSS 120B via inference profiles) |
| Database | Aurora Serverless v2 PostgreSQL (Data API) |
| Vector store | S3 Vectors + SageMaker Serverless (all-MiniLM-L6-v2) |
| Orchestration | SQS, Lambda invoke, Bedrock tool-calling |
| Infrastructure | Terraform (independent per-guide directories) |
| Build | Maven multi-module, Docker container images, ECR |

## Key Features

- AI-generated portfolio reports with insights and recommendations
- Interactive charts for allocation breakdowns and sector analysis
- Monte Carlo retirement simulations (accumulation + drawdown phases)
- Automatic instrument classification (sector, region, asset-class)
- Step-by-step deployment guides in `guidesJava/` (permissions through enterprise monitoring)

## Repository

The complete application is available at:
https://github.com/LuvRaheja/NESTOR

See the README.md in the repository for detailed setup instructions, architecture diagrams, and deployment guides.