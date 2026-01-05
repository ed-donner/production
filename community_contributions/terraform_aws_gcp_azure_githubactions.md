# Salutron: Multi-Cloud Infrastructure Automation

**Project Link:** [https://salutron.lisekarimi.com](https://salutron.lisekarimi.com)
**GitHub Repository:** [https://github.com/lisekarimi/salutron](https://github.com/lisekarimi/salutron)

## 🎯 Project Overview

A production-ready DevOps project demonstrating enterprise-level Infrastructure as Code practices across **AWS, GCP, and Azure**. Built to master multi-cloud deployment strategies, automated CI/CD pipelines, and modern security practices.

**Key Achievement:** Single-command infrastructure deployment across three major cloud providers with zero stored credentials.

## 🛠️ Technical Stack

- **Infrastructure as Code:** Terraform with workspace isolation (dev/test/prod)
- **Containerization:** Docker with optimized multi-stage builds
- **Cloud Platforms:** AWS App Runner, GCP Cloud Run, Azure Container Apps
- **CI/CD:** GitHub Actions with OIDC/Workload Identity Federation
- **State Management:** Remote backends (S3, GCS, Azure Blob Storage)
- **Automation:** Bash scripting + Makefiles for deployment orchestration

## 🚀 What Makes This Special

### Multi-Cloud Parity
Identical deployment workflows across AWS, GCP, and Azure - demonstrating cloud-agnostic infrastructure design patterns.

### Zero-Credential Security
Implemented OIDC and Workload Identity Federation for all three clouds, eliminating long-lived credentials and following enterprise security best practices.

### One-Command Deployment
```bash
make aws-deploy-prod  # Deploy to AWS production
make gcp-deploy-dev   # Deploy to GCP development
make azure-deploy-test # Deploy to Azure testing
```

## 💡 The Journey

### Challenges Faced

1. **Multi-Cloud State Management**
   - **Problem:** Each cloud has different backend requirements (S3+DynamoDB vs GCS vs Blob Storage)
   - **Solution:** Standardized backend configuration patterns with environment-specific state files

2. **OIDC Configuration Complexity**
   - **Problem:** Different federated identity implementations across clouds (AWS OIDC vs GCP Workload Identity vs Azure Workload Identity Federation)
   - **Solution:** Created environment-specific credentials (dev/test/prod) for proper GitHub Actions integration

3. **Azure Free Tier Limitations**
   - **Problem:** Only 1 Container App Environment per region in free tier
   - **Solution:** Documented shared environment pattern and region-based deployment strategies

4. **GitHub Actions Authentication**
   - **Problem:** Initial workflows failed due to generic credential matching (wildcard vs environment-specific)
   - **Solution:** Implemented granular federated credentials per environment for better security

### Key Learnings

**Infrastructure as Code:**
- Terraform workspace management for environment isolation
- Remote state backends prevent state conflicts in team/CI scenarios
- `-target` flag useful for incremental resource creation (ECR → Build → Deploy pattern)

**Container Registry Authentication:**
- Each cloud has unique login patterns (aws ecr, gcloud auth, az acr)
- Registry URLs follow predictable naming conventions (useful for automation)

**CI/CD Best Practices:**
- Environment protection rules in GitHub Actions prevent accidental prod deployments
- OIDC tokens expire (~1 hour), providing automatic credential rotation
- Separate workflows for deploy/destroy add safety layer

**Multi-Cloud Strategy:**
- Consistent naming conventions across clouds simplify management
- Cloud-specific nuances (scaling to 0, environment limits) require documentation
- Hybrid local/CI approach balances speed and safety

### Unexpected Discoveries

1. **GCP Cloud Run can scale to 0** (cost optimization) but **Azure Container Apps with ingress cannot** - important for pricing strategy

2. **Terraform state conflicts** are more common in CI/CD than expected - proper backend initialization critical

3. **Docker build caching** in GitHub Actions significantly speeds up deployments (30s vs 3min)

4. **Azure resource provider registration** required before first deployment - similar to GCP API enablement but less obvious

## 📊 Project Metrics

- **3 Cloud Providers:** AWS, GCP, Azure
- **3 Environments:** dev, test, prod (per cloud)
- **6 GitHub Actions Workflows:** Deploy + Destroy for each cloud
- **Zero Long-Lived Credentials:** 100% OIDC/Workload Identity
- **~50 Terraform Resources:** Across all clouds
- **Single Command Deployment:** Via Makefiles

## 🎓 Skills Demonstrated

- Multi-cloud infrastructure design
- Terraform workspace and state management
- Docker containerization and optimization
- GitHub Actions CI/CD pipelines
- OIDC/Workload Identity Federation
- Bash scripting and automation
- GitOps workflow implementation
- Secret management best practices
---

**Built with ❤️ while mastering DevOps**

If you found this helpful, ⭐ star the repo!
