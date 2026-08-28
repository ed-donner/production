# AI Digital Twin

This project is a web application that serves as an **AI-powered digital twin**, providing users with a course companion to assist with AI deployment and related queries. The application features a frontend built with React and Tailwind CSS, and a backend API for handling chat interactions.

---

## Links

- Repo: https://github.com/adisco4420/ai-digital-twin
- Live app: https://d1o5h1kp8zvr80.cloudfront.net


---

## Features

- **Backend**: Python-based backend with FastAPI, AWS Lambda, and other utilities.
- **Frontend**: Next.js application for a modern, responsive user interface.
- **Infrastructure**: Managed with Terraform for AWS resources.
- **Environment Management**: `.env` files for configuration.
- **CI/CD**: GitHub Actions for automated deployment and destruction workflows.

---

## Project Structure

```plaintext
├── backend/                # Backend services and Lambda functions
│   ├── lambda-package/     # Lambda deployment package
│   ├── server.py           # FastAPI server entry point
│   ├── deploy.py           # Deployment script
│   └── requirements.txt    # Python dependencies
├── frontend/               # Frontend application (Next.js)
│   ├── pages/              # Next.js pages
│   ├── components/         # React components
│   └── package.json        # Node.js dependencies
├── terraform/              # Terraform configuration for AWS infrastructure
├── scripts/                # Utility scripts for deployment and destruction
├── .github/workflows/      # GitHub Actions workflows
└── README.md               # Project documentation
```