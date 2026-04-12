# 🧠 Learning can be Fun

### 🌐 Play the Live App: [learningfun-gamma.vercel.app](https://learningfun-gamma.vercel.app)
*(Production URL: [learning-9rra7wkty.vercel.app](https://learning-9rra7wkty-mikeaig4reals-projects.vercel.app))*

"Learning can be Fun" is a robust, full-stack Trivia application designed to test your knowledge across multiple categories. Built with modern, highly interactive UI and backed by conversational AI seamlessly tutoring players based on their mistakes.

## ✨ Features
- **5 Dynamic Categories:** Music, Nature, Science, Religion, and History.
- **Glassmorphism UI:** Highly aesthetic, modern interface utilizing TailwindCSS v4 transitions, glow effects, backdrop blurring, and text lock-down (`select-none`) to provide a mobile-app feel.
- **AI-Powered Structured Outputs:** Leverages OpenRouter (`gpt-4o-mini`) via a Python FastAPI backend perfectly conforming to explicit Pydantic JSON schemas to ensure structurally sound trivia options every query.
- **Personalized AI Coaching:** Calculates total score gradients from Beginer to Pro, and feeds historical misses to the AI tutor endpoint (`/api/feedback`) in order to generate short, encouraging post-play feedback.

## 🛠️ Technology Stack
- **Frontend:** Next.js (Pages Router), React, Tailwind CSS v4.
- **Backend:** Python FastAPI, Pydantic, OpenAI SDK (configured for OpenRouter).
- **Environment Management:** `uv`
- **Deployment:** Optimized for Vercel Serverless Functions.

## 🚀 Getting Started

### 1. Backend Setup
We utilize `uv` to manage Python configurations aggressively fast.
```bash
# Pull dependencies
uv sync

# Provide your OpenRouter Key
echo 'OPENROUTER_API_KEY="sk-or-v1-..."' > .env
```

### 2. Frontend Setup
```bash
npm install
```

### 3. Local Development
For the absolute smoothest local development experience mimicking production behavior, Vercel covers both APIs flawlessly.
```bash
# Run the Next.js Client and Python backend synchronously 
vercel dev
```
*(Alternatively, run `uv run uvicorn api.index:app --reload` and `npm run dev` in two separate terminals!)*

## 🌐 Deployment
To deploy this application immediately to the Vercel edge:
```bash
vercel --prod
```
