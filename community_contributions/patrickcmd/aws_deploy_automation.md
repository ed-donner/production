# PR summary: Week 1 follow-through + AWS App Runner automation

Use the sections below as the **Pull Request description** (or trim as needed). Source of truth for architecture and scripts: [PatrickCmd/saas — `aws-preview-deploy` README](https://github.com/PatrickCmd/saas/blob/aws-preview-deploy/README.md).

## Live app

**Production URL:** [https://healthapp.patrickcmd.dev](https://healthapp.patrickcmd.dev)

## What this demonstrates

This work extends the **Week 1** healthcare consultation assistant concept with a full-stack deployment path aligned with **Day 5: Deploy Your SaaS to AWS App Runner** ([`week1/day5.md`](../../week1/day5.md)): Docker image → **Amazon ECR** → **AWS App Runner**, with environment-based secrets and a repeatable CLI-driven workflow instead of only console clicks.

## Product summary (Consultation App)

AI-assisted **medical visit summarization**: clinicians enter visit notes; the app returns a structured summary, next steps, and a draft patient email, with **streaming** from OpenAI for a responsive UX.

## Architecture (high level)

| Layer | Stack |
|--------|--------|
| **Frontend** | Next.js (Pages Router), static export, Tailwind CSS v4, react-markdown |
| **Auth** | Clerk (Core 3) on the client; backend verifies **Clerk JWTs** |
| **Backend** | FastAPI — `POST /api/consultation` (SSE/streaming), `GET /health` |
| **AI** | OpenAI API (streaming) |
| **Infra** | Multi-stage **Docker** build → **ECR** → **App Runner** |

The upstream README includes an ASCII architecture diagram (frontend ↔ SSE ↔ FastAPI ↔ OpenAI) for reviewers who want a one-glance map.

## Automation: `bin/` scripts (Day 5 “professional deployment” loop)

Scripts load configuration from `.env` and use AWS CLI profile **`aiengineer`** (as documented in the repo). Deploy order:

| Step | Script | Purpose |
|------|--------|--------|
| 1 | `./bin/create-ecr-repo.sh` | Create ECR repository for the app image |
| 2 | `./bin/push-to-ecr.sh` | Build **linux/amd64** image, tag, push to ECR |
| 3 | `./bin/create-apprunner-service.sh` | IAM role, auto-scaling config, App Runner service |
| 4 | `./bin/apprunner-custom-domain.sh link` | Custom domain + Route 53 records |

**Operations:** `./bin/apprunner-custom-domain.sh status`, `./bin/apprunner-pause-resume.sh` (`pause` / `resume` / `status`) for cost control and checks.

**Tear down:** `./bin/apprunner-custom-domain.sh unlink`, `./bin/delete-apprunner-service.sh`.

## Local / Docker (for reviewers)

- **Local:** `npm run dev` (frontend, port 3000) + `uvicorn api.server:app --reload --port 8000` (backend).
- **Single container:** `docker build` / `docker run` as in the [README](https://github.com/PatrickCmd/saas/blob/aws-preview-deploy/README.md); app served on port **8000**.

## Secrets & config

Documented in `.env` / `.env.example`: Clerk keys, JWKS URL, `OPENAI_API_KEY`, and AWS identifiers (`DEFAULT_AWS_REGION`, `AWS_ACCOUNT_ID`). Keys are **not** committed; Vercel vs AWS parity is handled via env vars in each environment.

## Why this is useful for the course repo PR

- Shows an **end-to-end** path from the Week 1 SaaS idea to **production on AWS** using the same building blocks taught on Day 5 (Docker, ECR, App Runner, budgets/IAM called out in the lesson).
- Adds **repeatable bash automation** so deploy, domain link, pause/resume, and teardown are reviewable as code.

---

**Primary reference:** [https://github.com/PatrickCmd/saas/blob/aws-preview-deploy/README.md](https://github.com/PatrickCmd/saas/blob/aws-preview-deploy/README.md) · **Live:** [https://healthapp.patrickcmd.dev](https://healthapp.patrickcmd.dev)
