# Learning can be Fun

### Play the Live App: [learningfun-gamma.vercel.app](https://learningfun-gamma.vercel.app) or [AWS Mirror](https://vismmexoi5ivcq4qdnhao5u64u0pplxv.lambda-url.eu-west-2.on.aws/)

"Learning can be Fun" is a robust, full-stack Trivia application designed to test your knowledge across multiple categories. Built with modern, highly interactive UI and backed by conversational AI seamlessly tutoring players based on their mistakes.

## Features
- **5 Dynamic Categories:** Music, Nature, Science, Religion, and History.
- **Glassmorphism UI:** Highly aesthetic, modern interface utilizing TailwindCSS v4 transitions, glow effects, backdrop blurring, and text lock-down (`select-none`) to provide a mobile-app feel.
- **AI-Powered Structured Outputs:** Leverages OpenRouter (`gpt-4o-mini`) via a Python FastAPI backend perfectly conforming to explicit Pydantic JSON schemas to ensure structurally sound trivia options every query.
- **Personalized AI Coaching:** Calculates total score gradients from Beginner to Pro, and feeds historical misses to the AI tutor endpoint (`/api/feedback`) in order to generate short, encouraging post-play feedback.

## Technology Stack
- **Frontend:** Next.js (Pages Router), React, Tailwind CSS v4.
- **Backend:** Python FastAPI, Pydantic, OpenAI SDK (configured for OpenRouter).
- **Environment Management:** `uv`
- **Deployment:** Optimized for Vercel Serverless Functions and AWS Lambda (Containerized).

## Account Verification & Migration Disclaimer

I originally intended to use **AWS App Runner** for this deployment, but encountered the following AWS account setup restrictions:

> **Complete your account setup**
> Thanks for signing up for Amazon Web Services. If we have directed you to this page, then you have either not finished registering, or your account is currently on free plan.
> 
> **Account setup checklist**
> - Provided all required information during sign-up. This includes adding a payment method, completing identity verification, and selecting a support plan.
> - Responded to any additional information we have requested by email. Check your spam and junk email folders to make sure you have not missed any such requests.
> - Verified your credit card information. We might temporarily hold up to $1 USD (or an equivalent amount in local currency) as a pending transaction for 3-5 days to verify your identity. This is an authorization, and you might need to contact your card issuer to approve it.
> - It might take up to 24 hours to fully activate your AWS services. If you can’t access your services after that time, contact support.
> 
> **Complete your AWS registration**
> **Free account plan access limitations**
> Free account plans have limited access to certain services and features. Upgrade your account plan to remove limitations.

**Due to these restrictions, I successfully moved the backend to AWS Lambda functions.** This shift allows the application to run within the "Always Free" tier without requiring the account "upgrade" or provisioned memory costs associated with App Runner.