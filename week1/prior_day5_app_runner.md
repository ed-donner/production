# Day 5: Deploy Your SaaS to AWS App Runner

## From Vercel to AWS: Professional Cloud Deployment

Today, you'll take your Healthcare Consultation Assistant from Vercel and deploy it to AWS using Docker containers and App Runner. This is how professional teams deploy production applications at scale.

## What You'll Learn

- **Docker containerization** for consistent deployments
- **AWS fundamentals** and account setup
- **AWS App Runner** for serverless container hosting
- **Production deployment** patterns used by engineering teams
- **Cost monitoring** to keep your AWS bill under control

## Important: Budget Protection First! 💰

AWS charges for resources you use. Let's set up cost alerts BEFORE deploying anything:

**Expected costs**: With our configuration, expect ~$5-10/month. AWS offers free tier credits for new accounts that should cover your first 3 months.

We'll set up budget alerts at $1, $5, and $10 to track spending. This is a crucial professional practice!

## Understanding AWS Services We'll Use

Before we start, let's understand the AWS services:

### AWS App Runner
**App Runner** is AWS's simplest way to deploy containerized web applications. Think of it as "Vercel for Docker containers" - it automatically handles HTTPS certificates, load balancing, and scaling. You just provide a container, and App Runner does the rest.

### Amazon ECR (Elastic Container Registry)
**ECR** is like GitHub but for Docker images. It's where we'll store our containerized application before deploying it to App Runner.

### AWS IAM (Identity and Access Management)
**IAM** controls who can access what in your AWS account. We'll create a special user account with limited permissions for safety - never use your root account for daily work!

### CloudWatch
**CloudWatch** is AWS's monitoring service. It collects logs from your application and helps you debug issues - like having the browser console for your server.

## Part 1: Create Your AWS Account

## WAIT - HEADS UP - DISCOVERY SINCE GOING TO PRESS!

There's an option for first time users of AWS to select the "free tier" of AWS. Don't choose this! It only has limited access to AWS services, including no access to App Runner (the service we use today). This doesn't mean that you need to pay a subscription or pay for support; just that you need to enter payment details and not be in a sandbox environment. Student Jake C. confirmed that $120 free credits still applied even after signing up for a full account.

This was discovered brilliantly by student Andy C. who shared:

> **Cryptic App Runner service error message: "The AWS Access Key Id needs a subscription for the service"**  
> 
> I struggled with this message for 24 hours and wanted to let everyone know the root cause. I get it when (1) I try to set up a new "Auto scaling" config (e.g., "Basic" that Ed suggests) and (2) when I try to save and create my app runner service.
>
> Here was the problem: I was signed up for the free tier of AWS. Apparently the free tier does not allow for you to use App Runner. Argh. Once I upgraded to paid tier, I was golden.
> 
> I tried so many other things to try to fix this issue and spent hours trying to understand IAM, thinking that was the problem. I hope this message saves someone else a huge amount of time!

This is an example of the kind of infrastructure horrors you may face - and with enormous appreciation to Andy for digging in, finding the root cause and sharing with us all.

With that in mind:

### Step 1: Sign Up for AWS

1. Visit [aws.amazon.com](https://aws.amazon.com)
2. Click **Create an AWS Account**
3. Enter your email and choose a password
4. Select **Personal** account type (for learning)
5. Enter payment information (required, but we'll set up cost alerts)
6. Verify your phone number via SMS
7. Select **Basic Support - Free**

You now have an AWS root account. This is like having admin access - powerful but dangerous!

### Step 2: Secure Your Root Account

1. Sign in to AWS Console
2. Click your account name (top right) → **Security credentials**
3. Enable **Multi-Factor Authentication (MFA)**:
   - Click **Assign MFA device**
   - Name: `root-mfa`
   - Select **Authenticator app**
   - Scan QR code with Google Authenticator or Authy
   - Enter two consecutive codes
   - Click **Add MFA**

### Step 3: Set Up Budget Alerts (Critical!)

1. In AWS Console, search for **Billing** and click **Billing and Cost Management**
2. In the left menu, click **Budgets**
3. Click **Create budget**
4. Select **Use a template (simplified)**
5. Choose **Monthly cost budget**
6. Set up three budgets:

**Budget 1 - Early Warning ($1)**:
- Budget name: `early-warning`
- Enter budgeted amount: `1` USD
- Email recipients: Enter your email address
- Click **Create budget**

**Budget 2 - Caution ($5)**:
- Repeat steps: Create budget → Use a template → Monthly cost budget
- Budget name: `caution-budget`
- Enter budgeted amount: `5` USD
- Email recipients: Enter your email address
- Click **Create budget**

**Budget 3 - Stop Alert ($10)**:
- Repeat steps: Create budget → Use a template → Monthly cost budget
- Budget name: `stop-budget`
- Enter budgeted amount: `10` USD
- Email recipients: Enter your email address
- Click **Create budget**

AWS will automatically notify you when:
- Your actual spend reaches 85% of budget
- Your actual spend reaches 100% of budget
- Your forecasted spend is expected to reach 100%

If you hit $10, stop and review what's running!

### Step 4: Create an IAM User for Daily Work

Never use your root account for daily work. Let's create a limited user:

1. Search for **IAM** in the AWS Console
2. Click **Users** → **Create user**
3. Username: `aiengineer`
4. Check ✅ **Provide user access to the AWS Management Console**
5. Select **I want to create an IAM user**
6. Choose **Custom password** and set a strong password
7. Uncheck ⬜ **Users must create a new password at next sign-in**
8. Click **Next**

### Step 5: Create a User Group with Permissions

We'll create a reusable permission group first, then add our user to it:

1. On the permissions page, select **Add user to group**
2. Click **Create group**
3. Group name: `BroadAIEngineerAccess`
4. In the permissions policies search, find and check these policies:
   - `AWSAppRunnerFullAccess` - to deploy applications
   - `AmazonEC2ContainerRegistryFullAccess` - to store Docker images
   - `CloudWatchLogsFullAccess` - to view logs
   - `IAMUserChangePassword` - to manage own credentials
   - IMPORTANT: also `IAMFullAccess` - I don't think I mention this in the video, but it must be included or you will get errors later! Thank you Anthony W and Jake C for pointing this out.
5. Click **Create user group**
6. Back on the permissions page, select the `BroadAIEngineerAccess` group (it should be checked)
7. Click **Next** → **Create user**
8. **Important**: Click **Download .csv file** and save it securely!

It's worth keeping in mind that you might get permissions errors thoughout the course, when AWS complains that your user doesn't have permission to do something. The solution is usually to come back to this screen (as the root user) and attach another policy! This is a very common chore working with AWS...

### Step 6: Sign In as IAM User

1. Sign out from root account
2. Go to your AWS sign-in URL (in the CSV file, looks like: `https://123456789012.signin.aws.amazon.com/console`)
3. Sign in with:
   - Username: `aiengineer`
   - Password: (the one you created)

✅ **Checkpoint**: You should see "aiengineer @ Account-ID" in the top right corner

## Part 2: Install Docker Desktop

Docker lets us package our application into a container - like a shipping container for software!

### Step 1: Install Docker Desktop

1. Visit [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
2. Download for your system:
   - **Mac**: Download for Mac (Apple Silicon or Intel)
   - **Windows**: Download for Windows (requires Windows 10/11)
3. Run the installer
4. **Windows users**: Docker Desktop will install WSL2 if needed - accept all prompts
5. Start Docker Desktop
6. You may need to restart your computer

### Step 2: Verify Docker Works

Open Terminal (Mac) or PowerShell (Windows):

```bash
docker --version
```

You should see: `Docker version 26.x.x` or similar

Test Docker:
```bash
docker run hello-world
```

You should see a message starting with "Hello from Docker!" confirming Docker is working correctly.

✅ **Checkpoint**: Docker Desktop icon should be running (whale icon in system tray/menu bar)

## Part 3: Prepare Your Application

We need to modify our Day 4 application for AWS deployment. The key change: we'll export Next.js as static files and serve everything from a single container.

### Step 1: Update Project Structure

Your project should look like this:
```
saas/
├── pages/                  # Next.js Pages Router
├── styles/                 # CSS styles
├── api/                    # FastAPI backend
├── public/                 # Static assets
├── node_modules/          
├── .env.local             # Your secrets (never commit!)
├── .gitignore
├── package.json
├── requirements.txt
├── next.config.ts
└── tsconfig.json
```

### Step 2: Convert to Static Export

**Important Architecture Change**: On Vercel, our Next.js app could make server-side requests. For AWS simplicity, we'll export Next.js as static HTML/JS files and serve them from our Python backend. This means everything runs in one container!

**Note about Middleware**: 
With Pages Router, we don't use middleware files. Authentication is handled entirely by Clerk's client-side components (`<Protect>`, `<SignedIn>`, etc.) which work perfectly with static exports.

Update `next.config.ts`:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',  // This exports static HTML/JS files
  images: {
    unoptimized: true  // Required for static export
  }
};

export default nextConfig;
```

### Step 3: Update Frontend API Calls

Since we're serving everything from the same container, we need to update how the frontend calls the backend.

Update `pages/product.tsx` - find the `fetchEventSource` call and change it:

```typescript
// Old (Vercel):
await fetchEventSource('/api', {

// New (AWS):
await fetchEventSource('/api/consultation', {
```

This works because both frontend and backend will be served from the same domain!

### Step 4: Update Backend Server

Create a new file `api/server.py` (updating our FastAPI server for AWS):

```python
import os
from pathlib import Path
from fastapi import FastAPI, Depends
from fastapi.responses import StreamingResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from fastapi_clerk_auth import ClerkConfig, ClerkHTTPBearer, HTTPAuthorizationCredentials
from openai import OpenAI

app = FastAPI()

# Add CORS middleware (allows frontend to call backend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Clerk authentication setup
clerk_config = ClerkConfig(jwks_url=os.getenv("CLERK_JWKS_URL"))
clerk_guard = ClerkHTTPBearer(clerk_config)

class Visit(BaseModel):
    patient_name: str
    date_of_visit: str
    notes: str

system_prompt = """
You are provided with notes written by a doctor from a patient's visit.
Your job is to summarize the visit for the doctor and provide an email.
Reply with exactly three sections with the headings:
### Summary of visit for the doctor's records
### Next steps for the doctor
### Draft of email to patient in patient-friendly language
"""

def user_prompt_for(visit: Visit) -> str:
    return f"""Create the summary, next steps and draft email for:
Patient Name: {visit.patient_name}
Date of Visit: {visit.date_of_visit}
Notes:
{visit.notes}"""

@app.post("/api/consultation")
def consultation_summary(
    visit: Visit,
    creds: HTTPAuthorizationCredentials = Depends(clerk_guard),
):
    user_id = creds.decoded["sub"]
    client = OpenAI()
    
    user_prompt = user_prompt_for(visit)
    prompt = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]
    
    stream = client.chat.completions.create(
        model="gpt-5-nano",
        messages=prompt,
        stream=True,
    )
    
    def event_stream():
        for chunk in stream:
            text = chunk.choices[0].delta.content
            if text:
                lines = text.split("\n")
                for line in lines[:-1]:
                    yield f"data: {line}\n\n"
                    yield "data:  \n"
                yield f"data: {lines[-1]}\n\n"
    
    return StreamingResponse(event_stream(), media_type="text/event-stream")

@app.get("/health")
def health_check():
    """Health check endpoint for AWS App Runner"""
    return {"status": "healthy"}

# Serve static files (our Next.js export) - MUST BE LAST!
static_path = Path("static")
if static_path.exists():
    # Serve index.html for the root path
    @app.get("/")
    async def serve_root():
        return FileResponse(static_path / "index.html")
    
    # Mount static files for all other routes
    app.mount("/", StaticFiles(directory="static", html=True), name="static")
```

### Step 5: Create Environment File for AWS

Create `.env` file (copy from `.env.local` but add AWS info):

```bash
# Copy your values from .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
CLERK_JWKS_URL=https://...
OPENAI_API_KEY=sk-...

# Add AWS configuration (use your chosen region from earlier) - us-east-1 or eu-west-1 etc
DEFAULT_AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
```

**To find your AWS Account ID**:
1. In AWS Console, click your username (top right)
2. Copy the 12-digit Account ID

**Important**: Add `.env` to your `.gitignore` file if not already there!

## Part 4: Create Docker Configuration

Docker lets us package everything into a single container that runs anywhere.

### Step 1: Create Dockerfile

Create `Dockerfile` in your project root:

```dockerfile
# Stage 1: Build the Next.js static files
FROM node:22-alpine AS frontend-builder

WORKDIR /app

# Copy package files first (for better caching)
COPY package*.json ./
RUN npm ci

# Copy all frontend files
COPY . .

# Build argument for Clerk public key
ARG NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY

# Note: Docker may warn about "secrets in ARG/ENV" - this is OK!
# The NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY is meant to be public (it starts with pk_)
# It's safe to include in the build as it's designed for client-side use

# Build the Next.js app (creates 'out' directory with static files)
RUN npm run build

# Stage 2: Create the final Python container
FROM python:3.12-slim

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the FastAPI server
COPY api/server.py .

# Copy the Next.js static export from builder stage
COPY --from=frontend-builder /app/out ./static

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Expose port 8000 (FastAPI will serve everything)
EXPOSE 8000

# Start the FastAPI server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Step 2: Create .dockerignore

Create `.dockerignore` to exclude unnecessary files:

```
node_modules
.next
.env
.env.local
.git
.gitignore
README.md
.DS_Store
*.log
.vercel
dist
build
```

## Part 5: Build and Test Locally

Let's test our containerized app before deploying to AWS.

### Step 1: Load Environment Variables

**Mac/Linux** (Terminal):
```bash
export $(cat .env | grep -v '^#' | xargs)
```

**Windows** (PowerShell):
```powershell
Get-Content .env | ForEach-Object {
    if ($_ -match '^(.+?)=(.+)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}
```

### Step 2: Build the Docker Image

Build your container:

**Mac/Linux**:
```bash
docker build \
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" \
  -t consultation-app .
```

**Windows PowerShell**:
```powershell
docker build `
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$env:NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" `
  -t consultation-app .
```

This will take 2-3 minutes the first time.

### Step 3: Run Locally

**Mac/Linux**:
```bash
docker run -p 8000:8000 \
  -e CLERK_SECRET_KEY="$CLERK_SECRET_KEY" \
  -e CLERK_JWKS_URL="$CLERK_JWKS_URL" \
  -e OPENAI_API_KEY="$OPENAI_API_KEY" \
  consultation-app
```

**Windows PowerShell**:
```powershell
docker run -p 8000:8000 `
  -e CLERK_SECRET_KEY="$env:CLERK_SECRET_KEY" `
  -e CLERK_JWKS_URL="$env:CLERK_JWKS_URL" `
  -e OPENAI_API_KEY="$env:OPENAI_API_KEY" `
  consultation-app
```

### Step 4: Test Your Application

1. Open browser to `http://localhost:8000`
2. Sign in with your Clerk account
3. Test the consultation form
4. Verify everything works!

**To stop**: Press `Ctrl+C` in the terminal

✅ **Checkpoint**: Application works identically to Vercel version

## Part 6: Deploy to AWS

Now let's deploy our container to AWS App Runner!

### Step 1: Create ECR Repository

ECR (Elastic Container Registry) is where we'll store our Docker image.

1. In AWS Console, search for **ECR**
2. Click **Get started** or **Create repository**
3. **Important**: Make sure you're in the correct region (top right of AWS Console - should match your DEFAULT_AWS_REGION)
4. Settings:
   - Visibility settings: **Private**
   - Repository name: `consultation-app` (must match exactly!)
   - Leave all other settings as default
5. Click **Create repository**
6. **Verify**: You should see your new `consultation-app` repository in the list

### Step 2: Set Up AWS CLI

We need AWS CLI to push our image.

#### Create Access Keys

1. In AWS Console, go to **IAM**
2. Click **Users** → click on `aiengineer`
3. Click **Security credentials** tab
4. Under **Access keys**, click **Create access key**
5. Select **Command Line Interface (CLI)**
6. Check the confirmation box → **Next**
7. Description: `Docker push access`
8. Click **Create access key**
9. **Critical**: Download CSV or copy both:
   - Access key ID (like: `AKIAIOSFODNN7EXAMPLE`)
   - Secret access key (like: `wJalrXUtnFEMI/K7MDENG/bPxRfiCY`)
10. Click **Done**

#### Configure AWS CLI

Install AWS CLI if you haven't:
- **Mac**: `brew install awscli` or download from [aws.amazon.com/cli](https://aws.amazon.com/cli/)
- **Windows**: Download installer from [aws.amazon.com/cli](https://aws.amazon.com/cli/)

Configure it:
```bash
aws configure
```

Enter:
- AWS Access Key ID: (paste your key)
- AWS Secret Access Key: (paste your secret)
- Default region: Choose based on your location:
  - **US East Coast**: `us-east-1` (N. Virginia)
  - **US West Coast**: `us-west-2` (Oregon)
  - **Europe**: `eu-west-1` (Ireland)
  - **Asia**: `ap-southeast-1` (Singapore)
  - **Pick the closest region for best performance!**
- Default output format: `json`

**Important**: Remember your region choice - you'll use it throughout this course!

### Step 3: Push Image to ECR

1. In ECR console, click your `consultation-app` repository
2. Click **View push commands**
3. Since you already have your AWS info in `.env`, let's use it!

**First, make sure your environment variables are loaded** (from Part 5, Step 1).

**Understanding the authentication**: The first command gets a temporary password from AWS and pipes it to Docker. You won't be prompted for a password - it's all automatic!

**Mac/Linux**:
```bash
# 1. Authenticate Docker to ECR (using your .env values!)
aws ecr get-login-password --region $DEFAULT_AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$DEFAULT_AWS_REGION.amazonaws.com

# 2. Build for Linux/AMD64 (CRITICAL for Apple Silicon Macs!)
docker build \
  --platform linux/amd64 \
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" \
  -t consultation-app .

# 3. Tag your image (using your .env values!)
docker tag consultation-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$DEFAULT_AWS_REGION.amazonaws.com/consultation-app:latest

# 4. Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$DEFAULT_AWS_REGION.amazonaws.com/consultation-app:latest
```

**Windows PowerShell**:
```powershell
# 1. Authenticate Docker to ECR (using your .env values!)
aws ecr get-login-password --region $env:DEFAULT_AWS_REGION | docker login --username AWS --password-stdin "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:DEFAULT_AWS_REGION.amazonaws.com"

# 2. Build for Linux/AMD64
docker build `
  --platform linux/amd64 `
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$env:NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" `
  -t consultation-app .

# 3. Tag your image (using your .env values!)
docker tag consultation-app:latest "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:DEFAULT_AWS_REGION.amazonaws.com/consultation-app:latest"

# 4. Push to ECR
docker push "$env:AWS_ACCOUNT_ID.dkr.ecr.$env:DEFAULT_AWS_REGION.amazonaws.com/consultation-app:latest"
```

**Note for Apple Silicon (M1/M2/M3) Macs**: The `--platform linux/amd64` flag is ESSENTIAL. Without it, your container won't run on AWS!

The push will take 2-5 minutes depending on your internet speed.

✅ **Checkpoint**: In ECR console, you should see your image with tag `latest`

## Part 7: Create App Runner Service

### Step 1: Launch App Runner

1. In AWS Console, search for **App Runner**
2. Click **Create service**

### Step 2: Configure Source

1. **Source**:
   - Repository type: **Container registry**
   - Provider: **Amazon ECR**
2. Click **Browse** 
3. Select `consultation-app` → Select `latest` tag
4. **Deployment settings**:
   - Deployment trigger: **Manual** (to control costs)
   - ECR access role: **Create new service role**
5. Click **Next**

### Step 3: Configure Service

1. **Service name**: `consultation-app-service`

2. **Virtual CPU & memory**:
   - vCPU: `0.25 vCPU`
   - Memory: `0.5 GB`

3. **Environment variables** - Click **Add environment variable** for each:
   - `CLERK_SECRET_KEY` = (paste your value)
   - `CLERK_JWKS_URL` = (paste your value)  
   - `OPENAI_API_KEY` = (paste your value)

   Note: We don't need `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` here - it's baked into the static files!

4. **Port**: `8000` (Important: our FastAPI server runs on 8000)

5. **Auto scaling**:
   - Minimum size: `1` (AWS requires at least 1 instance)
   - Maximum size: `1` (keeps costs low)

6. Click **Next**

### Step 4: Configure Health Check

1. **Health check configuration**:
   - Protocol: **HTTP**
   - Path: `/health`
   - Interval: `20` seconds (maximum allowed)
   - Timeout: `5` seconds
   - Healthy threshold: `2`
   - Unhealthy threshold: `5`

2. Click **Next**

### Step 5: Review and Create

1. Review all settings
2. Click **Create & deploy**
3. **Wait 5-10 minutes** - watch the Events log
4. Status will change from "Operation in progress" to "Running"

✅ **Checkpoint**: Service shows "Running" with green checkmark

### Step 6: Access Your Application

1. Click on the **Default domain** URL (like: `abc123.YOUR-REGION.awsapprunner.com`)
2. Your app should load with HTTPS automatically enabled!
3. Test all functionality:
   - Sign in with Clerk
   - Create a consultation summary
   - Sign out

🎉 **Congratulations!** Your healthcare app is now running on AWS!

## Part 8: Monitoring and Debugging

### View Logs

1. In your App Runner service, click **Logs** tab
2. **Application logs**: Your app's console output
3. **System logs**: Deployment and infrastructure logs
4. Click **View in CloudWatch** for detailed analysis

### Common Issues and Solutions

**"Unhealthy" status**:
- Check application logs for Python errors
- Verify all environment variables are set
- Ensure health check path is `/health`

**"Authentication failed"**:
- Double-check Clerk environment variables
- Verify JWKS URL is correct
- Check CloudWatch logs for specific errors

**Page not loading**:
- Ensure port is set to `8000`
- Check that Docker image was built with `--platform linux/amd64`
- Verify static files are being served

## Part 9: Updating Your Application

When you make code changes:

### Step 1: Rebuild and Push

**Mac/Linux**:
```bash
# 1. Rebuild with platform flag
docker build \
  --platform linux/amd64 \
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" \
  -t consultation-app .

# 2. Tag for ECR (use your account ID and region from .env file)
docker tag consultation-app:latest YOUR-ACCOUNT-ID.dkr.ecr.YOUR-REGION.amazonaws.com/consultation-app:latest

# 3. Push to ECR
docker push YOUR-ACCOUNT-ID.dkr.ecr.YOUR-REGION.amazonaws.com/consultation-app:latest
```

**Windows PowerShell**:
```powershell
# 1. Rebuild with platform flag
docker build `
  --platform linux/amd64 `
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$env:NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" `
  -t consultation-app .

# 2. Tag for ECR (use your account ID and region from .env file)
docker tag consultation-app:latest YOUR-ACCOUNT-ID.dkr.ecr.YOUR-REGION.amazonaws.com/consultation-app:latest

# 3. Push to ECR
docker push YOUR-ACCOUNT-ID.dkr.ecr.YOUR-REGION.amazonaws.com/consultation-app:latest
```

### Step 2: Deploy Update

1. Go to App Runner console
2. Click your service
3. Click **Deploy**
4. Wait for deployment to complete

## Cost Management

### What This Costs

With our minimal configuration (1 instance always running):
- App Runner: ~$0.007/hour = ~$5/month for continuous running
- ECR: ~$0.10/GB/month for image storage
- Total: ~$5-6/month

**Note**: AWS App Runner requires at least 1 instance running, so you'll pay for continuous availability. To save money, you can pause the service when not in use.

### How to Save Money

1. **Pause when not using**: Pause your App Runner service (Actions → Pause service)
2. **Use free tier**: New AWS accounts get credits
3. **Monitor budgets**: Check your email for alerts
4. **Clean up ECR**: Delete old image versions

### Emergency Cost Control

If you hit budget alerts:
1. Go to App Runner → Select service → **Actions** → **Pause service**
2. Review CloudWatch logs for any issues
3. Check ECR for multiple image versions (delete old ones)

## What You've Accomplished

You've successfully:
- ✅ Created a production AWS account with security best practices
- ✅ Containerized a full-stack application with Docker
- ✅ Deployed to AWS App Runner with HTTPS and monitoring
- ✅ Set up cost controls and budget alerts
- ✅ Learned professional deployment patterns

## Architecture Comparison: Vercel vs AWS

**Vercel Architecture**:
- Next.js runs on Vercel's servers
- API routes handled by Vercel Functions
- Automatic deployments from Git
- Zero-config setup

**AWS Architecture**:
- Everything runs in a single Docker container
- FastAPI serves both API and static files
- Manual deployments (or automated with CI/CD)
- Full control over infrastructure

Both are valid approaches! Vercel optimizes for developer experience, while AWS offers more control and flexibility.

## Next Steps

### Immediate Improvements
1. **Custom domain**: Add your own domain in App Runner settings
2. **Auto-deployment**: Set up GitHub Actions for automated deployments
3. **Monitoring**: Add CloudWatch alarms for errors

### Advanced Enhancements
1. **Database**: Add Amazon RDS for data persistence
2. **File storage**: Use S3 for user uploads
3. **Caching**: Add ElastiCache for performance
4. **CDN**: Use CloudFront for global distribution
5. **Secrets Manager**: Store sensitive data securely

## Troubleshooting Reference

### Docker Issues

**"Cannot connect to Docker daemon"**:
```bash
# Make sure Docker Desktop is running
# Mac: Check for whale icon in menu bar
# Windows: Check system tray
```

**"Exec format error" when running container**:
```bash
# You forgot --platform flag. Rebuild:
docker build --platform linux/amd64 ...
```

### AWS Issues

**"Unauthorized" in ECR push**:
```bash
# Re-authenticate (use your region):
aws ecr get-login-password --region YOUR-REGION | docker login --username AWS --password-stdin [your-ecr-url]
```

**"Access Denied" errors**:
- Check IAM user has all required policies
- Verify AWS CLI is configured with correct credentials

### Application Issues

**Clerk authentication not working**:
- Verify all three Clerk environment variables
- Check JWKS URL matches your Clerk app
- Ensure frontend was built with public key

**API calls failing**:
- Check browser console for CORS errors
- Verify `/api/consultation` path is correct
- Check CloudWatch logs for Python errors

## Conclusion

Congratulations on deploying your healthcare SaaS to AWS! You've learned:

1. **Docker basics** - containerizing applications
2. **AWS fundamentals** - IAM, ECR, App Runner
3. **Production deployment** - security, monitoring, cost control
4. **DevOps practices** - CI/CD preparation, logging, health checks

This is how professional engineering teams deploy production applications. You now have the skills to deploy any containerized application to AWS!

## Resources

- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [Docker Documentation](https://docs.docker.com/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Cost Management](https://aws.amazon.com/aws-cost-management/)

Remember to monitor your AWS costs and pause/delete resources when not in use. Happy deploying! 🚀