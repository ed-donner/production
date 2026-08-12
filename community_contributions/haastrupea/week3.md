# Cyber-Security Agent (Azure)

A small cybersecurity code analyzer: a FastAPI backend that uses an AI agent plus a Semgrep MCP server to scan pasted code and return structured findings (issues, severity, fixes, summary). The API can serve the frontend for a single-origin style deployment in production.

I deployed it as a containerized app on Azure: Terraform provisions Azure Container Registry, builds and pushes the Docker image, and runs it on Azure Container Apps with Log Analytics, using Terraform workspaces for environment separation as in the course. The repo also includes a GCP Terraform layout if you followed that track.

(Optional — only if true for you:) I validated the stack end-to-end (manual apply / first deploy), then relied on Terraform for repeatable infrastructure instead of one-off console steps.

Live URL

https://cyber-analyzer.kindgrass-67fd4fe2.germanywestcentral.azurecontainerapps.io
