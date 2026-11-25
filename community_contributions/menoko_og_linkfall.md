# LINKFALL by Menoko OG

## Repo

- GitHub: https://github.com/MenokoOG/linkfall
- Live demo in your browser: https://menokoog.github.io/linkfall/

## Brief description

LINKFALL is a multi-agent system built for a CPU-only budget. It runs offline on a laptop with an i5, 16 GB of RAM and no GPU, with no API or cloud costs.

You are a pilot linked to armor. A lead agent, Lodestar, picks among proposals from four crew agents. You set one number, the link, from 10 to 90, and it decides how much Lodestar may do without you.

- A deterministic engine owns the state. Agents only propose, and a validator checks every proposal.
- Every event goes into an append-only SQLite log. A run replays from its log without calling a model.
- A training range probes a Comms agent for values it was told to protect. Code decides every leak.
- Stack: Python 3.13, FastAPI, plain ES modules, Docker Compose, and Qwen3-4B-Instruct-2507 (Q4_K_M) on llama.cpp.
- Measured on a 6-thread laptop CPU: median 22.8 s per model-crew turn, p95 24.9 s.
- The hosted demo runs the Python engine in the browser on Pyodide, served from GitHub Pages, so it costs nothing to run.

## The experience

Ed, thank you for this course. You took apps from a notebook to a real URL with auth, billing, Terraform and CI/CD, and you kept every step small enough to finish.

What stuck with me:

- Ship early, then make it right.
- Auth and billing belong in the first version.
- Infrastructure as code makes tearing down as easy as standing up.
- GitHub Actions with OIDC keeps long-lived cloud keys out of the repo.
- Cost is a design input.

That last one became LINKFALL. Plenty of people who want to learn agentic systems have a laptop and no budget for cloud hosting or API calls. I kept the course's habits (tests, logs you can replay, security review, measured performance) and swapped the cloud for a local machine.

Feedback on the repo is welcome. Thanks again, Ed.
