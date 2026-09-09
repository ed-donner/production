# Day 3: Adding User Authentication with Clerk

## Transform Your SaaS with Professional Authentication

Today you'll add enterprise-grade authentication to your Business Idea Generator, allowing users to sign in with Google, GitHub, and other providers. This transforms your app from a demo into a real SaaS product.

## What You'll Build

An authenticated version of your app that:
- Requires users to sign in before accessing the idea generator
- Supports multiple authentication providers (Google, GitHub, Email)
- Passes secure JWT tokens to your backend
- Verifies user identity on every API request
- Works seamlessly with Next.js Pages Router

## Prerequisites

- Completed Day 2 (working Business Idea Generator)
- Your project deployed to Vercel

## IMPORTANT Note - added since the videos

In some situations, if your app takes longer than 60 seconds to respond to a request, it's possible that you experience a Timeout error. You'll see in the browser's Javascript Console that you're getting a 403 error. The fix for this is in community_contributions explained in the file jwt_token_60s_fix.md. Look out for this 403 timeout after 60 seconds, and if it happens, please see the fix. Thanks!

Clerk Core 3 (`@clerk/nextjs` v7) also removed `<SignedIn>`, `<SignedOut>`, and `<Protect>`. The Week 1 samples now use `useAuth()`. If you copied older snippets and see those components are "not available", see [clerk_core3_signedin_signedout.md](../community_contributions/clerk_core3_signedin_signedout.md). If Sign In never appears after `vercel --prod`, see [clerk_publishable_key_vercel.md](../community_contributions/clerk_publishable_key_vercel.md).


## Part 1: User Authentication

### Step 1: Create Your Clerk Account

1. Visit [clerk.com](https://clerk.com) and click **Sign Up**
2. Create your account using Google auth (or your preferred method)
3. You'll be taken to **Create Application** (or click "Create Application" if returning)

### Step 2: Configure Your Clerk Application

1. **Application name:** SaaS
2. **Sign-in options:** Enable these providers:
   - Email
   - Google  
   - GitHub
   - Apple (optional)
3. Click **Create Application**

You'll see the Clerk dashboard with your API keys displayed.

### Step 3: Install Clerk Dependencies

Side note: The latest `@clerk/nextjs` as of Core 3 is v7. It removed `<SignedIn>`, `<SignedOut>`, and `<Protect>`. Rendering them throws `Clerk: <SignedOut> is not available in @clerk/nextjs Core 3`. On Week 1 Pages Router client pages, use `useAuth()` instead of those components. The code samples below are already updated. Full notes: [clerk_core3_signedin_signedout.md](../community_contributions/clerk_core3_signedin_signedout.md).

If you want to stay on the original lesson version, pin v6:

```bash
npm install @clerk/nextjs@6.39.0
```

For handling streaming with authentication, also install:

```bash
npm install @microsoft/fetch-event-source
```

### Step 4: Configure Environment Variables

Create a `.env.local` file in your project root:

```bash
CLERK_PUBLISHABLE_KEY=your_publishable_key_here
CLERK_SECRET_KEY=your_secret_key_here
```

Clerk's browser SDK auto-reads `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`. Vercel Clerk often provisions `CLERK_PUBLISHABLE_KEY` instead. Use that name, then inline it in `next.config.ts` so it reaches the browser (see Step 5). Details: [clerk_publishable_key_vercel.md](../community_contributions/clerk_publishable_key_vercel.md).

**Important:** Copy these values from the Clerk dashboard (they're displayed after creating your application on the configure screen, in the API Keys section). Remember to save the .env.local file after changing it.

### Add to .gitignore

Open `.gitignore` in Cursor and add `.env.local` on a new line.

### Step 5: Add Clerk Provider to Your App

With Pages Router, we need to wrap our application with the Clerk provider. Do **not** add `"use client"` to `_app.tsx`.

Also update `next.config.ts` so `CLERK_PUBLISHABLE_KEY` is inlined into the client bundle:

```typescript
import type { NextConfig } from "next";

const clerkPublishableKey =
  process.env.CLERK_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY ||
  '';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  env: {
    CLERK_PUBLISHABLE_KEY: clerkPublishableKey,
  },
};

export default nextConfig;
```

Update `pages/_app.tsx`:

```typescript
import { ClerkProvider } from '@clerk/nextjs';
import type { AppProps } from 'next/app';
import '../styles/globals.css';

export default function MyApp({ Component, pageProps }: AppProps) {
  const publishableKey = process.env.CLERK_PUBLISHABLE_KEY;

  return (
    <ClerkProvider {...pageProps} publishableKey={publishableKey} afterSignOutUrl="/">
      <Component {...pageProps} />
    </ClerkProvider>
  );
}
```

### Step 6: Create the Product Page

Move your business idea generator to a protected route. Since we're using client-side authentication, we'll protect this route using Clerk's built-in components.

Create `pages/product.tsx`:

```typescript
"use client"

import { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkBreaks from 'remark-breaks';
import { useAuth } from '@clerk/nextjs';
import { fetchEventSource } from '@microsoft/fetch-event-source';

export default function Product() {
    const { getToken } = useAuth();
    const [idea, setIdea] = useState<string>('…loading');

    useEffect(() => {
        let buffer = '';
        (async () => {
            const jwt = await getToken();
            if (!jwt) {
                setIdea('Authentication required');
                return;
            }
            
            await fetchEventSource('/api', {
                headers: { Authorization: `Bearer ${jwt}` },
                onmessage(ev) {
                    buffer += ev.data;
                    setIdea(buffer);
                },
                onerror(err) {
                    console.error('SSE error:', err);
                    // Don't throw - let it retry
                }
            });
        })();
    }, []); // Empty dependency array - run once on mount

    return (
        <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
            <div className="container mx-auto px-4 py-12">
                {/* Header */}
                <header className="text-center mb-12">
                    <h1 className="text-5xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-4">
                        Business Idea Generator
                    </h1>
                    <p className="text-gray-600 dark:text-gray-400 text-lg">
                        AI-powered innovation at your fingertips
                    </p>
                </header>

                {/* Content Card */}
                <div className="max-w-3xl mx-auto">
                    <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8 backdrop-blur-lg bg-opacity-95">
                        {idea === '…loading' ? (
                            <div className="flex items-center justify-center py-12">
                                <div className="animate-pulse text-gray-400">
                                    Generating your business idea...
                                </div>
                            </div>
                        ) : (
                            <div className="markdown-content text-gray-700 dark:text-gray-300">
                                <ReactMarkdown
                                    remarkPlugins={[remarkGfm, remarkBreaks]}
                                >
                                    {idea}
                                </ReactMarkdown>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </main>
    );
}
```

### Step 7: Create the Landing Page

Update `pages/index.tsx` to be your new landing page with sign-in. Clerk Core 3 removed `<SignedIn>` / `<SignedOut>`, so this sample uses `useAuth()`:

```typescript
"use client"

import Link from 'next/link';
import { SignInButton, UserButton, useAuth } from '@clerk/nextjs';

export default function Home() {
  const { isLoaded, isSignedIn } = useAuth();
  const showSignedIn = isLoaded && isSignedIn;

  return (
    <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-12">
        {/* Navigation */}
        <nav className="flex justify-between items-center mb-12">
          <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-200">
            IdeaGen
          </h1>
          <div>
            {showSignedIn ? (
              <div className="flex items-center gap-4">
                <Link 
                  href="/product" 
                  className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors"
                >
                  Go to App
                </Link>
                <UserButton />
              </div>
            ) : (
              <SignInButton mode="modal">
                <button className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors">
                  Sign In
                </button>
              </SignInButton>
            )}
          </div>
        </nav>

        {/* Hero Section */}
        <div className="text-center py-24">
          <h2 className="text-6xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-6">
            Generate Your Next
            <br />
            Big Business Idea
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-400 mb-12 max-w-2xl mx-auto">
            Harness the power of AI to discover innovative business opportunities tailored for the AI agent economy
          </p>
          
          {showSignedIn ? (
            <Link href="/product">
              <button className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                Generate Ideas Now
              </button>
            </Link>
          ) : (
            <SignInButton mode="modal">
              <button className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                Get Started Free
              </button>
            </SignInButton>
          )}
        </div>
      </div>
    </main>
  );
}
```

### Step 8: Configure Backend Authentication

First, get your JWKS URL from Clerk:
1. Go to your Clerk Dashboard
2. Click **Configure** (top nav)
3. Click **API Keys** (side nav)  
4. Find **JWKS URL** and copy it

**What is JWKS?** The JWKS (JSON Web Key Set) URL is a public endpoint that contains Clerk's public keys. When a user signs in, Clerk creates a JWT (JSON Web Token) - a digitally signed token that proves the user's identity. Your Python backend uses the JWKS URL to fetch Clerk's public keys and verify that incoming JWT tokens are genuine and haven't been tampered with. This allows secure authentication without your backend needing to contact Clerk for every request - it can verify tokens independently using cryptographic signatures.

Add to `.env.local` and save:
```bash
CLERK_JWKS_URL=your_jwks_url_here
```

### Step 9: Update Backend Dependencies

Add the Clerk authentication library to `requirements.txt`:

```
fastapi
uvicorn
openai
fastapi-clerk-auth
```

### Step 10: Update the API with Authentication

Replace `api/index.py` with:

```python
import os
from fastapi import FastAPI, Depends  # type: ignore
from fastapi.responses import StreamingResponse  # type: ignore
from fastapi_clerk_auth import ClerkConfig, ClerkHTTPBearer, HTTPAuthorizationCredentials  # type: ignore
from openai import OpenAI  # type: ignore

app = FastAPI()

clerk_config = ClerkConfig(jwks_url=os.getenv("CLERK_JWKS_URL"))
clerk_guard = ClerkHTTPBearer(clerk_config)

@app.get("/api")
def idea(creds: HTTPAuthorizationCredentials = Depends(clerk_guard)):
    user_id = creds.decoded["sub"]  # User ID from JWT - available for future use
    # We now know which user is making the request! 
    # You could use user_id to:
    # - Track usage per user
    # - Store generated ideas in a database
    # - Apply user-specific limits or customization
    
    client = OpenAI()
    prompt = [{"role": "user", "content": "Reply with a new business idea for AI Agents, formatted with headings, sub-headings and bullet points"}]
    stream = client.chat.completions.create(model="gpt-5-nano", messages=prompt, stream=True)

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
```

### Step 11: Add Environment Variables to Vercel

Add your Clerk keys to Vercel:

```bash
vercel env add CLERK_PUBLISHABLE_KEY
```
Paste your publishable key and select all environments. If Vercel lets you add `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` instead, that also works — the `next.config.ts` snippet in Step 5 accepts either name.

```bash
vercel env add CLERK_SECRET_KEY
```
Paste your secret key and select all environments except for development.

```bash
vercel env add CLERK_JWKS_URL
```
Paste your JWKS URL and select all environments except for development.

### Step 12: (This step intentionally skipped - we will test after deployment)

### Step 13: Deploy to Production

Deploy your authenticated app:

```bash
vercel --prod
```

Visit your production URL and test the complete authentication flow!

NOTE - if you hit a problem with jwt token expiration, please see this [fix contributed by Artur P](../community_contributions/jwt_token_60s_fix.md). If Sign In never appears after `vercel --prod`, see [clerk_publishable_key_vercel.md](../community_contributions/clerk_publishable_key_vercel.md). If you get `SignedOut` / `Protect` is not available, see [clerk_core3_signedin_signedout.md](../community_contributions/clerk_core3_signedin_signedout.md).

## What's Happening?

Your app now has:
- **Secure authentication**: Users must sign in to access your product
- **Client-side route protection**: Unauthenticated users are redirected from protected pages
- **JWT verification**: Every API request is verified using cryptographic signatures
- **User identification**: The backend knows which user is making each request
- **Professional UX**: Modal sign-in, user profile management, and smooth redirects
- **Multiple providers**: Users can choose their preferred sign-in method

## Security Architecture

Since we're using client-side Next.js with a separate Python backend:

1. **Frontend (Browser)**: User signs in with Clerk → receives session token
2. **Client-Side Protection**: Protected routes check authentication status and redirect if needed
3. **API Request**: Browser sends JWT token directly to Python backend with each request
4. **Backend Verification**: FastAPI verifies the JWT using Clerk's public keys (JWKS)
5. **User Context**: Backend can access user ID and metadata from verified token

This architecture keeps your Next.js deployment simple (static/client-side only) while maintaining secure API authentication.

## Troubleshooting

### "Unauthorized" errors
- Check that all three environment variables are set correctly in Vercel
- Ensure the JWKS URL is copied correctly from Clerk
- Verify you're signed in before accessing `/product`

### Sign-in modal not appearing
- Check that `CLERK_PUBLISHABLE_KEY` (or `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`) starts with `pk_`
- Confirm `next.config.ts` inlines the key and `ClerkProvider` receives `publishableKey`
- Ensure you've wrapped your app with `ClerkProvider` and `_app.tsx` does **not** have `"use client"`
- Clear browser cache and cookies

### API not authenticating
- Verify `CLERK_JWKS_URL` is set in your environment
- Check that `fastapi-clerk-auth` is in requirements.txt
- Ensure the JWT token is being sent in the Authorization header

### Local development issues
- Make sure `.env.local` has all three Clerk variables
- Restart your dev server after adding environment variables
- Try clearing Next.js cache: `rm -rf .next`

## Next Steps

Congratulations! You've added professional authentication to your SaaS. In Part 2, we'll add:
- Subscription tiers with Stripe
- Usage limits based on subscription level
- Payment processing
- Customer portal for managing subscriptions

Your app is now a real SaaS product with secure user authentication!