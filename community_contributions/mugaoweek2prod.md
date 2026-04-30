# Digital Twin — AI Personal Assistant

An AI-powered digital twin that represents me online. Visitors can interact with a conversational assistant that responds as me, using contextual knowledge and conversational memory. The system is built with FastAPI and deployed on AWS.

---

## 🔗 Project Repository
https://github.com/Mugao-joy/digital-twin

---

## 🌐 Deployment URL

Frontend (S3 Static Website):
http://twin-frontend-yourname.s3-website-us-east-1.amazonaws.com/
backend : https://ymw4zypayc.us-east-1.awsapprunner.com/

> ⚠️ Note: This is an S3 static website endpoint. In a production setup, this would ideally be served via CloudFront for HTTPS and improved performance.

---

## Overview

The project consists of three main parts:

### Backend (FastAPI + AI)
- Handles chat sessions and memory
- Builds a system prompt to simulate a digital twin
- Integrates with an AI model for responses
- Uses **Mangum** to run FastAPI on AWS Lambda (initial approach)

### Frontend
- Simple chat interface
- Sends user messages to backend API
- Displays responses in real-time
- Hosted on AWS S3

### Infrastructure
- **AWS Lambda** → backend execution (initial approach)
- **API Gateway** → HTTP routing
- **S3** → frontend hosting
- **App Runner** → final backend deployment

---

## System Flow
User → Frontend (S3) → API Gateway / App Runner → Backend → AI → Response

---

## Key Features

- Conversational AI assistant
- Session-based memory
- Serverless / containerized backend
- Lightweight frontend
- Cloud-native deployment

---

## 🧩 Challenges Encountered & How They Were Solved

This project involved several real-world engineering challenges, particularly around environment setup, dependency management, and cloud deployment.

---

### 1. Docker Desktop Stuck on “Starting”

**Problem:**
- Docker Desktop failed to start on Windows
- Root cause was virtualization / WSL misconfiguration

**Solution:**
- Switched to **Ubuntu (dual boot)** for a native Linux environment
- Continued development without relying on Docker Desktop

**Outcome:** Stable and predictable development environment

---

### 2. AWS Lambda Import Error (Critical)

**Problem:**
-No module named 'pydantic_core._pydantic_core'

**Root Cause:**
- Dependencies were built on Ubuntu
- AWS Lambda runs on Amazon Linux
- Compiled libraries (like `pydantic_core`) were incompatible

**Solution:**
- Rebuilt dependencies targeting a Linux-compatible environment
- Adjusted packaging process
- Ensured correct deployment structure

 **Key Insight:**
> Compiled dependencies must be built in an environment compatible with the target runtime.

---

### 3. Lambda Packaging & Structure Issues

**Problem:**
- Incorrect zip structure
- Lambda could not locate modules or handler

**Solution:**
- Ensured all dependencies and files were at the root level of the zip
- Verified handler configuration (`lambda_handler.handler`)

 **Outcome:** Successful Lambda initialization

---

### 4. CloudFront Integration Challenges

**Problem:**
- Attempted to use **CloudFront** to serve the application
- Encountered issues integrating dynamic API responses with static hosting
- Complexity in routing requests between S3 (frontend) and API Gateway (backend)
- Additional configuration overhead (origins, behaviors, caching rules)

**Why it failed (practically):**
- CloudFront is optimized for **static content delivery**
- This project required **dynamic backend communication (chat API)**
- Misalignment between use-case and tool added unnecessary complexity

---

### 5. Architectural Pivot → App Runner

**Decision:**
Instead of forcing a CloudFront-based architecture, the backend was moved to **AWS App Runner**

**Why App Runner:**
- Designed for running **containerized web services**
- Handles HTTP traffic natively
- Eliminates API Gateway + Lambda complexity
- Simplifies deployment and debugging

**Solution:**
- Containerized the FastAPI application
- Deployed using App Runner
- Configured proper start command (`uvicorn`)

**Outcome:**
- Faster deployment
- Fewer moving parts
- Easier debugging and iteration

---

### 6. Runtime Startup Failures (App Runner)

**Problem:**
- Application built successfully but failed during deployment
- No server was listening on expected port

**Solution:**
- Explicitly defined start command:
-uvicorn server:app --host 0.0.0.0 --port 8080
- Ensured correct working directory and module path

 **Outcome:** Application successfully started and served traffic

---

## Deployment Notes

- Backend must expose and listen on port `8080`
- Start command must explicitly run the ASGI server (uvicorn)
- Environment consistency is critical for dependency compatibility

---

## 🛠️ Tech Stack

- Python (FastAPI)
- OpenAI API
- AWS Lambda
- API Gateway
- AWS App Runner
- Amazon S3
- Mangum
- uv (Python package manager)

---

## Future Improvements

- Add CloudFront CDN (properly configured)
- Improve UI/UX
- Add authentication
- Introduce vector database for memory
- Fully containerize and standardize deployment with Docker

---

## Key Lessons Learned

- Environment consistency is critical
- Serverless deployments require strict packaging rules
- Compiled dependencies can break across systems
- Choosing the right AWS service matters more than forcing one
- Simpler architectures are often more reliable

---

## 👩🏽‍💻 Author

**Mwende Mugao**

---

## ⭐ Final Note

This project demonstrates:
- End-to-end AI system development
- Cloud deployment and architecture decisions
- Real-world debugging and problem-solving