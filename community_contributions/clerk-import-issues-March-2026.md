# Issue with Clerk v6+ - Solution

## Description

In week 1, when first working with Clerk, I noticed that index.tsx had some import errors and an issue with the afterSignOutUrl button. The import errors had to do with the SignedIn and SignedOut modules.

# The Solution

To fix this, in your index.tsx code, use this instead.  It fixes the imports (uses "Show" instead of the deprecated "SignedIn" and "SignedOut"):

```TypeScript
"use client";

import Link from "next/link";
import { SignInButton, Show, UserButton } from "@clerk/nextjs";

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-12">
        <nav className="flex justify-between items-center mb-12">
          <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-200">
            IdeaGen
          </h1>

          <div>
            <Show when="signed-out">
              <SignInButton mode="modal">
                <button className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors">
                  Sign In
                </button>
              </SignInButton>
            </Show>

            <Show when="signed-in">
              <div className="flex items-center gap-4">
                <Link
                  href="/product"
                  className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors"
                >
                  Go to App
                </Link>
                <UserButton />
              </div>
            </Show>
          </div>
        </nav>

        <div className="text-center py-24">
          <h2 className="text-6xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-6">
            Generate Your Next
            <br />
            Big Business Idea
          </h2>

          <p className="text-xl text-gray-600 dark:text-gray-400 mb-12 max-w-2xl mx-auto">
            Harness the power of AI to discover innovative business opportunities tailored for the AI agent economy
          </p>

          <Show when="signed-out">
            <SignInButton mode="modal">
              <button className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                Get Started Free
              </button>
            </SignInButton>
          </Show>

          <Show when="signed-in">
            <Link href="/product">
              <button className="bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                Generate Ideas Now
              </button>
            </Link>
          </Show>
        </div>
      </div>
    </main>
  );
}
```

Also, create a file in your pages folder called "layout.tsx". This is where the "afterSignOutUrl" module is now supposed to live.

```TypeScript
import { ClerkProvider } from "@clerk/nextjs";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider afterSignOutUrl="/">
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```
