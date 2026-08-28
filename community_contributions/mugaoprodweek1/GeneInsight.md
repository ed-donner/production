## 🧬 GeneInsight Studio

I built a biotech-focused AI application that transforms raw genomic and experimental notes into structured biological insights, hypotheses, and stakeholder-ready summaries.

The goal is to reduce the cognitive load in interpreting complex bioinformatics outputs while improving clarity, speed, and communication across research and clinical teams.

**Live App**
👉 https://gene-insight-studio-4xh4.vercel.app/

<br />

![Next.js](https://img.shields.io/badge/Next.js-16-black?logo=nextdotjs)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi)
![TypeScript](https://img.shields.io/badge/TypeScript-Frontend-3178C6?logo=typescript)
![Python](https://img.shields.io/badge/Python-API-3776AB?logo=python)
![OpenAI](https://img.shields.io/badge/AI-OpenAI-412991?logo=openai)
![Docker](https://img.shields.io/badge/Deployment-Docker-2496ED?logo=docker)

---

## 🧬 Core Features

* AI-powered interpretation of genomic and experimental data using OpenAI.
* Structured output with three sections:

  * **Research Summary** — clear biological interpretation of findings.
  * **Hypotheses & Next Experiments** — actionable scientific next steps.
  * **Regulatory / Stakeholder Summary** — simplified explanation for non-technical audiences.
* Real-time streaming responses (Server-Sent Events) for immediate feedback.
* Experiment input system:

  * Sample type (RNA, DNA, tissue, etc.)
  * Free-form experimental notes
* Modular frontend architecture for scalability and clean UX.
* Backend prompt engineering tailored for genomics and molecular biology use cases.

---

## Example Use Cases

* RNA-seq differential gene expression analysis
* Variant interpretation from DNA sequencing
* Infectious disease genomics (antimicrobial resistance)
* CRISPR experiment analysis
* Pharmacogenomics and drug response insights

---

## Motivation

Biological data is often:

* fragmented
* difficult to interpret
* hard to communicate across teams

GeneInsight Studio explores how AI can bridge the gap between:

**Raw experimental data → Structured insight → Actionable decisions**

This is particularly relevant for:

* Biotech startups in Europe working on precision medicine
* Research environments handling large-scale omics data
* Resource-constrained healthcare systems where expertise is limited

---

## 🏗 Architecture Overview

**Frontend (Next.js / React / TypeScript)**

* User interface
* Experiment input
* Streaming output rendering

**Backend (FastAPI / Python)**

* Prompt construction
* OpenAI API integration
* SSE streaming responses

**AI Layer**

* Domain-specific prompt engineering for genomics reasoning

---

## ⚙️ Key Technical Highlights

* **Server-Sent Events (SSE)** for real-time AI output streaming
* **Domain-aware prompt design** for biological interpretation
* **Separation of concerns** between UI and AI processing layers
* **Environment-based configuration** using `.env` and `python-dotenv`
* **Container-ready architecture** using Docker

---

## Deployment

* Frontend deployed on **Vercel**
* Backend containerized with **Docker** and deployable to AWS App Runner

---

## Repository

The complete application is available at:
https://github.com/Mugao-joy/geneInsight-Studio

For full setup instructions, architecture details, and local development steps, see the main `README.md` in the repository.

---
