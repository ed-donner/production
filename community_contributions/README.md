# SAAS Demo — Community Contribution

This folder contains a small Next.js demo that demonstrates streaming OpenAI responses rendered progressively as Markdown.

Contents:

- `docs/saas_demo_notebook.ipynb` — Notebook with examples for calling the local and deployed APIs.
- `README.md` — This file.

How to run locally

1. Set your OpenAI key in the shell:

```bash
export OPENAI_API_KEY="sk-..."
```

2. Install dependencies and run:

```bash
npm install
# SAAS Demo — Community Contribution

This contribution contains a small demo (Next.js) that showcases progressive streaming from OpenAI and rendering the model output as nicely formatted Markdown in the browser.

Live demo
-----------

https://saas-amber-delta.vercel.app/

What I changed and why
----------------------
- Added a small streaming demo which demonstrates how to proxy OpenAI streaming responses (server-side) and render them progressively in the browser (client-side). The goal is to show a compact, production-ready example that other contributors can reuse.
- Implemented a Server-Sent Events (SSE) endpoint that forwards OpenAI streaming responses to the browser as JSON chunks. The client buffers tokens and flushes complete paragraphs/lines to ReactMarkdown for clean, progressive rendering.

Files included in this contribution
-----------------------------------
- `docs/saas_demo_notebook.ipynb` — Notebook with examples for calling the local and deployed APIs (simple requests and an SSE streaming example).
- `.gitignore` — local ignores for the contribution folder.
- `README.md` — this file describing the demo and run instructions.

How it works (technical summary)
--------------------------------
- Server: `pages/api/stream.ts` (Next API route) makes a request to OpenAI with `stream: true`, reads the incoming stream, parses OpenAI-style `data: ...` streaming events, and forwards JSON SSE events to the client. It writes a final `event: done` when the stream completes.
- Client: `pages/index.tsx` opens an `EventSource('/api/stream')`, receives JSON `{ chunk }` events and a final `done` event. It buffers token text and flushes by paragraph or newline into a `ReactMarkdown` renderer so the UI updates progressively with clean Markdown blocks.
- Helper: `lib/getIdea.ts` centralizes OpenAI client initialization and protects build-time runs by providing a graceful fallback when `OPENAI_API_KEY` is not present.

How to run locally
-------------------
1. Set your OpenAI key in the shell (required for live OpenAI calls):

```bash
export OPENAI_API_KEY="sk-..."
```

2. From the repository root (the full app is at the repo root):

```bash
npm install
npm run dev
```

3. Open http://localhost:3000 and watch the demo. The page progressively shows Markdown as the model tokens arrive.

How to verify the streaming API (quick)
-------------------------------------
1. Use curl to confirm SSE streaming headers and chunks:

```bash
curl -N -H "Accept: text/event-stream" https://saas-amber-delta.vercel.app/api/stream | sed -n '1,50p'
```

2. You should see multiple `data: {"chunk": "..."}` lines and an `event: done` followed by `data: [DONE]` when the stream finishes.

Notes for maintainers
---------------------
- The deployed demo requires the `OPENAI_API_KEY` environment variable to be set in the Vercel project for streaming to function.
- The contribution intentionally includes only docs and the notebook to keep the upstream repo tidy; the full app lives at the repository root of this fork.

Contact / follow-up
-------------------
If you want, I can:
- Expand the notebook with a live-in-notebook streaming renderer.
- Extract smaller pieces as standalone utilities with tests.
- Add a short video/GIF showing progressive rendering for the README.

Enjoy!
