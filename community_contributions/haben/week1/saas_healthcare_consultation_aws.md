# Week 1 Contribution — SaaS Healthcare Consultation Platform on AWS

**Author:** Haben Eyasu
**Course:** Andela AI Engineering Series
**Repository:** [habeneyasu/saas-healthcare-consultation-aws](https://github.com/habeneyasu/saas-healthcare-consultation-aws)

---

## Project Idea

This project is a full-stack AI-powered SaaS platform that exposes two intelligent tools through a unified Next.js interface:

- **SaaS Idea Generator** — produces investor-ready B2B SaaS concepts complete with pricing models, MVP scope, and go-to-market strategy
- **Health Consultation Assistant** — delivers structured clinical assessments with ranked differential diagnoses, recommended actions, and urgency classification

Both tools stream responses token-by-token using Cerebras `llama3.1-8b`, targeting sub-10-second response times. The platform supports a free unauthenticated tier and an authenticated Pro tier managed via Clerk.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Next.js 16 · React 19 · TypeScript · Tailwind CSS v4 |
| Backend | FastAPI · Python 3.12 · httpx |
| AI Inference | Cerebras Cloud SDK · llama3.1-8b |
| Authentication | Clerk |
| Containerization | Docker · Docker Compose |
| CI/CD | GitHub Actions |
| Deployment | Vercel (frontend + backend) |

---

## Architecture

```
Browser
  │
  ├── GET  /api/ideas          ──► Next.js (Vercel)
  └── POST /api/consultation   ──► Next.js (Vercel)
                                        │
                              NEXT_PUBLIC_API_URL
                                        │
                                 FastAPI (Vercel)
                                        │
                            ┌───────────┴────────────┐
                       Clerk JWT               Cerebras API
                     (auth check)           (llama3.1-8b SSE)
                                                  │
                                        Streamed Markdown
                                         back to browser
```

---

## Key Features

- Real-time token streaming rendered as live Markdown
- Free tier (unauthenticated) and Pro tier (Clerk-authenticated) with separate rate limits
- Structured prompt templates for consistent, high-quality AI output
- CORS-enabled FastAPI backend deployable as serverless functions
- Dockerized services with a single `docker-compose up` for local development
- Automated CI/CD via GitHub Actions with Docker Hub and Vercel integration

---

## Getting Started

### Prerequisites

- Node.js 20+
- Python 3.12+
- Cerebras Cloud API key
- Clerk account

### Run the Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

### Run the Frontend

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

### Run with Docker (Full Stack)

```bash
docker-compose up --build
```

| Service | URL |
|---|---|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8000 |
| Swagger UI | http://localhost:8000/docs |

---

## Environment Variables

### Backend — `backend/.env`

| Variable | Description | Required |
|---|---|---|
| `CEREBRAS_API_KEY` | Cerebras Cloud API key | ✅ |
| `CEREBRAS_MODEL` | Model ID (e.g. `llama3.1-8b`) | ✅ |
| `ALLOWED_ORIGINS` | Comma-separated allowed frontend URLs | ✅ |
| `CLERK_DOMAIN` | Clerk domain for JWT verification | ✅ |

### Frontend — `frontend/.env.local`

| Variable | Description | Required |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | Backend base URL | ✅ |
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | Clerk publishable key | ✅ |
| `CLERK_SECRET_KEY` | Clerk secret key | ✅ |
| `NEXT_PUBLIC_CLERK_SIGN_IN_URL` | Sign-in redirect path | ✅ |
| `NEXT_PUBLIC_CLERK_SIGN_UP_URL` | Sign-up redirect path | ✅ |

---

## API Reference

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/ideas` | Optional | Stream AI-generated SaaS ideas |
| `POST` | `/api/consultation` | Optional | Stream health consultation report |
| `GET` | `/health` | None | Service health check |
| `GET` | `/docs` | None | Swagger UI |

### Rate Limits

| Tier | Limit |
|---|---|
| Free (unauthenticated) | 3 requests / day |
| Pro (Clerk-authenticated) | 20 requests / day |

### Example — `POST /api/consultation`

```json
{
  "name": "Patient Name",
  "date": "2026-04-07",
  "complaint": "Persistent headache and mild fever for 2 days"
}
```

---

## Deployment

### Deploy Backend to Vercel

```bash
cd backend
vercel link
vercel env add CEREBRAS_API_KEY production
vercel env add CEREBRAS_MODEL production
vercel env add ALLOWED_ORIGINS production
vercel env add CLERK_DOMAIN production
vercel --prod
```

### Deploy Frontend to Vercel

```bash
cd frontend
vercel link
vercel env add NEXT_PUBLIC_API_URL production
vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY production
vercel env add CLERK_SECRET_KEY production
vercel env add NEXT_PUBLIC_CLERK_SIGN_IN_URL production
vercel env add NEXT_PUBLIC_CLERK_SIGN_UP_URL production
vercel --prod
```

---

## CI/CD Pipeline

Every push to `main` triggers the following automated pipeline:

1. **Lint** — `ruff` on backend, `eslint` on frontend
2. **Build** — Docker images for both services
3. **Push** — images published to Docker Hub
4. **Deploy** — both services deployed to Vercel production

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `VERCEL_TOKEN` | Vercel personal access token |

---

## License

MIT © Haben Eyasu
