# INSTANT GRATIFICATION!

## Production Deployment in minutes

This guide will walk you through deploying a simple FastAPI application to Vercel in under 10 minutes.

## Step 1: Sign Up for Vercel

1. Open your web browser and navigate to [https://vercel.com](https://vercel.com)
2. Click the **Sign Up** button in the top right corner
3. Select **Hobby** (for personal projects)
4. Enter your name
5. Choose one of the following sign-up methods:
   - **GitHub** (recommended) - Click "Continue with GitHub" and authorize Vercel
   - **GitLab** - Click "Continue with GitLab" and authorize Vercel
   - **Bitbucket** - Click "Continue with Bitbucket" and authorize Vercel
   - **Email** - Enter your email address and follow the verification steps
6. Complete the onboarding (you can skip team creation)

## Step 2: Install Cursor IDE

> Note: You can use a different IDE if you prefer (VS Code, PyCharm, etc.), but these instructions assume you're using Cursor.

1. Visit [Cursor Desktop QuickStart](https://cursor.com/docs/get-started/quickstart)
2. Follow the first step "1. Install Cursor and sign in" for macOS, Windows or Linux
4. If `AppImage` was downloaded, directly run it in the terminal: `/path/to/Cursor-*.AppImage`
5. For the rest of systems the run can be done using native desktop launcher


### Create Your Project Folder

1. Open Cursor
2. **Windows/Linux:** Click File → Open Folder → Create a new folder called "instant"
3. **Mac:** Click File → Open → Create a new folder called "instant"
4. Select and open the "instant" folder

## Step 3: Create Your FastAPI Application

In Cursor, create a new file called `instant.py` with the following content:

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def instant():
    return "Live from production!"
```

Save the file (Ctrl+S on Windows/Linux, Cmd+S on Mac).

## Step 4: Create Requirements File

Create a new file called `requirements.txt` with the following content:

```
fastapi
uvicorn
```

Save the file.

## Step 5: Create Vercel Configuration

Create a new file called `vercel.json` with the following content:

```json
{
    "builds": [
        {
            "src": "instant.py",
            "use": "@vercel/python"
        }
    ],
    "routes": [
        {
            "src": "/(.*)",
            "dest": "instant.py"
        }
    ]
}
```

Save the file.

## Step 6: Install Node.js

Node.js is required for the Vercel CLI.

1. Visit the official Node.js download page: [https://nodejs.org/en/download](https://nodejs.org/en/download)

2. Choose your preferred installation method:
   - **Direct Download:** Download the installer for your operating system
   - **Package Manager:** Use the package manager for your platform (Homebrew for Mac, Chocolatey for Windows, etc.)
   - **Version Manager (recommended):** Use nvm, fnm, or volta for easy version management

3. After installation, open a **new** terminal window

4. Verify installation:
   ```bash
   node --version
   npm --version
   ```

Both commands should return version numbers if installed correctly.

## Step 7: Deploy to Vercel

### Open Terminal in Cursor

- Click Terminal → New Terminal (or press Ctrl+\` on Windows/Linux, Cmd+\` on Mac)

**Make sure you're in your "instant" project folder** - you should see your three files (instant.py, requirements.txt, vercel.json) when you list files.

### Install Vercel CLI and Deploy

1. Install Vercel CLI globally:
   ```bash
   npm install -g vercel
   ```

2. Login to Vercel:
   ```bash
   vercel login
   ```
   - Enter the email address you used to sign up for Vercel
   - Check your email for a verification link and click it
   - Return to the terminal - it should confirm you're logged in

3. Deploy to Vercel (development):
   ```bash
   vercel .
   ```
   - When prompted "Set up and deploy?"  → Press Enter (Yes)
   - "Which scope?"  → Select your personal account
   - "Link to existing project?"  → Type `n` and press Enter (No)
   - "What's your project's name?"  → Type `instant` and press Enter
   - "In which directory is your code located?"  → Press Enter (current directory)
   - Wait for deployment to complete (usually 30-60 seconds)
   - You'll see a URL like `https://instant-xxxxxx.vercel.app`

4. Test your development deployment:
   - Click the URL provided (or copy and paste into browser)
   - You should see: **"Live from production!"**


## Congratulations! 🎉

You've successfully deployed your first API to production! Your API is now:
- ✅ Live on the internet
- ✅ Automatically scaled
- ✅ Secured with HTTPS
- ✅ Accessible from anywhere in the world

### What You've Learned:
- How to create a simple FastAPI application
- How to configure a project for Vercel deployment
- How to use the Vercel CLI for deployment

### Next Steps:
- Try modifying the message in `instant.py` and redeploying
- Add more API endpoints
- Explore Vercel's dashboard at [https://vercel.com/dashboard](https://vercel.com/dashboard)

## Troubleshooting

### "vercel: command not found"
- Make sure you opened a **new** terminal after installing Node.js
- Try running `npm install -g vercel` again

### "Python version not supported"
- Vercel supports Python 3.9, 3.10, 3.11, and 3.12
- The default should work, but if you have issues, add a `runtime.txt` file with: `python-3.12`

### Deployment fails
- Check that all three files (instant.py, requirements.txt, vercel.json) are in your project folder
- Make sure you're in the correct directory when running `vercel`
- Ensure your vercel.json has the exact JSON structure shown above

### Need Help?
- Check Vercel's documentation: [https://vercel.com/docs](https://vercel.com/docs)
- Ask in class or post in the course forum
