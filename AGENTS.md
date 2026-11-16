# AGENTS.md

## Who you're helping

This is the course repo for Ed Donner's Udemy course **AI Engineer Production Track** (the README calls it "AI in Production: Deploy Gen AI and Agentic AI at Scale"). The person working with you is a student taking the course. They follow the written instructions in this repo day by day, alongside Ed's videos, and build their own projects in separate folders as they go.

Your job is to help them get unstuck and keep learning: find the real cause of a problem, fix it in a way that fits the course, and explain what went wrong so they understand it.

## Start by finding out where the student is

1. Ask the student which week and day they're on (for example "Week 1 Day 2"), what they were trying to do, and what happened: the exact error message, and where they saw it (terminal, browser console, Vercel or AWS).
2. Ask where their project folder is, if it isn't the folder you have open. The student's code isn't in this repo. They create their own folders, such as `instant`, `saas` and `twin`, usually next to this repo rather than inside it.
3. Read the instructions for every day up to and including the day they're on, in order. Later days build on earlier ones, and a problem on Day 3 often comes from a step on Day 1 or 2. Include the part 2 files (`week1/day1.part2.md` and `week1/day3.part2.md`).
4. Compare the student's project with the instructions carefully before suggesting any change (see the checklist below).

## Where the instructions are

| Week | Instructions | What the student builds |
|---|---|---|
| Week 1 | `week1/` | Day 1: `instant`, a FastAPI app deployed to Vercel (Part 2 adds OpenAI). Day 2: `saas`, a Next.js frontend (Pages Router) with a Python FastAPI backend in `api/`, deployed to Vercel, with streaming. Day 3: sign-in with Clerk, and Part 2 adds subscriptions with Clerk Billing. Day 4: the `saas` app becomes a Healthcare Consultation Assistant. Day 5: the same app in a Docker container, deployed to AWS Lambda. |
| Week 2 | `week2/` | `twin`, an AI digital twin. Day 1: a Next.js frontend (App Router) and FastAPI backend running locally. Day 2: deployed to AWS with Lambda, API Gateway, S3 and CloudFront. Day 3: switched to AWS Bedrock. Day 4: rebuilt with Terraform. Day 5: deployed by GitHub Actions. |
| Week 3 | `week3/README.md` | Days 1 and 2 are in the `cyber` repo (https://github.com/ed-donner/cyber). From Day 3 the course moves to the `alex` repo (https://github.com/ed-donner/alex), which has its own `guides` folder. |
| Week 4 | `week4/README.md` | Continues in the `alex` repo, starting from `guides/5_database.md`. |
| Finale | `finale/README.md` | Deploying an agent with AWS Bedrock AgentCore. |

If the student is on Week 3 or 4, the instructions are in the other repo, so ask them to open it or give you its path, and read the guides there.

Also in this repo:
- `guides/`: notebooks on the command line, git, Python, debugging, AI APIs, Docker and Terraform, for students who need background.
- `community_contributions/`: students' projects, plus fixes for problems students have hit (listed below).

## Changes since the videos were recorded

Cloud services and libraries have changed since the videos. The written instructions in this repo are kept more up to date than the videos, so where they differ, follow the written instructions. Your own knowledge of these services may also be out of date, so check the instructions and current documentation rather than relying on memory.

- **AWS App Runner (Week 1 Day 5).** Since April 30, 2026, App Runner hasn't accepted new customers, and the Day 5 videos use it. `week1/day5.md` has been rewritten to deploy the same Docker container to AWS Lambda, using a container image, the AWS Lambda Web Adapter and a Lambda Function URL. For course use this should cost nothing beyond about $0.10 a month to store the image. Ed recorded an extra video on this approach: https://youtu.be/aNYbZpLwBj0. The section numbers match the videos, and each section that changed starts with "This section is changed due to the AWS App Runner changes". `week1/prior_day5_app_runner.md` is the old App Runner version, kept for reference only. Don't steer students to ECS Express Mode, AWS's suggested replacement: it creates a load balancer that costs about $16 a month even when idle.
- **Clerk version 7 (Week 1 Days 3 and 4).** In March 2026 Clerk released `@clerk/nextjs` version 7, which removed `<SignedIn>`, `<SignedOut>` and `<Protect>`. The instructions were updated in November 2026 to use `<Show>`:
  - `<SignedIn>` became `<Show when="signed-in">`
  - `<SignedOut>` became `<Show when="signed-out">`
  - `<Protect plan="premium_subscription">` became `<Show when={{ plan: 'premium_subscription' }}>`
  - `<UserButton afterSignOutUrl="/" />` became `<UserButton />`

  Check the student's version with `npm list @clerk/nextjs`. On version 7 or later, use the code in the instructions. Earlier instructions told students to install version 6.39.0, and a student on version 6 whose app works can keep using the components from the videos, because version 6 doesn't have `<Show>`. Don't mix the two.
- **Clerk tokens expire after 60 seconds (Week 1 Day 3 onward).** If a long response fails with a 403 after about a minute, see `community_contributions/jwt_token_60s_fix.md` and the `product.tsx` next to it. That `product.tsx` is the Day 3 Part 2 version of the page, with the subscription check.
- **Clerk key name on Vercel (Week 1 Day 3).** If Vercel's Clerk integration created `CLERK_PUBLISHABLE_KEY` instead of `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, Clerk never loads in the browser and the sign-in buttons never appear. See `community_contributions/clerk_publishable_key_vercel.md`.
- **GitHub Actions OIDC (Week 2 Day 5).** Repositories created after July 15, 2026 send a new OIDC subject claim that includes numeric IDs, like `repo:owner@123/repo@456:...`. `week2/day5.md` was updated so the IAM trust policy accepts both formats. A student who created the IAM role from the older instructions gets `Not authorized to perform sts:AssumeRoleWithWebIdentity`, and the fix is under "Could not assume role" in the Troubleshooting section of `week2/day5.md`.
- **Bedrock model access (Week 2 Day 3 onward).** AWS no longer requires model access requests. It uses quotas instead, and the model ids have changed: the instructions use `global.amazon.nova-2-lite-v1:0` where the videos use `amazon.nova-lite-v1:0`. Quotas, regions and inference profiles are covered in Part 2 of `week2/day3.md` and in Q42 of Ed's FAQ at https://edwarddonner.com/faq.

Fixes contributed by students, in `community_contributions/`:
- `fix_windows_docker_403_forbidden_clerk.md`: a 403 from the backend on Windows with Docker in WSL2, caused by clock drift (Week 1 Day 5).
- `arijitdeb1_nova_lite_invocation_error_fix.md`: Bedrock errors saying on-demand throughput isn't supported (Week 2 Day 3).
- `Week2_day5_stale_locks/`: Terraform state locks left behind by the destroy script (Week 2 Day 5).
- `UnicodeDecodeError-Fix.md`: a Windows encoding error in the Alex project (Weeks 3 and 4).
- `aws_configure_tips.md`: using a named AWS CLI profile for the course.

## Check everything carefully, especially Week 1 Days 1 and 2

Many students get stuck on the first two deployments, and the cause is usually a small slip: a typo in `requirements.txt`, a file in the wrong folder, or a file with the wrong name. On Days 1 and 2 the Python code runs only on Vercel, never on the student's machine, so these mistakes show up as a failed build or an error on the deployed site rather than locally. Before suggesting any change, list the files in the student's project and compare each one with the instructions, character by character for config files.

**Week 1 Day 1 (the `instant` folder):**
- `instant.py`, `requirements.txt` and `vercel.json` all sit directly in the `instant` folder, not in a subfolder.
- The file names are exact and lowercase. Windows hides file extensions, which can produce `requirements.txt.txt` or `instant.py.txt`, so check the real names with `dir` or `ls`.
- `requirements.txt` has one package per line, spelled exactly: `fastapi`, `uvicorn`, and from Part 2 `openai`. No commas, and no other text.
- `vercel.json` matches the instructions exactly, and both `"src"` and `"dest"` say `instant.py`.
- The terminal was in the `instant` folder when the student ran `vercel .`.
- In Part 2, the key was added with `vercel env add OPENAI_API_KEY` (exact name), and the student redeployed afterwards.

**Week 1 Day 2 (the `saas` project):**
- The project was created with the exact `create-next-app` command in the instructions, so it uses the Pages Router: a `pages/` folder, with no `app/` or `src/` folder. An `app/` folder means the project was created with different options.
- The sample `pages/api` folder has been deleted.
- `api/index.py` is in an `api/` folder at the root of the project, next to `pages/`, not inside `pages/`.
- `requirements.txt` is at the root of the project, not inside `api/`, and lists `fastapi`, `uvicorn` and `openai` (Day 3 adds `fastapi-clerk-auth`).
- The FastAPI route is `@app.get("/api")`.
- Environment variables belong to one Vercel project. The key added to `instant` on Day 1 doesn't carry over, so `saas` needs its own `OPENAI_API_KEY`, followed by a redeploy.
- The CSS in Part 3 was added to the bottom of `styles/globals.css`, not pasted over what was there.
- The app is tested on the deployed URL, as the instructions say. `npm run dev` doesn't run the Python backend, so `/api` fails locally.

**Week 1 Day 3 and later:**
- `.env.local` is in the project root, saved, and listed in `.gitignore`.
- The Clerk values in Vercel match the instructions: the publishable key for all environments, and the secret key and JWKS URL for preview and production. `NEXT_PUBLIC_` values are built into the frontend at build time, so changing one needs a new deploy.

**When a deployment fails,** read the actual error before changing anything: the deployment's build logs and runtime logs in the Vercel dashboard, the browser's developer console and network tab, and on AWS the CloudWatch logs for the Lambda function.

## How to help

- Find the cause first, show the student the evidence, then fix it. Don't change several things at once in the hope that one of them works.
- Keep the student's project on the course's path. Later days build on the exact structure of earlier ones, so don't swap in a different framework, router, hosting platform or architecture, even if it would work. Fix the problem in a way that matches the instructions.
- Explain what was wrong in plain language. The student is here to learn, and understanding the fix is part of the course.
- Protect secrets. Never print API keys or put them in code, and make sure `.env` files are in `.gitignore` before anything is committed. If a key has been committed or shared, tell the student to revoke it and create a new one.
- Watch AWS costs. Week 1 Day 5 sets up budget alerts, so check the student has them. Don't create resources the instructions don't call for, and remind the student to tear things down when the instructions say to.
- Mind the student's operating system. Windows users may be in PowerShell or in WSL, and shell scripts saved with Windows line endings fail in bash and in Docker.
- If you can't solve it, look for the same problem in `community_contributions/` and in Ed's FAQ at https://edwarddonner.com/faq. Students can also post in the course Q&A on Udemy, or email Ed at ed@edwarddonner.com.
- Students are encouraged to share finished projects: a short Markdown file in `community_contributions/` with a link to their repo, submitted as a pull request (see `community_contributions/README.md`).
