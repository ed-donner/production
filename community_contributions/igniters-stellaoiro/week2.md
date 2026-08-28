# Stella's AI Digital Twin — Week 2 Project

**Student:** Stella Achar Oiro (Igniters cohort)  
**Live demo:** https://stella-twin.vercel.app  
**API (AWS App Runner):** https://3pramfenpd.us-east-1.awsapprunner.com/api/health  
**Repo:** https://github.com/Stella-Achar-Oiro/stella-twin

---

## What it does

An AI digital twin that represents Stella Achar Oiro on her personal site. Visitors can chat with it and ask about her background, projects, and experience. The twin answers in character, drawing on a personal summary and facts file, and remembers conversation history across turns using file-based memory.

Built on the **Next.js App Router** (the key Week 2 upgrade from Pages Router) with a FastAPI backend.

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Next.js 15 (App Router), TypeScript, Tailwind CSS |
| Backend | FastAPI, Python 3.12, OpenAI `gpt-4o-mini` |
| Memory | File-based JSON (per-session, 24 h TTL, 10-turn cap) |
| Deployment | Vercel (frontend) · AWS App Runner via ECR (backend) |

## Key features

- **App Router** — Server and client components properly separated; `Chat.tsx` is a `"use client"` component, layout and pages are server components
- **SSE streaming** — Token-by-token streaming via FastAPI `StreamingResponse` + browser `ReadableStream`; cursor animation while streaming
- **File-based memory** — Conversation history persisted as JSON in `memory/`; keyed by session ID, 24 h TTL, 10-turn cap
- **Starter questions** — Four clickable prompts on the empty state so users know what to ask
- **Personal persona** — System prompt grounded in `data/summary.txt` and `data/facts.txt`; twin stays in character as Stella

## Architecture

```
browser → Next.js App Router (Vercel)
               │  POST /api/chat  ← SSE stream
               ▼
          FastAPI (App Runner)
               │
               ├── personality.py   system prompt from data files
               ├── memory.py        file-based session history
               └── api/chat.py      SSE streaming endpoint
```
