# Michael's Digital Twin

### Chat Live: [https://dvofgvxpqpz8c.cloudfront.net](https://dvofgvxpqpz8c.cloudfront.net)

This project is a high-performance, serverless **Digital Twin** of me. It utilizes a modern "Serverless First" architecture on AWS to provide a lightning-fast, secure, and aesthetically stunning conversational AI experience.

## Features
- **Aesthetic Glassmorphism UI:** Built with Next.js 15 and Tailwind CSS, featuring smooth animations, backdrop blurring, and mobile-responsive layouts.
- **Rich Markdown Support:** Michael's responses are fully rendered with Markdown, supporting bold text, lists, code snippets, and professional typography.
- **Cloud-Native Memory:** Chat history is persisted in a private AWS S3 bucket, allowing for long-running, context-aware conversations.
- **Dual Infrastructure:** Optimized for both local development (Vite/FastAPI) and production (CloudFront/S3/Lambda).

## Technology Stack & Infrastructure

### Frontend
- **Framework:** Next.js 15 (App Router)
- **Styling:** Tailwind CSS v4 (Glassmorphic Design System)
- **Rendering:** `react-markdown` with `remark-gfm` for rich text responses.
- **Deployment:** Hosted as a Static Site on **Amazon S3** with **Amazon CloudFront** providing global HTTPS delivery.

### Backend
- **Framework:** Python FastAPI
- **Lambda Bridge:** `Mangum` (Serverless ASGI adapter)
- **Compute:** **AWS Lambda** (Python 3.12)
- **Gateway:** **Amazon API Gateway** (HTTP API) handling routing and CORS.

### AI & Data
- **AI Model:** **Amazon Bedrock** (`amazon.nova-2-lite-v1:0`)
- **SDK:** OpenAI SDK (configured for Amazon Bedrock compatibility)
- **Storage:** **Amazon S3** for persistent session JSON storage.

---

## Solved Engineering Challenges

During the manual deployment to AWS, several "production-grade" challenges were addressed:

### 1. Mixed Content Security
**The Issue:** Browsers block requests from an insecure site (S3 HTTP) to a secure API (API Gateway HTTPS).
**The Solution:** Provisioned an **Amazon CloudFront** distribution with an SSL certificate to serve the frontend over HTTPS, enabling secure end-to-end communication.

### 2. Environment Variable Precedence
**The Issue:** Next.js build processes prioritize `.env.local` over `.env.production`. This caused the initial deployment to point to `localhost`.
**The Solution:** Corrected the environment configuration to ensure the **API Gateway Invoke URL** was correctly "baked" into the static JS assets during the production build.

### 3. Lambda Binary Compatibility
**The Issue:** The local build machine was running Python 3.13, while AWS Lambda uses Python 3.12. This caused architecture mismatches for C-extensions like `pydantic_core`.
**The Solution:** Updated the `deploy.py` script to explicitly target **Python 3.12** wheels and the `manylinux2014` platform during the packaging process, ensuring 100% compatibility with the AWS runtime.

### 4. CORS Stringency
**The Issue:** API Gateway and Lambda are extremely sensitive to trailing slashes in CORS Origins (e.g., `...net/` vs `...net`).
**The Solution:** Normalized all CORS settings across API Gateway and FastAPI to use the exact CloudFront distribution domain without a trailing slash.
