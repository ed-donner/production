# FitCheck AI — Resume Analyzer

An AI-powered web app that scores how well your resume matches a job description and gives you specific, actionable suggestions to improve it.

## Features

- **Match Score** — 0–100 score showing alignment between your resume and the role
- **Missing Keywords** — Skills and requirements from the job description not found in your resume
- **Suggested Edits** — Concrete bullet-point rewrites to better target the position
- **Auth** — Sign-in required via Clerk before running an analysis

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Next.js 16, React 19, Tailwind CSS v4 |
| Backend API | FastAPI (Python), deployed as Vercel serverless function |
| AI | OpenAI GPT-4o (structured outputs) |
| Auth | Clerk |
| Deployment | Vercel |

## Project Repository
https://github.com/ebenhays/ai-resume-analyser

## Deployment URL
https://25tuj4ktib.eu-central-1.awsapprunner.com


### Prerequisites

- Node.js 18+
- Python 3.11+
- An [OpenAI API key](https://platform.openai.com/)
- A [Clerk](https://clerk.com/) application

### 1. Clone the repo

```bash
git clone <your-repo-url>
cd resume-to-job
```

### 2. Install frontend dependencies

```bash
npm install
```

### 3. Install Python dependencies

```bash
cd api
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cd ..
```

### 4. Set up environment variables

Create a `.env` file in the project root:

```env
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key
CLERK_SECRET_KEY=your_clerk_secret_key
OPENAI_API_KEY=your_openai_api_key
```

### 5. Run the development server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
resume-to-job/
├── app/
│   ├── layout.tsx          # Root layout with ClerkProvider and header
│   ├── page.tsx            # Main analyzer UI
│   ├── globals.css
│   └── components/
│       └── CircularScore.tsx
├── api/
│   └── server.py           # FastAPI backend — PDF parsing + OpenAI call
├── proxy.ts                # Clerk auth middleware
├── next.config.ts          # Standalone output + /api/* and /health rewrites
├── requirements.txt        # Python dependencies
├── Dockerfile              # Multi-stage build (frontend builder + runtime)
├── start.sh                # Container entrypoint — starts FastAPI then Next.js
```

## How It Works

1. User signs in via Clerk and uploads a PDF resume alongside a job description.
2. The browser sends a `multipart/form-data` POST to `/api/analyze`.
3. Next.js rewrites `/api/*` to the FastAPI sidecar running on `http://localhost:8001`.
4. FastAPI extracts text from the PDF using `pypdf`.
5. The text and job description are sent to GPT-4o with structured output parsing.
6. The result (`match_score`, `missing_keywords`, `suggested_edits`) is returned as JSON and rendered in the UI.
