# Clerk Core 3: replace SignedIn, SignedOut, and Protect

**Week 1 Day 3 / Day 3 Part 2 / Day 4** | `@clerk/nextjs` v7 (Core 3) on Pages Router

**By Onur Sencan**

If you installed the latest Clerk (`@clerk/nextjs` v7) instead of pinning `6.39.0`, the landing page and product page can crash with:

```text
Clerk: <SignedOut> is not available in @clerk/nextjs Core 3.
Clerk: <Protect> is not available in @clerk/nextjs Core 3.
```

Those components still export so the build does not fail with "undefined is not a component". Rendering them throws that error instead.

Updated lesson copies are in `week1/day3_v2.md`, `week1/day3.part2_v2.md`, and `week1/day4_v2.md`. The original `day3.md` / `day4.md` files still match the current videos.

If you already built Week 1 on v6 and want Cursor to convert your app, copy [clerk-core3-auth](clerk-core3-auth/) into your SaaS repo as `.cursor/skills/clerk-core3-auth/`.

## What changed

Clerk Core 3 removed `<SignedIn>`, `<SignedOut>`, and `<Protect>`. The official replacement is `<Show>`.

`<Show>` from `@clerk/nextjs` is a **server** control. Week 1 pages are `"use client"` Pages Router files, so `<Show>` does not see the browser session. On those pages, use `useAuth()`.

- **Client component** (`"use client"`) → `useAuth()`
- **Server component** → `<Show>`

## SignedIn / SignedOut → useAuth()

**Before (older lesson code)**

```tsx
import { SignInButton, SignedIn, SignedOut, UserButton } from '@clerk/nextjs';

<SignedOut>
  <SignInButton mode="modal">
    <button>Sign In</button>
  </SignInButton>
</SignedOut>
<SignedIn>
  <Link href="/product">Go to App</Link>
  <UserButton afterSignOutUrl="/" />
</SignedIn>
```

**After**

```tsx
"use client"

import { SignInButton, UserButton, useAuth } from '@clerk/nextjs';

const { isLoaded, isSignedIn } = useAuth();
const showSignedIn = isLoaded && isSignedIn;

{showSignedIn ? (
  <>
    <Link href="/product">Go to App</Link>
    <UserButton />
  </>
) : (
  <SignInButton mode="modal">
    <button>Sign In</button>
  </SignInButton>
)}
```

Do **not** render `null` while `!isLoaded`. If Clerk is slow or the publishable key is missing, every CTA disappears. Default to the signed-out UI until `isLoaded && isSignedIn`.

`UserButton` no longer accepts `afterSignOutUrl`. Set it on `ClerkProvider` in `pages/_app.tsx`:

```tsx
<ClerkProvider {...pageProps} publishableKey={publishableKey} afterSignOutUrl="/">
```

## Protect → useAuth().has()

Day 3 Part 2 and Day 4 used `<Protect plan="premium_subscription">`. That throws the same Core 3 error.

**Before**

```tsx
<Protect plan="premium_subscription" fallback={<PricingTable />}>
  <IdeaGenerator />
</Protect>
```

**After**

```tsx
const { isLoaded, has } = useAuth();
const hasPremium = Boolean(isLoaded && has?.({ plan: 'premium_subscription' }));

{hasPremium ? <IdeaGenerator /> : <PricingTable />}
```

Do not mount `IdeaGenerator` (or the Day 4 `ConsultationForm`) until `hasPremium` is true, or the SSE request fires for people without a plan.

`has()` also accepts `{ role: '...' }`, `{ permission: '...' }`, `{ feature: '...' }`.

## If you are on a server component

Use `<Show>`:

| Old | New |
| --- | --- |
| `<SignedIn>` | `<Show when="signed-in">` |
| `<SignedOut>` | `<Show when="signed-out">` |
| `<Protect>` (no props) | `<Show when="signed-in">` |
| `<Protect plan="x">` | `<Show when={{ plan: "x" }}>` |
| `<Protect role="x">` | `<Show when={{ role: "x" }}>` |
| `<Protect permission="x">` | `<Show when={{ permission: "x" }}>` |

`Show` accepts `fallback={...}` for the failed-condition UI.

## Related gotchas

- Keep `pages/_app.tsx` **without** `"use client"`. That directive can make Clerk pick the App Router provider, and clerk-js never loads.
- Next.js 16 uses `proxy.ts` with `clerkMiddleware()`, not `middleware.ts`.
- If Sign In never appears after `vercel --prod`, see [clerk_publishable_key_vercel.md](clerk_publishable_key_vercel.md).
