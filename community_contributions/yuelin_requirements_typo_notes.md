# Lesson Learned: A Small Typo, A Big Debugging Journey

> **Community Contribution:** Sharing a critical deployment mistake so others can avoid the same trap.

## Background

During **Week 1 Day 2** of the course, I deployed a Next.js + FastAPI app to Vercel. The goal was simple: get both frontend and backend working in production.

However, I repeatedly encountered errors:
- **Local**: `/api` returned `404 Not Found`
- **Vercel**: `/api` returned `500 Internal Server Error`

Initially, I suspected a limitation with Vercel and Python APIs. That assumption was **completely wrong**—the real cause was much simpler.

---

## My Debugging Journey

### 1. Wrong Initial Assumption
I assumed Vercel couldn't run FastAPI from the project root. This led me down the wrong path of trying Node.js API routes instead.

### 2. Misguided Experiments
- Reimplemented the OpenAI call in `pages/api/index.ts`
- Tried various streaming approaches
- Focused on platform limitations rather than checking basics

### 3. Teacher's Guidance: Simplify First
Ed suggested creating a minimal endpoint to isolate the issue:

```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse

app = FastAPI()

@app.get("/api")
def test():
    def event_stream():
        yield "bananas\n"
    return StreamingResponse(event_stream(), media_type="text/event-stream")
```

The goal: verify the deployment pipeline works before adding OpenAI, Markdown parsing, etc.

---

## The Root Cause

After carefully reviewing my setup, I discovered the **real issue**:

**I had named my dependencies file `requirement.txt` instead of `requirements.txt`**

Because of this single missing "s":
- Vercel never installed FastAPI or other Python packages
- The backend failed completely, producing 404/500 errors
- Days of debugging were caused by a one-letter typo

Renaming to `requirements.txt` immediately fixed everything.

---

## Working Solution Reference

For future learners, here's the minimal setup that works:

**File Structure:**
```
├── api/
│   └── bananas.py
├── requirements.txt
└── [your Next.js files]
```

**File: `api/bananas.py`**
```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse

app = FastAPI()

@app.get("/")
def stream_test():
    def event_stream():
        yield "bananas\n"
    return StreamingResponse(event_stream(), media_type="text/event-stream")
```

**File: `requirements.txt`** ⚠️ **Critical: Note the "s"**
```
fastapi
uvicorn
openai
```

**Local Testing:**
```bash
vercel dev
# Visit: http://localhost:3000/api/bananas
```

**Production Deploy:**
```bash
vercel --prod
# Visit: https://your-app.vercel.app/api/bananas
```

---

## Key Lessons Learned

### Technical Insights
- **File naming matters**: In production, a single typo can break everything
- **Check the fundamentals first**: Dependencies, environment variables, file paths
- **Vercel + FastAPI works perfectly** when configured correctly

### Debugging Approach
- **Don't blame the platform first**: Assume your setup has issues before assuming framework limitations
- **Simplify to isolate**: Start with minimal working examples, then add complexity
- **Verify each layer**: Dependencies → basic endpoint → full features

### Communication & Mindset
- **Express uncertainty properly**: Instead of "Vercel doesn't support X", say "I'm having trouble getting X to work on Vercel"
- **Take breaks when stuck**: Long debugging sessions make you miss obvious details
- **Ask for help sooner**: Fresh eyes catch simple mistakes faster

---

## Why This Matters

This mistake cost me days of frustration and led me to question the entire tech stack. But it taught me that:

1. **The simplest explanation is usually correct**
2. **Production deployments amplify small mistakes**
3. **Good debugging starts with verification, not assumption**

Hopefully this saves someone else from the same rabbit hole. Sometimes the biggest problems have the smallest causes.

---

**Special thanks to Ed for the patience and for teaching the value of simplifying first.** 🙏