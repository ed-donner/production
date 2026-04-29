# Day 3 Part 2: Adding Subscriptions with Clerk Billing

## Transform Your SaaS with Subscription Management

Now let's add subscription tiers to your Business Idea Generator, turning it into a full-fledged SaaS with payment processing and subscription management built-in.

## What You'll Build

An enhanced version of your app that:
- Requires a paid subscription to access the idea generator
- Shows a beautiful pricing table to non-subscribers
- Handles payment processing through Clerk Billing
- Manages subscription status automatically
- Provides a user menu with billing management options

## Prerequisites

- Completed Day 3 Part 1 (authentication working)
- Your app deployed to Vercel

## Step 1: Enable Clerk Billing

### Navigate to Clerk Dashboard

1. Go to your [Clerk Dashboard](https://dashboard.clerk.com)
2. Select your **SaaS** application
3. Click **Configure** in the top navigation
4. Click **Billing>>Subscription Plans** in the left sidebar
5. Click **Get Started** if this is your first time

### Enable Billing

1. Click **Enable Billing** if prompted
2. Accept the terms if prompted
3. You'll see the Subscription Plans page

## Step 2: Create Your Subscription Plan

### Configure the Plan

1. Click **Create Plan**
2. Fill in the details:
   - **Name:** Premium Subscription
   - **Key:** `premium_subscription` (this is important - copy it exactly)
   - **Price:** $10.00 monthly (or your preferred price)
   - **Description:** Unlimited AI-powered business ideas
3. Optional: Add an annual discount
   - Toggle on **Annual billing**
   - Set annual price (e.g., $100/year for a discount)
4. Click **Save**

### Copy the Plan ID

After creating the plan, you'll see a **Plan ID** in the top right of the plan card (it looks like `plan_...`). You'll need this for testing, but Clerk handles it automatically in production.

## Step 3: Update Your Product Page

Since we're using Pages Router with client-side components, we need to protect our product route with the subscription check.

Update `pages/product.tsx`:

```typescript
"use client"

import { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkBreaks from 'remark-breaks';
import { useAuth } from '@clerk/nextjs';
import { fetchEventSource } from '@microsoft/fetch-event-source';
import { Protect, PricingTable, UserButton } from '@clerk/nextjs';

function IdeaGenerator() {
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
    );
}

export default function Product() {
    return (
        <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
            {/* User Menu in Top Right */}
            <div className="absolute top-4 right-4">
                <UserButton showName={true} />
            </div>

            {/* Subscription Protection */}
            <Protect
                plan="premium_subscription"
                fallback={
                    <div className="container mx-auto px-4 py-12">
                        <header className="text-center mb-12">
                            <h1 className="text-5xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-4">
                                Choose Your Plan
                            </h1>
                            <p className="text-gray-600 dark:text-gray-400 text-lg mb-8">
                                Unlock unlimited AI-powered business ideas
                            </p>
                        </header>
                        <div className="max-w-4xl mx-auto">
                            <PricingTable />
                        </div>
                    </div>
                }
            >
                <IdeaGenerator />
            </Protect>
        </main>
    );
}
```

## Step 4: Update Your Landing Page

Let's update the landing page to better reflect the subscription model.

Update `pages/index.tsx`:

```typescript
"use client"

import Link from 'next/link';
import { SignInButton, SignedIn, SignedOut, UserButton } from '@clerk/nextjs';

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-12">
        {/* Navigation */}
        <nav className="flex justify-between items-center mb-12">
          <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-200">
            IdeaGen Pro
          </h1>
          <div>
            <SignedOut>
              <SignInButton mode="modal">
                <button className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors">
                  Sign In
                </button>
              </SignInButton>
            </SignedOut>
            <SignedIn>
              <div className="flex items-center gap-4">
                <Link 
                  href="/product" 
                  className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors"
                >
                  Go to App
                </Link>
                <UserButton showName={true} />
              </div>
            </SignedIn>
          </div>
        </nav>

        {/* Hero Section */}
        <div className="text-center py-24">
          <h2 className="text-6xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-6">
            Generate Your Next
            <br />
            Big Business Idea
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-400 mb-8 max-w-2xl mx-auto">
            Harness the power of AI to discover innovative business opportunities tailored for the AI agent economy
          </p>
          
          {/* Pricing Preview */}
          <div className="bg-white/80 dark:bg-gray-800/80 backdrop-blur-lg rounded-xl p-6 max-w-sm mx-auto mb-8">
            <h3 className="text-2xl font-bold mb-2">Premium Subscription</h3>
            <p className="text-4xl font-bold text-blue-600 mb-2">$10<span className="text-lg text-gray-600">/month</span></p>
            <ul className="text-left text-gray-600 dark:text-gray-400 mb-6">
              <li className="mb-2">✓ Unlimited idea generation</li>
              <li className="mb-2">✓ Advanced AI models</li>
              <li className="mb-2">✓ Priority support</li>
            </ul>
          </div>
          
          <SignedOut>
            <SignInButton mode="modal">
              <button className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                Start Your Free Trial
              </button>
            </SignInButton>
          </SignedOut>
          <SignedIn>
            <Link href="/product">
              <button className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                Access Premium Features
              </button>
            </Link>
          </SignedIn>
        </div>
      </div>
    </main>
  );
}
```

## Step 5: Configure Billing Provider (Optional)

Clerk comes with a built-in payment gateway that's ready to use immediately:

1. In Clerk Dashboard → **Configure** → **Billing** → **Settings** (in the left sidebar)
2. By default, **Clerk payment gateway** is selected:
   - "Our zero-config payment gateway. Ready to process test payments immediately."
   - This works great for testing and development
3. **Optional:** You can switch to Stripe if you prefer:
   - Select **Stripe** instead
   - Follow Clerk's setup wizard to connect your Stripe account

**Note:** The Clerk payment gateway is perfect for getting started - it handles test payments immediately without any additional setup.

## Step 6: Test Your Subscription Flow

Deploy your updated application:

```bash
vercel --prod
```

### Testing the Flow

1. Visit your production URL
2. Sign in (or create a new account)
3. Click "Go to App" or "Access Premium Features"
4. You'll see the pricing table since you don't have a subscription
5. Click **Subscribe** on the Premium plan
6. If you haven't connected a payment provider, Clerk will simulate the subscription
7. After subscribing, you'll have access to the idea generator

### Managing Subscriptions

Users can manage their subscriptions through the UserButton menu:
1. Click on their profile picture (UserButton)
2. Select **Manage account**
3. Navigate to **Subscriptions**
4. View or cancel their subscription

## What's Happening?

Your app now has:
- **Subscription Gate**: Users must have an active subscription to access the product
- **Pricing Table**: Beautiful, Clerk-managed pricing display
- **Payment Processing**: Handled entirely by Clerk (with Stripe integration if configured)
- **User Management**: Subscription status in the UserButton menu
- **Automatic Enforcement**: Clerk automatically checks subscription status

## Architecture Overview

1. **User visits `/product`** → Clerk checks subscription status
2. **No subscription** → Shows PricingTable component
3. **Has subscription** → Shows IdeaGenerator component
4. **Payment** → Handled by Clerk Billing (optionally with Stripe)
5. **Management** → Users manage subscriptions through Clerk's UI

## Troubleshooting

### "Plan not found" error
- Ensure the plan key is exactly `premium_subscription`
- Check that billing is enabled in Clerk Dashboard
- Verify the plan is active (not archived)

### Pricing table not showing
- Clear browser cache and cookies
- Check that `@clerk/nextjs` is up to date
- Ensure billing is enabled in your Clerk application

### Always seeing the pricing table (even after subscribing)
- Check the user's subscription status in Clerk Dashboard
- Verify the plan key matches exactly
- Try signing out and back in

### Payment not working
- This is normal if you haven't connected a payment provider
- Clerk will simulate subscriptions in test mode
- For real payments, connect Stripe in Billing Settings

## Customization Options

### Different Plan Tiers

You can create multiple plans in Clerk Dashboard:
```typescript
<Protect
    plan={["basic_plan", "premium_plan", "enterprise_plan"]}
    fallback={<PricingTable />}
>
    <IdeaGenerator />
</Protect>
```

### Custom Pricing Table

Instead of Clerk's default PricingTable, you can build your own:
```typescript
<Protect
    plan="premium_subscription"
    fallback={<CustomPricingPage />}
>
    <IdeaGenerator />
</Protect>
```

### Usage Limits

Track API usage per user in your backend:
```python
@app.get("/api")
def idea(creds: HTTPAuthorizationCredentials = Depends(clerk_guard)):
    user_id = creds.decoded["sub"]
    subscription_plan = creds.decoded.get("subscription", "free")
    
    # Apply different limits based on plan
    if subscription_plan == "premium_subscription":
        # Unlimited or high limit
        pass
    else:
        # Limited access
        pass
```

## Next Steps

Congratulations! You've built a complete SaaS with:
- ✅ User authentication
- ✅ Subscription management
- ✅ Payment processing
- ✅ AI-powered features
- ✅ Professional UI/UX

### Ideas for Enhancement

1. **Multiple subscription tiers** (Basic, Pro, Enterprise)
2. **Usage tracking** and limits per tier
3. **Webhook integration** for subscription events
4. **Email notifications** for subscription changes
5. **Admin dashboard** to manage users and subscriptions
6. **Annual billing discounts**
7. **Free trial periods**

Your Business Idea Generator is now a fully-functional SaaS product ready for real customers!