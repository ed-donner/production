# Deploying a container to AWS ECS Express Mode

## Problem
The Week 1 Day 5 instructions say to use AWS App Runner to deploy the container. Unfortunately, AWS has deprecated App Runner and suggests
using ECS Express Mode as a replacement. ECS Express Mode is not as straightforward as App Runner and requires some additional infrastructure.

## Solution
1. As the AWS root user (*not* aiengineer), add two additional policies to the BroadAIEngineerAccess user group.
- AmazonECS_FullAccess
- AmazonVPCFullAccess

2. Create a default VPC using the AWS CLI. (I did this from the terminal in cursor.)
- `aws ec2 create-default-vpc`

3. As the aiengineer user, create an ECS Express Mode deployment. Keep defaults except for:
- Image URI (Use the Browse ECR images button to select image.)
- Container port: 8000
- Container health check path: /health
- Add CLERK_SECRET_KEY, CLERK_JWKS_URL, & OPENAI_API_KEY and their values as environment variables.
- Set CPU: 0.25 vCPU
- Set Memory: 0.5 GB
- Set Minimum number of tasks: 1
- Set Maximum number of tasks: 1

Many of these settings are under the "Additional configurations - optional" twistie.

The deployment takes 7-10 minutes to complete. It creates several objects including load balancers and elastic IPs, so you may want to use
something like [AWS Resource Explorer](https://docs.aws.amazon.com/resource-explorer/latest/userguide/welcome.html) to find and delete them. Deleting the deployment does *not* remove all resources.

I hope this helps!

[Katherine](https://github.com/ktstevenson)