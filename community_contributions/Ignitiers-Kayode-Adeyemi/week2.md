Digital Twin on AWS

A serverless AI chat application powered by AWS Bedrock, featuring:

- Backend: FastAPI server using Amazon Nova model via AWS Bedrock
- Frontend: Next.js application
- Infrastructure: Terraform-managed AWS resources
- Memory: Conversation history storage (local or S3)

Finally I wired GitHub Actions for CI/CD push-based deploys, secrets/OIDC style AWS auth, and remote state so infrastructure and releases follow a repeatable, team-style workflow instead of one-off console steps.

GitHub
https://github.com/karosi12/twin

Live URL
[Digital Twin](https://d22mcqw6rgl43y.cloudfront.net/)