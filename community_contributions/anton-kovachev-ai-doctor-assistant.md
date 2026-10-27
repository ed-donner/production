# AI Doctor Assistant

## Links

- Repository: https://github.com/anton-kovachev/ai-doctor-assistant
- Live project: https://ai-doctor-assistant-dev-frontend-456097556049.s3.eu-north-1.amazonaws.com/index.html

## Overview

AI Doctor Assistant helps clinicians turn consultation notes into professional summaries, clear follow-up actions, and patient-friendly email drafts. It is designed to support clinical workflows, not replace clinical judgment.

## Business case

Preparing consistent documentation and follow-up communications takes time after a consultation. The application uses an AI assistant to organize clinician-provided notes and prepare useful next steps, while requiring approval for sensitive actions such as sending a treatment-plan email.

## Features

- Generates consultation summaries and action items from visit notes.
- Streams the response and tool progress to the web interface.
- Supports a clinician review and approval step before sending a treatment-plan email.
- Provides sign-in and protected application features.

## Technology and architecture

- **Frontend:** Next.js Pages Router, React, and TypeScript. The app is statically exported and hosted from an Amazon S3 website bucket; Clerk provides authentication.
- **API:** A Python FastAPI service runs as a container on AWS Lambda behind API Gateway.
- **Agent and model:** The backend uses the OpenAI Agents SDK with an OpenAI-compatible AWS Bedrock endpoint, plus input guardrails for consultation-note length.
- **Streaming:** Server-Sent Events carry generated text, progress, errors, and approval interruptions from the API to the frontend.
- **MCP tools:** The agent connects to a healthcare MCP server for healthcare information and can use a separate email tool for treatment-plan messages.
- **Session state:** Redis-backed agent sessions retain conversation context. Redis also stores interrupted run state while an action awaits clinician approval.
- **Infrastructure and deployment:** Terraform provisions the AWS resources, including API Gateway, Lambda, ECR, ElastiCache Redis, and the S3 frontend. A deployment script builds the frontend with the deployed API URL and uploads its static assets; GitHub Actions can run the deployment workflow.

## Project notes

The frontend and backend are deployed independently. The frontend's backend URL and Clerk publishable key are supplied at build time, while Terraform and the deployment script connect the static site to the API created for the selected environment. This project is a useful example of combining a static web frontend with a streaming, tool-using backend agent and managed cloud infrastructure.
