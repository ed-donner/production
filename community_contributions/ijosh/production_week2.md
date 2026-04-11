# Week 2 – AI Digital Twin

I modificed the AI Digital Twin application to be a production-ready, full-stack  that represents **Joshua Balogun** in real-time conversations.
This project combines a modern Next.js frontend with a FastAPI backend powered by AWS Bedrock and deploys to AWS using Lambda + API Gateway + S3 + CloudFront + Terraform.

Production URL: https://d36qx0izkd71ph.cloudfront.net/

<br />

![Next.js](https://img.shields.io/badge/Next.js-16-black?logo=nextdotjs)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6?logo=typescript&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-4-06B6D4?logo=tailwindcss&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![AWS Bedrock](https://img.shields.io/badge/AWS_Bedrock-LLM-FF9900?logo=amazonaws&logoColor=white)
![AWS Lambda](https://img.shields.io/badge/AWS_Lambda-Serverless-FF9900?logo=awslambda&logoColor=white)
![API Gateway](https://img.shields.io/badge/API_Gateway-HTTP_API-FF4F8B?logo=amazonapigateway&logoColor=white)
![Amazon S3](https://img.shields.io/badge/Amazon_S3-Storage-569A31?logo=amazons3&logoColor=white)
![CloudFront](https://img.shields.io/badge/CloudFront-CDN-8C4FFF?logo=amazoncloudfront&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)


## Core Features

- Conversational AI Digital Twin experience
- Session-based conversation memory
- Memory persistence to local files or S3
- Bedrock tool-calling loop with guarded execution
- Structured context injection from profile files
- Hidden reasoning sanitization in backend and frontend
- Optional lead capture + unknown-question logging tools
- Optional email dispatch via SendGrid
- Optional push notifications via Pushover
- Static frontend export optimized for S3 + CloudFront
- Terraform-based environment-aware infrastructure deployment
- Optional notifications via Pushover.
- Optional outbound email delivery via SendGrid.

## Repository

The complete application is available at:
https://github.com/iJoshy/digital-twin

See the README.md in the repository for detailed information about implementation, setup, and usage.
