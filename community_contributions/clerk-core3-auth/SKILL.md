---
name: clerk-core3-auth
description: Converts Clerk SignedIn, SignedOut, and Protect to Core 3 APIs (useAuth or Show). Use when @clerk/nextjs throws signedout-is-not-available, signedin-is-not-available, or protect-is-not-available, when lesson code uses SignedIn/SignedOut/Protect, when Show is used on a client page, or when migrating Clerk v6 to v7 / Core 3.
---

# Clerk Core 3 auth conversion

Copy this folder into your own SaaS repo as `.cursor/skills/clerk-core3-auth/` if you already built Week 1 on `@clerk/nextjs@6.39.0` and want Cursor to convert the old components.

`SignedIn`, `SignedOut`, and `Protect` were removed in Clerk Core 3 (`@clerk/nextjs` v7). They still export, but rendering them throws:

```text
Clerk: <SignedOut> is not available in @clerk/nextjs Core 3.
Clerk: <Protect> is not available in @clerk/nextjs Core 3.
```

Official replacement is `<Show>`. `Show` from `@clerk/nextjs` is a **server** control. On any `"use client"` file it does not see the browser session. Decide by component type, not router:

- **Client component** (`"use client"`) → `useAuth()`
- **Server component** → `<Show>`

Week 1 pages are client components, so default to `useAuth()`.

## Workflow

1. Search the repo (exclude `node_modules` and lesson markdown unless the user asked to edit lessons):

```bash
rg -n --glob '!node_modules' --glob '!week1/**' 'SignedIn|SignedOut|Protect' .
```

2. Convert every match. Keep the user's copy, layout, and extra props (`showName`, button labels).
3. Grep again. No TS/TSX file should import `SignedIn`, `SignedOut`, or `Protect`.
4. Do not render `null` while `!isLoaded`. Default to the signed-out or locked UI until Clerk confirms state.

## Client components (default here)

Use `useAuth()`.

### SignedIn / SignedOut

```tsx
"use client"

import { SignInButton, UserButton, useAuth } from '@clerk/nextjs';

const { isLoaded, isSignedIn } = useAuth();
const showSignedIn = isLoaded && isSignedIn;

{showSignedIn ? (
  <>
    <Link href="/product">Go to App</Link>
    <UserButton showName={true} />
  </>
) : (
  <SignInButton mode="modal">...</SignInButton>
)}
```

### Protect (plan / role / permission)

```tsx
const { isLoaded, has } = useAuth();
const hasPremium = Boolean(isLoaded && has?.({ plan: 'premium_subscription' }));

{hasPremium ? <IdeaGenerator /> : <PricingTable />}
```

`has()` also accepts `{ role: '...' }`, `{ permission: '...' }`, `{ feature: '...' }`.

Do not mount data-fetching children (for example `IdeaGenerator` SSE) until the plan check is true, or the request fires for non-subscribers.

For `<Protect condition={(has) => expr}>`, use `Boolean(isLoaded && expr)` with the same `has` from `useAuth()`.

## Server components

Use `<Show>` from `@clerk/nextjs`:

| Old | New |
| --- | --- |
| `<SignedIn>` | `<Show when="signed-in">` |
| `<SignedOut>` | `<Show when="signed-out">` |
| `<Protect>` (no props) | `<Show when="signed-in">` |
| `<Protect plan="x">` | `<Show when={{ plan: "x" }}>` |
| `<Protect role="x">` | `<Show when={{ role: "x" }}>` |
| `<Protect permission="x">` | `<Show when={{ permission: "x" }}>` |
| `<Protect condition={(has) => expr}>` | `<Show when={(has) => expr}>` |

`Show` accepts `fallback={...}` for the failed-condition UI.

## Related Core 3 fixes (same conversion)

- `UserButton` no longer takes `afterSignOutUrl`. Set it on `ClerkProvider`.
- Keep `pages/_app.tsx` **without** `"use client"`. That directive can make Clerk pick the App Router provider, and `clerk-js` never loads.
- Next.js 16: `proxy.ts` with `clerkMiddleware()`, not `middleware.ts`.

## Additional resources

- Before/after: [examples.md](examples.md)
- Course note: [../clerk_core3_signedin_signedout.md](../clerk_core3_signedin_signedout.md)
