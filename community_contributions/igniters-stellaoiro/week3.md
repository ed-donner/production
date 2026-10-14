# Stella's Cyber-Security Agent — Week 3 Project

**Student:** Stella Achar Oiro (Igniters cohort)  
**Repo:** https://github.com/Stella-Achar-Oiro/cyber-security-agent  
**Azure Live URL:** https://cyber-analyzer.redmushroom-c74997c1.eastus.azurecontainerapps.io  
**GCP Live URL:** https://cyber-analyzer-608805582585.us-central1.run.app  

---

## What it does

An AI-powered cybersecurity code analyzer that scans Python code for security vulnerabilities using Semgrep MCP (Model Context Protocol) and OpenAI. Users upload a Python file and receive a detailed security analysis with vulnerability descriptions and recommendations.

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Next.js 15 (static export), TypeScript, Tailwind CSS |
| Backend | FastAPI, Python 3.12, OpenAI, Semgrep MCP |
| Deployment (Azure) | Azure Container Apps via Terraform |
| Deployment (GCP) | GCP Cloud Run via gcloud CLI |
| Infrastructure | Terraform (Azure), gcloud CLI (GCP) |

## Key features

- **Semgrep MCP Integration** — Uses Semgrep MCP server for advanced static code analysis
- **Multi-cloud deployment** — Live on both Azure Container Apps and GCP Cloud Run
- **AI-powered analysis** — OpenAI interprets Semgrep findings into actionable recommendations
- **Containerized** — Single Docker image (multi-stage build) deployed across both clouds
- **Scale to zero** — Both deployments scale down when idle to minimize cost

## Architecture

```
User uploads Python file
        │
        ▼
  Next.js Frontend (static)
        │  POST /analyze
        ▼
  FastAPI Backend
        ├── Semgrep MCP Server  ← static analysis
        └── OpenAI API          ← AI interpretation
```

## Deployments

- **Azure Container Apps** — deployed via Terraform (`terraform/azure`), hosted in `eastus` region, resource group `cyber-analyzer-rg`
- **GCP Cloud Run** — deployed via gcloud CLI to `us-central1`, image stored in Artifact Registry (`stella-cyber-analyzer` project)
