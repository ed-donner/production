## MediNotes Consultation Studio

I modificed the healthcare SaaS application into a solution that helps clinicians reduce documentation overhead while maintaining professional, consistent, and patient-friendly communication:

Production App - https://myziq7veyx.eu-west-1.awsapprunner.com/

<br />

![Next.js](https://img.shields.io/badge/Next.js-16-black?logo=nextdotjs)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi)
![TypeScript](https://img.shields.io/badge/TypeScript-Frontend-3178C6?logo=typescript)
![Python](https://img.shields.io/badge/Python-API-3776AB?logo=python)
![Clerk](https://img.shields.io/badge/Auth-Clerk-6C47FF)
![OpenAI](https://img.shields.io/badge/AI-OpenAI-412991?logo=openai)


## Core Features

- AI consultation report generation using OpenAI.
- Structured output with three sections:
  - Summary for clinical records.
  - Next steps for provider action.
  - Draft patient email in plain language.
- Live streaming response (Server-Sent Events) for fast feedback.
- Authentication and protected workspace using Clerk.
- Subscription/paywall enforcement with Clerk `Protect` + `PricingTable`.
- Consultation history persisted in SQLite.
- Favorite (pin) important consultations for quick access.
- Search and filter history by patient, email, or visit date.
- Optional notifications via Pushover.
- Optional outbound email delivery via SendGrid.

## Repository

The complete application is available at:
https://github.com/iJoshy/saas

See the README.md in the repository for detailed information about implementation, setup, and usage.
