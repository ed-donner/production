## MediNotes Pro — Healthcare consultation assistant
I built a small SaaS-style healthcare consultation assistant: doctors enter visit details (patient, date, notes), and the app streams back a structured summary—sections for the doctor’s records, next steps, and a patient-friendly email draft. The UI is a Next.js app (static export) with Clerk authentication; the backend is FastAPI, which validates Clerk JWTs, proxies to an OpenAI-compatible API (OpenRouter), and serves the built static assets from one process. I containerized the app with a multi-stage Dockerfile (Node build → Python runtime) so it can run as a single service (for example on AWS or any host that runs containers).


GitHub
[github-repo](https://github.com/haastrupea/MediNotes-pro)

Live URL
[MediNotes Pro](https://v4gjp58m68.eu-central-1.awsapprunner.com/)