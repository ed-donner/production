# Fixing Missing Environment Variables in Docker Builds (Clerk + Next.js)

## Context
During `next build` inside a Docker multi-stage image, I got:

Error: @clerk/clerk-react: Missing publishableKey.
Error occurred prerendering page “/”.
Export encountered an error on /, exiting the build.

Root cause: at build/prerender time, Next.js needs **both** Clerk keys in the environment:
- Client: `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- Server/SSR: `CLERK_PUBLISHABLE_KEY`

If they’re not present **before** `npm run build`, the build fails.

---

## Solution

### 1) Dockerfile (frontend builder stage)
Expose the keys as ENV **before** `npm run build`:

```dockerfile
FROM node:22-alpine AS frontend-builder
WORKDIR /app

COPY package*.json ./
RUN npm ci
COPY . .

ARG NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
ARG CLERK_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY}
ENV CLERK_PUBLISHABLE_KEY=${CLERK_PUBLISHABLE_KEY}

RUN npm run build

Do not bake CLERK_SECRET_KEY at build time (secrets only in runtime/backends).

## Build args usage

```bash
docker build \
  --platform linux/amd64 \
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" \
  --build-arg CLERK_PUBLISHABLE_KEY="$CLERK_PUBLISHABLE_KEY" \
  -t consultation-app .
