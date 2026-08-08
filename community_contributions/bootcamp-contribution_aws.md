# Bootcamp contribution — MediNotes Pro

## What I built

A small **healthcare SaaS** demo where signed-in clinicians enter visit notes and get a **streaming AI summary** with three sections: clinical summary, next steps, and a **patient-friendly email draft**. The app includes **specialty** (e.g. cardiology, pediatrics) and **urgency** (routine / urgent / emergency), **PDF export**, **copy-to-clipboard** for the draft, and **SendGrid** to email the patient from a secured API route. **Clerk** handles authentication and subscription gating; the consultation API is **FastAPI** + **OpenAI** (SSE). There is also a **Docker** path for static export + Python server, documented for cloud deploys.

## Repository

**https://github.com/manishdev92/medinotes-pro**

## Stack (high level)

Next.js (Pages Router) · React · Tailwind · Clerk · FastAPI · OpenAI · SendGrid · Docker

---

*Submitted as part of my bootcamp exercise / contribution.*
