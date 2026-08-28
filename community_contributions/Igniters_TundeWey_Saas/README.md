# HealthCheck AI - A Health Consultation Assistant For You

Turn **consultation notes** into a **visit summary**, **next steps for the clinician**, and a **patient-friendly email draft**—rendered in real time as the model streams the response.

Sign in with Clerk, open the assistant at `/product`, enter patient name, visit date, and notes, then **Generate Summary**.

> **Demo only** — not for real PHI without proper compliance (e.g. HIPAA, BAAs).

## Tech stack

| Layer | Technologies |
|--------|----------------|
| **Frontend** | [Next.js](https://nextjs.org) (Pages Router), [React](https://react.dev), [TypeScript](https://www.typescriptlang.org), [Tailwind CSS](https://tailwindcss.com) |
| **Auth** | [Clerk](https://clerk.com) (`@clerk/nextjs`) |
| **Streaming UI** | [fetch-event-source](https://github.com/Azure/fetch-event-source), [react-markdown](https://github.com/remarkjs/react-markdown) |
| **Backend** | [FastAPI](https://fastapi.tiangolo.com), [Uvicorn](https://www.uvicorn.org), [Pydantic](https://docs.pydantic.dev) |
| **LLM** | [OpenAI Python SDK](https://github.com/openai/openai-python) → [OpenRouter](https://openrouter.ai) or [Google Gemini](https://ai.google.dev) (OpenAI-compatible) |
| **Deploy** | [Docker](https://www.docker.com), [AWS App Runner](https://aws.amazon.com/apprunner/), [Amazon ECR](https://aws.amazon.com/ecr/) |

## Links

| | |
|--|--|
| **Source repository** | [GIT_REPO](https://github.com/tundewey/HealthCheck-AI) |
| **AWS deployment** | [AWS Production Link](https://mr68ziwnhy.us-east-1.awsapprunner.com) |

## Local development

```bash
npm install
npm run dev
```

Run the FastAPI app from `api/` (e.g. `uvicorn` on `index.py`) per your course setup. Configure **`.env.local`** or **`.env`**: Clerk keys + **`CLERK_JWKS_URL`**, and **`OPENROUTER_API_KEY`** or **`GOOGLE_API_KEY`**. Do not commit secrets.

## Docker / AWS

Single image: Next static export + **`api/server.py`** on port **8000**, health at **`GET /health`**. See `Dockerfile` and course **Day 5** (ECR → App Runner).

## Layout

| Path | Role |
|------|------|
| `pages/` | Landing + `/product` |
| `api/index.py` | API for local / split hosting |
| `api/server.py` | API + static site for the container |

---

*Andela Production — SaaS & cloud deployment exercise.*
