# Business Idea Generator - Full-Stack Next.js Edition (no python, app router)

This project is a complete, full-stack implementation of the **Business Idea Generator** from the "Generative and Agentic AI in Production" course by Ed Donner ❤️, built entirely with Next.js using the App Router. It serves as a complementary guide for the first week's project (Days 1-5) for those who wish to follow the course using a unified TypeScript/Next.js stack instead of the Next.js + Python/FastAPI architecture taught in the original materials.

This repository can be found at: [https://github.com/roman-sh/saas]  
The original course material is available at: [https://www.udemy.com/course/generative-and-agentic-ai-in-production]

This implementation covers the core application from `day2.md` and the authentication setup from `day3.md`. It does not include the subscription and billing features from `day3.part2.md`.

## Key Architectural Differences from the Course

The primary goal of this repository is to showcase an alternative architecture. Here are the main deviations from the course's `day2.md` and `day3.md` guides:

-   **Unified Next.js Backend:** Instead of using a separate Python/FastAPI backend in an `/api` directory, this project uses a Next.js API Route Handler (`src/app/api/idea/route.ts`). This simplifies the architecture, streamlines deployment, and allows for a single language (TypeScript) across the entire stack.
-   **Next.js Middleware for Authentication:** User authentication and route protection are handled by Next.js Middleware (`src/middleware.ts`) in conjunction with Clerk, which is the standard pattern for the App Router. This differs from the client-side token passing shown in the course.
-   **SSE Streaming with Hono:** To handle the complexities of streaming from the `@openai/agents` SDK, the API route uses Hono's `streamSSE` helper. This provides a clean solution for managing the SSE connection and ensures newline characters are preserved by sending data as JSON strings, which is crucial for correct Markdown rendering.

## Getting Started

The setup process is simpler than the multi-language version.

1.  Follow the standard Node.js/Next.js setup: clone, `npm install`, and create your `.env.local` file.
2.  You will need to add your `OPENAI_API_KEY` and the two required Clerk variables (`NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY`) to the `.env.local` file. The `CLERK_JWKS_URL` is not needed because the official `@clerk/nextjs` SDK uses a different verification strategy than the Python library in the course.

## Deployment

This repository is configured for two deployment targets, each with a different approach compared to the course material.

### Option 1: Vercel

Deployment to Vercel is simpler than the course version, as there is no Python environment to configure.

1.  Link the project with `vercel link`.
2.  Add your secrets (`OPENAI_API_KEY`, `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`) with `vercel env add`.
3.  Deploy with `vercel --prod`.

### Option 2: AWS App Runner with Docker

This deployment provides a full-stack, containerized alternative to the static Next.js + Python backend architecture described in `day5.md`.

-   **Architecture:** The `Dockerfile` creates a single, self-contained Node.js server that runs the entire Next.js application (frontend and backend). This contrasts with the course's approach of exporting a static frontend and serving it from a Python server.
-   **Configuration:** The deployment process requires specific App Runner configurations that differ from the `day5.md` guide. The notes below are critical for a successful deployment.

#### AWS App Runner Configuration Notes

When deploying to AWS App Runner, pay close attention to the following critical configuration details discovered during deployment:

1.  **`HOSTNAME` Environment Variable (CRITICAL):**
    You **must** add an environment variable in the App Runner service configuration with the following values:
    -   **Name:** `HOSTNAME`
    -   **Value:** `0.0.0.0`

    *Reason: AWS App Runner injects its own `HOSTNAME` variable, which causes the Next.js standalone server to bind to an internal-only network interface. Overriding it with `0.0.0.0` forces the server to listen on all interfaces, allowing it to accept traffic from App Runner's load balancer.*

2.  **Port Configuration:** The port number you set in the App Runner service configuration (e.g., `8080`) is automatically passed into the container as the `PORT` environment variable. Our application is configured to listen on this variable, so the port you choose in the UI is the one your server will use.

3.  **Health Check:**
    Configure an **HTTP** health check pointing to the `/health` endpoint. The middleware `matcher` is configured to completely exclude this route from any Clerk logic.

#### Troubleshooting

##### Deployment Fails with NO Application Logs

-   **Symptom:** The App Runner deployment fails, often with a health check timeout, and the "Application logs" tab is completely empty. You see system logs, but nothing from the application itself.
-   **Cause:** This is a strong indicator of an AWS account-level issue, such as service quotas or restrictions on older/limited-tier accounts. The service fails before the container can fully start and produce logs.
-   **Diagnosis:** The definitive test is to deploy the official AWS sample image from https://gallery.ecr.aws/aws-containers/hello-app-runner. If this simple image also fails to deploy, the problem is with the account, not your application.
-   **Solution:** The most reliable solution is to ensure you are using a **standard, fully-enabled AWS account**. Some accounts, regardless of age, may have service limitations (e.g., if created under an old "free tier" model or without a payment method). Using an account with full access to all services is required for App Runner to work correctly.

##### Deployment Fails, but Application Logs Show "Ready"

-   **Symptom:** The App Runner deployment fails on a health check timeout, but you can see the `✓ Ready...` message in the application logs.
-   **Cause:** This means your container is running, but the health checker cannot get a successful response. There are two common causes:
    1.  **Network Binding (`HOSTNAME`):** The Next.js server is binding to the wrong network interface and isn't reachable from the App Runner load balancer. This is the most likely cause.
    2.  **Middleware Interference:** The health check route is being intercepted by Clerk middleware, which is causing it to return an error (like a 404) instead of a `200 OK`.
-   **Solution:**
    1.  First, ensure the `HOSTNAME=0.0.0.0` environment variable is set in your service configuration.
    2.  Second, ensure your `src/middleware.ts` `matcher` is configured to completely exclude the `/health` route.
