# Week 3 — Cyber Security Agent (Igniters / Tunde)

This note documents the **cyber** Week 3 project work: a **Semgrep MCP–based code analyzer** with a FastAPI backend and Next.js UI, extended with **AWS** deployment options.

## Repository

**Fork (this contribution):** [github.com/tundewey/cyber-analyzer](https://github.com/tundewey/cyber-analyzer)

**Course upstream:** [github.com/ed-donner/cyber](https://github.com/ed-donner/cyber) — pull from `origin` on `main` to stay aligned with the class materials.

## What’s in the `cyber` project

| Area | Description |
|------|-------------|
| **Week 3 guides** | `week3/` — start with `day1.part0` (open as Markdown preview in Cursor). |
| **App** | `backend/` (FastAPI), `frontend/` (Next.js), single container on port **8000** per root `Dockerfile`. |
| **AWS — manual** | `aws/README.md` — ECR, scripts under `scripts/` (e.g. `push-ecr.ps1`), App Runner / ECS notes. |
| **AWS — Terraform** | `terraform/` — ECS **Fargate**, **ALB**, security groups, IAM execution role, CloudWatch logs. See `terraform/README.md`. |
| **GCP (optional)** | `terraform/gcp/` — separate Terraform layout for GCP experiments. |

## Quick clone

```bash
git clone https://github.com/tundewey/cyber-analyzer.git
cd cyber-analyzer
```

Copy **`.env.example`** → **`.env`** locally. For Terraform, copy **`terraform/terraform.tfvars.example`** → **`terraform/terraform.tfvars`** and fill in values — **do not commit** secrets (both paths are gitignored in the fork).

## Deploy highlights

1. **ECR image** — build/push from repo root; see `aws/README.md` and `scripts/push-ecr.ps1`.
2. **Terraform (ECS + ALB)** — from `terraform/`: `terraform init` → `plan` → `apply`. Use a unique **`project_name`** if ALB/target group names already exist in your account.
3. After apply, use **`terraform output alb_url`** (or the console) once targets are **healthy**.

## Staying up to date with the course

From your local clone (with `origin` pointing at `ed-donner/cyber` if you cloned the course repo, or after adding that remote):

```bash
git checkout main
git pull origin main
```

Then merge or rebase onto your fork’s branch and push to your GitHub remote as needed.

## Contact

Course questions: Udemy / [ed@edwarddonner.com](mailto:ed@edwarddonner.com) per the upstream README.


## Links

| | |
|--|--|
| **Source repository** | [GIT_REPO](https://github.com/tundewey/cyber-analyzer) |
| **AWS deployment** | [AWS Cyber Link](http://cyber-analyzer-tf-alb-1085052966.us-east-1.elb.amazonaws.com/) |
