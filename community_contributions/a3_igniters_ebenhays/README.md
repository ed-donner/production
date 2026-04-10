# Digital Twin — Eben's Personal Assistant

An AI-powered digital twin for a personal website. Visitors can chat with a conversational assistant that responds as you, powered by Amazon Bedrock and grounded in your resume, notes, and personal context.

## Project Repository
https://github.com/ebenhays/digital-twin

## Deployment URL
https://dzuy82f0ics2k.cloudfront.net/

## Overview

The project consists of three parts:

- **Backend** — A FastAPI application that handles chat sessions, builds a rich system prompt from personal documents, and calls the Amazon Bedrock Converse API to generate responses.
- **Frontend** — A Next.js static site with a chat UI that sends messages to the backend API.
- **Infrastructure** — Terraform configuration that provisions the full AWS stack: Lambda, API Gateway, S3 and CloudFront.
