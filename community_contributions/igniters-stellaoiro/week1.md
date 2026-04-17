# Zeya Antenatal — Week 1 Project

**Student:** Stella Achar Oiro (Igniters cohort)  
**Live demo:** https://zeya-antenatal.vercel.app  
**Repo:** https://github.com/Stella-Achar-Oiro/zeya-antenatal

---

## What it does

Zeya Antenatal is an AI-powered maternal health chatbot that supports pregnant women in **English and Swahili**. It answers antenatal questions, detects obstetric danger signs in real time, and streams responses token by token.

Inspired by an existing Zeya WhatsApp chatbot used in East Africa, rebuilt from scratch on the course tech stack.

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Next.js 14 (Pages Router), TypeScript, Tailwind CSS, Clerk v6 |
| Backend | FastAPI, Python 3.12, OpenAI `gpt-4o-mini` |
| Auth | Clerk |
| Deployment | Vercel (frontend + backend) |

## Key features

- **Danger sign detection** — 8-category regex (bleeding, convulsions, fetal movement, etc.) in both English and Swahili; fires before every AI call and shows an emergency alert
- **SSE streaming** — word-chunked token streaming via FastAPI `StreamingResponse` and a browser `ReadableStream` reader
- **Trimester-aware prompts** — system prompt adjusts guidance based on gestational age
- **Tool-calling loop** — model can call `record_unanswered_question` before responding
- **In-memory conversation history** — 6-turn cap, 24 h TTL, keyed by Clerk user ID
- **Markdown rendering** — `react-markdown` renders bold, lists, and paragraphs cleanly in chat bubbles
