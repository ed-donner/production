# Clerk Core 3 conversion examples

## Landing page nav + hero

**Before (lesson / Clerk v6)**

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

**After (client page)**

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
  <SignInButton mode="modal">
    <button>Sign In</button>
  </SignInButton>
)}
```

Move `afterSignOutUrl="/"` to `ClerkProvider` in `pages/_app.tsx`.

## Product page plan gate

**Before**

```tsx
<Protect
  plan="premium_subscription"
  fallback={<PricingTable />}
>
  <IdeaGenerator />
</Protect>
```

**After**

```tsx
const { isLoaded, has } = useAuth();
const hasPremium = Boolean(isLoaded && has?.({ plan: 'premium_subscription' }));

{hasPremium ? <IdeaGenerator /> : <PricingTable />}
```

Do not mount `IdeaGenerator` until `hasPremium` is true, or the SSE request fires for non-subscribers.

## Server components only

```tsx
import { Show, SignInButton, UserButton } from '@clerk/nextjs';

<Show when="signed-out">
  <SignInButton mode="modal" />
</Show>
<Show when="signed-in">
  <UserButton />
</Show>

<Show when={{ plan: 'premium_subscription' }} fallback={<PricingTable />}>
  <IdeaGenerator />
</Show>
```
