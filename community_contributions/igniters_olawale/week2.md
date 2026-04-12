# Digital Twin on AWS

I built a personal digital twin (my own data and prompts) as a small serverless app on AWS (API, compute, storage, and CDN style delivery as in the course). I deployed it manually first to validate the stack end-to-end, then codified the infrastructure with Terraform (including workspaces/environments where applicable).

Finally I wired GitHub Actions for CI/CD push-based deploys, secrets/OIDC style AWS auth, and remote state so infrastructure and releases follow a repeatable, team-style workflow instead of one-off console steps.

## GitHub

[github.com/iamwales/digital-twin](https://github.com/iamwales/digital-twin)

## Live URL

[Digital Twin](https://dy0w0qymcv26e.cloudfront.net/)
