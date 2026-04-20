Digital Twin on AWS
I built a personal digital twin (my own facts, LinkedIn/summary notes, and style prompts) as a small serverless stack on AWS: a FastAPI backend wrapped with Mangum for AWS Lambda, exposed through API Gateway, with session-based chat memory stored either locally (dev) or in S3 when enabled. The LLM calls go through OpenRouter (e.g. gpt-4o-mini) using a system prompt assembled from my context / resources.

The Next.js frontend is a simple chat UI that talks to the deployed API. I package the Lambda artifact with a Docker-based deploy.py script (Lambda Python 3.12–compatible dependencies and a zip for upload), which matches a manual or console-style deploy path for validating the stack end-to-end.

(Optional—only if accurate for you: I codified infrastructure with Terraform / wired GitHub Actions for CI/CD…)

GitHub
https://github.com/haastrupea/twins-aws-deploy

Live URL
https://d12ojqcn1s89o3.cloudfront.net/

