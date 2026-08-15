# Digital Twin

A **chat-style “digital twin”** for a personal site: visitors talk to an assistant that **represents you** using your profile notes, LinkedIn context, writing style, and brief facts—powered by an LLM and grounded in the context you define in the backend.

The UI is a simple **message thread**; the API keeps a **session id** so the conversation can continue across turns.

> Demo / course project — tune tone, facts, and deployment for your own use case.

## Tech stack


| Layer              | Technologies                                                                                                                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Frontend**       | [Next.js](https://nextjs.org) (App Router), [React](https://react.dev), [TypeScript](https://www.typescriptlang.org), [Tailwind CSS](https://tailwindcss.com), [Lucide](https://lucide.dev) |
| **Backend**        | [FastAPI](https://fastapi.tiangolo.com), [Mangum](https://mangum.io) (ASGI → AWS Lambda), [OpenAI](https://platform.openai.com) Python SDK                                                  |
| **Data / context** | Structured prompts from `backend/resources` (e.g. facts, summary, LinkedIn, style); [PyPDF](https://pypdf.readthedocs.io) where PDFs are used                                               |
| **AWS**            | [AWS Lambda](https://aws.amazon.com/lambda/), [API Gateway](https://aws.amazon.com/api-gateway/) (HTTP API), [boto3](https://boto3.amazonaws.com/)                                          |
| **Packaging**      | [Docker](https://www.docker.com) (Lambda-compatible Linux/amd64 deps via `deploy.py`), zip deployment artifact                                                                              |


## Layout


| Path                                 | Role                                     |
| ------------------------------------ | ---------------------------------------- |
| `frontend/`                          | Next.js app and chat UI                  |
| `backend/server.py`                  | FastAPI app (local or behind Mangum)     |
| `backend/lambda_handler.py`          | Lambda entry (`Mangum` wrapper)          |
| `backend/deploy.py`                  | Build `lambda-deployment.zip` for upload |
| `backend/context.py`, `resources.py` | System prompt and twin context           |


## Local development

From `frontend/`: `npm install` → `npm run dev`. Point the fetch URL at your local API or deployed stage as configured in your environment.

From `backend/`: run the FastAPI app per **Week 2** course instructions; keep **API keys and AWS secrets** out of git (use `.env`, confirm `.gitignore`).

---

## Links


|                       |                                                             |
| --------------------- | ----------------------------------------------------------- |
| **Source repository** | [GITHUB REPO](https://github.com/tundewey/My-Digital-Twin/) |
| **AWS deployment**    | [AWS LINK](https://d2iorcr1jzfnk.cloudfront.net/)           |


*Andela Production — Week 2 Digital Twin exercise.*