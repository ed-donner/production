# Luna AI
**Luna**, a women’s health AI chat app: a Next.js frontend (Pages Router, Tailwind, streaming chat UI) and a **FastAPI** backend that verifies **Clerk** JWTs and streams replies from **OpenAI** over Server-Sent Events. Chats stay in the browser; the API is stateless aside from auth.

The app is packaged with **Docker** (static Next export served alongside the API) so it can run as a single container—aligned with **API + compute + delivery** patterns from a typical cloud course. Environment and secrets are injected at deploy time (OpenAI, Clerk JWKS, etc.).

You can deploy manually first (e.g. **AWS App Runner** or any container host) to validate the stack end-to-end, then optionally add **Terraform** for infrastructure as code and **GitHub Actions** with OIDC to AWS for repeatable CI/CD and remote state—same workflow style as a team project, without relying on one-off console steps.

## GitHub

[github.com/kihara-njoroge/women-health-app](https://github.com/Kihara-Njoroge/luna-womens-health)

## Live URL

https://mrydzptcyx.us-east-1.awsapprunner.com/
