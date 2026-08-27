# Vercel Clerk publishable key: use `CLERK_PUBLISHABLE_KEY`

**Week 1 Day 3** | Clerk on Next.js Pages Router + `vercel --prod`

**By Onur Sencan**

## The problem

Day 3 originally told you to add:

```bash
vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
```

Vercel Clerk often provisions `CLERK_PUBLISHABLE_KEY` instead. The `NEXT_PUBLIC_` name can be blocked or awkward to store as a production env var.

Clerk's browser SDK only auto-reads `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`. If that name is missing, clerk-js never loads. `useAuth().isLoaded` stays false, and the homepage CTAs never appear after `vercel --prod`.

## The fix

Keep the Vercel env var as `CLERK_PUBLISHABLE_KEY`. Then expose it to the browser at **build time**.

### 1. `next.config.ts`

```ts
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

`env` in `next.config.ts` inlines the value into the client bundle. Next.js will not do that for a non-`NEXT_PUBLIC_` var on its own.

### 2. `pages/_app.tsx`

```tsx
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

Do **not** add `"use client"` to `_app.tsx`. That can make Clerk pick the App Router provider on Pages Router.

### 3. Vercel env vars

```bash
vercel env add CLERK_PUBLISHABLE_KEY
vercel env add CLERK_SECRET_KEY
vercel env add CLERK_JWKS_URL
```

If Vercel lets you add `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` instead, that also works — the `next.config.ts` snippet accepts either name.

Then rebuild:

```bash
vercel --prod
```

`NEXT_PUBLIC_` values are baked in at build time. Changing the env var without a new deploy will not fix production.

## How to tell it worked

- Production HTML still has **Sign In** / **Get Started Free**
- Browser console shows Clerk loaded with development keys (for `pk_test_`)
- After sign-in, the product CTA appears
