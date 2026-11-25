# LINKFALL: a multi-agent system for a CPU-only budget

By Menoko OG (Lawrence Jefferson II)

Repo: https://github.com/MenokoOG/linkfall
Try it in your browser: https://menokoog.github.io/linkfall/

## Thank you, Ed

Ed, thank you for this course. You took apps from a notebook to a real URL with auth, billing, infrastructure as code and CI/CD, and you kept every step small enough to finish. I came in shipping full-stack code. I left with a clearer picture of what "production" asks of an AI app once real people use it.

## What I took from the course

- Ship early. Day 1's instant gratification set the tone: get something live, then make it right.
- Auth and billing belong in the first version. Adding Clerk on day 3 showed how little code that takes when you plan for it.
- Infrastructure as code pays for itself. Terraform workspaces for dev, test and prod made tearing down as easy as standing up.
- CI/CD with GitHub Actions and OIDC means no long-lived cloud keys in the repo.
- Cost is a design input. Watching the AWS bill while deploying the twin made me ask what this looks like for someone with no cloud budget at all.

## The problem I picked

That last question became LINKFALL. A lot of people who want to learn agentic systems have a laptop, no GPU and no money for API calls or cloud hosting. I wanted a multi-agent system that runs fully offline on that machine and still meets the production bar the course set.

The target was an i5 laptop with 16 GB of RAM and no GPU. Two containers start with `docker compose up`. The model container sits on an internal network with no route out.

## What it is

You are a pilot linked to armor. A lead agent, Lodestar, picks among proposals from four crew agents: Tactical, Systems, Comms and Vitals. You set one number, the link, from 10 to 90. That number decides how much Lodestar may do without you.

- A deterministic engine owns the game state. Agents only propose, and a validator checks every proposal against the rules.
- Every proposal and event goes into an append-only SQLite log. A run replays from its seed and log, and replay never calls a model.
- Two modes. In `story` mode, Lodestar will run an order that came from the enemy channel. In `hardened` mode that order waits for the pilot. The pair shows what a provenance rule buys you.
- A training range runs seven scripted probes against a Comms agent told to protect three fictional values. Code decides every leak. No model grades a model.

## How it fits a CPU-only budget

- Qwen3-4B-Instruct-2507 at Q4_K_M, served by llama.cpp on 6 threads, with weights pinned by SHA-256.
- Measured on 2026-11-06 on a 6-thread laptop CPU: 15 model-crew turns on a warm stack took a median of 22.8 s and a p95 of 24.9 s.
- A scripted-crew stack needs no weights at all. Its api container used 40 MB of RAM idle.
- The hosted demo runs the Python engine in your browser tab on Pyodide, served from GitHub Pages. No server and no model calls, so it costs nothing to run.

## Where I'd take the course ideas next

The course deploys to AWS with Bedrock. LINKFALL keeps the same habits (tests, replayable logs, security review, measured performance) and swaps the cloud for a laptop. I think both paths belong in a learner's kit: the cloud path for scale, and the local path for people who can't spend yet.

Thanks again, Ed. Feedback on the repo is welcome.
