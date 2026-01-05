# SaaS - Building a Full-Stack AI Application

## Build Your First SaaS Product with Next.js and FastAPI

Today you'll build a complete full-stack application with a React frontend and Python backend, all deployed to production on Vercel.

## What You'll Build

A **Business Idea Generator** - an AI-powered SaaS application that:
- Has a modern React frontend built with Next.js (using Pages Router for stability)
- Uses TypeScript for type safety
- Connects to a FastAPI backend
- Streams AI responses in real-time
- Renders beautiful Markdown content
- Deploys seamlessly to production

## Prerequisites

- Completed Day 1 (you should have Node.js and Vercel CLI installed)
- Your OpenAI API key from Day 1

## Step 1: Create Your Next.js Project

### Open Cursor and Create Your Project

1. Open Cursor
2. Open the terminal (Terminal → New Terminal or Ctrl+\` / Cmd+\`)
3. Navigate to your projects folder (or wherever you want to create the project)
4. Create a new Next.js project with TypeScript:


```bash
npx create-next-app saas --typescript
```

When prompted, respond to each question:
1. **Which linter would you like to use?** → Press Enter for **ESLint** (default)
2. **Would you like to use Tailwind CSS?** → Type `y` and press Enter for **Yes**
3. **Would you like your code inside a `src/` directory?** → Type `n` and press Enter for **No**
4. **Would you like to use App Router? (recommended)** → Type `n` and press Enter for **No** (we're using Pages Router)
5. **Would you like to use Turbopack? (recommended)** → Type `n` and press Enter for **No** (we'll keep the standard build for compatibility)
6. **Would you like to customize the import alias?** → Type `n` and press Enter for **No**

This creates a new Next.js project with:
- **Pages Router** (the stable, battle-tested routing system)
- **TypeScript** for type safety
- **ESLint** for catching errors and enforcing code quality
- **Tailwind CSS** for utility-first styling

### Open Your Project

1. In Cursor: File → Open Folder → Select the "saas" folder that was just created
2. You'll see several files and folders that Next.js created automatically

### Understanding the Project Structure

Next.js created these key files and folders:

```
saas/
├── pages/              # Pages Router directory (where your pages live)
│   ├── _app.tsx       # Application wrapper (initializes pages)
│   ├── _document.tsx  # Custom document (HTML structure)
│   ├── index.tsx      # Homepage (routes to "/")
│   └── api/           # API routes directory (we'll remove this)
│       └── hello.ts   # Sample API route (we'll remove this)
├── styles/            # Styles directory
│   └── globals.css    # Global styles (includes Tailwind)
├── public/            # Static files (images, fonts, etc.)
├── package.json       # Node.js dependencies and scripts
├── tsconfig.json      # TypeScript configuration
├── next.config.js     # Next.js configuration
└── node_modules/      # Installed packages (auto-generated)
```

**Key files explained:**
- **`pages/_app.tsx`**: The application wrapper that initializes all pages. Used for global providers and styles
- **`pages/_document.tsx`**: Custom document for modifying the HTML structure
- **`pages/index.tsx`**: Your homepage component. This is what users see at "/"
- **`styles/globals.css`**: Global styles including Tailwind CSS imports

### Clean Up Unnecessary Files

Since we're using a Python FastAPI backend (not Next.js API routes), let's remove the sample API directory:

1. In Cursor's file explorer (left sidebar), find the `pages/api` folder
2. Right-click on the `api` folder
3. Select **Delete** (or press Delete/Backspace key)
4. Confirm the deletion when prompted

### What is Tailwind CSS?

**Tailwind CSS** is a utility-first CSS framework. Instead of writing custom CSS, you apply pre-built utility classes directly in your HTML/JSX. For example:
- `bg-blue-500` sets a blue background
- `text-white` makes text white
- `p-4` adds padding on all sides
- `rounded-lg` rounds the corners

This approach makes styling faster and more consistent!

## Step 2: Set Up the Backend

### Create the API Folder

In Cursor's file explorer, create a new folder at the root level:
- Right-click in the file explorer → New Folder → name it `api`

### Create Python Dependencies

Create a new file `requirements.txt` in the root directory with:

```
fastapi
uvicorn
openai
```

### Create the API Server

Create a new file `api/index.py`:

```python
from fastapi import FastAPI  # type: ignore
from fastapi.responses import PlainTextResponse  # type: ignore
from openai import OpenAI  # type: ignore

app = FastAPI()

@app.get("/api", response_class=PlainTextResponse)
def idea():
    client = OpenAI()
    prompt = [{"role": "user", "content": "Come up with a new business idea for AI Agents"}]
    response = client.chat.completions.create(model="gpt-5-nano", messages=prompt)
    return response.choices[0].message.content
```

## Step 3: Create Your First Page

### Understanding Client Components

In Next.js Pages Router, all page components run on both server and client by default. Since we're using a **Python/FastAPI backend** for our API (not Next.js's server), we'll mark our components with `"use client"` to ensure:
- The component runs in the browser
- The browser makes direct API calls to our Python backend
- We're not trying to use Next.js as a middleman server

### Create the Homepage

Replace the entire contents of `pages/index.tsx` with:

```typescript
"use client"

import { useEffect, useState } from 'react';

export default function Home() {
    const [idea, setIdea] = useState<string>('…loading');

    useEffect(() => {
        fetch('/api')
            .then(res => res.text())
            .then(setIdea)
            .catch(err => setIdea('Error: ' + err.message));
    }, []);

    return (
        <main className="p-8 font-sans">
            <h1 className="text-3xl font-bold mb-4">
                Business Idea Generator
            </h1>
            <div className="w-full max-w-2xl p-6 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm">
                <p className="text-gray-900 dark:text-gray-100 whitespace-pre-wrap">
                    {idea}
                </p>
            </div>
        </main>
    );
}
```

**What's happening here:**
- `"use client"` tells Next.js this component runs in the browser
- The browser directly calls our Python FastAPI backend at `/api`
- We use React hooks to manage the UI state and fetch the data
- Vercel routes `/api` requests to our Python server (we don't need vercel.json configuration)

### Set Up the Application Wrapper

The `_app.tsx` file wraps all your pages. Let's create it to import our styles.

Create or replace `pages/_app.tsx` with:

```typescript
import type { AppProps } from 'next/app';
import '../styles/globals.css';  // This imports Tailwind styles

export default function MyApp({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}
```

### Set Up the Document

Now let's customize the HTML structure and add metadata.

Create `pages/_document.tsx`:

```typescript
import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
  return (
    <Html lang="en">
      <Head>
        <title>Business Idea Generator</title>
        <meta name="description" content="AI-powered business idea generation" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
```

## Step 4: Configure Your Project

**Note:** We don't need a `vercel.json` file - Vercel automatically detects both Next.js and Python files in the `api` folder using its default configuration.

## Step 5: Link Your Project

First, let's create and link your Vercel project:

```bash
vercel link
```

Follow the prompts:
- Set up and link? → Yes
- Which scope? → Your personal account
- Link to existing project? → No
- What's the name of your project? → saas
- In which directory is your code located? → Current directory (press Enter)

This creates your Vercel project and links it to your local directory.

## Step 6: Add Your OpenAI API Key

Now that the project is created, add your OpenAI API key:

```bash
vercel env add OPENAI_API_KEY
```
- Paste your API key when prompted
- Select all environments (development, preview, production)

## Step 7: Deploy and Test

Deploy your application to test it:

```bash
vercel .
```

When prompted "Set up and deploy?", answer **No** (we already linked the project).

Visit the URL provided to see your Business Idea Generator loading an AI-generated idea!

**Note:** We test using the deployed version rather than local development, as this ensures both the Next.js frontend and Python backend work together properly.

## Step 8: Deploy to Production

Deploy your working application to production:

```bash
vercel --prod
```

Visit the URL provided to see your live application!

## Part 2: Add Real-Time Streaming

Now let's enhance your app with real-time streaming and Markdown rendering.

### Install Markdown Libraries

```bash
npm install react-markdown remark-gfm remark-breaks
```

### Update the Frontend

Replace `pages/index.tsx` with:

```typescript
"use client"

import { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkBreaks from 'remark-breaks';

export default function Home() {
    const [idea, setIdea] = useState<string>('…loading');

    useEffect(() => {
        const evt = new EventSource('/api');
        let buffer = '';

        evt.onmessage = (e) => {
            buffer += e.data;
            setIdea(buffer);
        };
        evt.onerror = () => {
            console.error('SSE error, closing');
            evt.close();
        };

        return () => { evt.close(); };
    }, []);

    return (
        <main className="p-8 font-sans">
            <h1 className="text-3xl font-bold mb-4">
                Business Idea Generator
            </h1>
            <div className="w-full max-w-2xl p-6 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg shadow-md">
                <div className="prose prose-gray dark:prose-invert max-w-none">
                    <ReactMarkdown 
                        remarkPlugins={[remarkGfm, remarkBreaks]}
                    >
                        {idea}
                    </ReactMarkdown>
                </div>
            </div>
        </main>
    );
}
```

**Tailwind classes explained:**
- `prose`: Tailwind Typography plugin class that styles markdown content beautifully
- `w-full max-w-2xl`: Full width with a maximum width constraint
- `p-6`: Padding on all sides
- `bg-gray-50`: Light gray background
- `border border-gray-200`: Border with gray color
- `rounded-lg`: Rounded corners

**Note:** We still need `"use client"` at the top because we're making direct API calls from the browser to our Python FastAPI backend (rather than using Next.js as a middleman server).

### Install Tailwind Typography Plugin

The `prose` class requires the Typography plugin. Install it:

```bash
npm install @tailwindcss/typography
```

### Update the Backend for Streaming

Replace `api/index.py` with:

```python
from fastapi import FastAPI  # type: ignore
from fastapi.responses import StreamingResponse  # type: ignore
from openai import OpenAI  # type: ignore

app = FastAPI()

@app.get("/api")
def idea():
    client = OpenAI()
    prompt = [{"role": "user", "content": "Come up with a new business idea for AI Agents"}]
    stream = client.chat.completions.create(model="gpt-5-nano", messages=prompt, stream=True)

    def event_stream():
        for chunk in stream:
            text = chunk.choices[0].delta.content
            if text:
                lines = text.split("\n")
                for line in lines:
                    yield f"data: {line}\n"
                yield "\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")
```

### Test Streaming

Deploy and test your updated application:

```bash
vercel .
```

Visit the URL provided. You'll now see the AI response streaming in real-time with proper Markdown formatting!

## Part 3: Professional Styling

Let's make your app look professional with modern styling.

### Fix Markdown Rendering

First, we need to restore the default HTML styles that Tailwind removes. Add this to the bottom of your `styles/globals.css` file:

```css
@layer base {
  .markdown-content h1 {
    font-size: 2em;
    font-weight: bold;
    margin: 0.67em 0;
  }
  .markdown-content h2 {
    font-size: 1.5em;
    font-weight: bold;
    margin: 0.83em 0;
  }
  .markdown-content h3 {
    font-size: 1.17em;
    font-weight: bold;
    margin: 1em 0;
  }
  .markdown-content h4 {
    font-size: 1em;
    font-weight: bold;
    margin: 1.33em 0;
  }
  .markdown-content h5 {
    font-size: 0.83em;
    font-weight: bold;
    margin: 1.67em 0;
  }
  .markdown-content h6 {
    font-size: 0.67em;
    font-weight: bold;
    margin: 2.33em 0;
  }
  .markdown-content p {
    margin: 1em 0;
  }
  .markdown-content ul {
    list-style-type: disc;
    padding-left: 2em;
    margin: 1em 0;
  }
  .markdown-content ol {
    list-style-type: decimal;
    padding-left: 2em;
    margin: 1em 0;
  }
  .markdown-content li {
    margin: 0.25em 0;
  }
  .markdown-content strong {
    font-weight: bold;
  }
  .markdown-content em {
    font-style: italic;
  }
  .markdown-content hr {
    border: 0;
    border-top: 1px solid #e5e7eb;
    margin: 2em 0;
  }
}
```

### Update Your Backend Prompt

Update the prompt in `api/index.py` to request formatted output:

```python
prompt = [{"role": "user", "content": "Reply with a new business idea for AI Agents, formatted with headings, sub-headings and bullet points"}]
```

### Update Your Component

Now replace `pages/index.tsx` with:

```typescript
"use client"

import { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkBreaks from 'remark-breaks';

export default function Home() {
    const [idea, setIdea] = useState<string>('…loading');

    useEffect(() => {
        const evt = new EventSource('/api');
        let buffer = '';

        evt.onmessage = (e) => {
            buffer += e.data;
            setIdea(buffer);
        };
        evt.onerror = () => {
            console.error('SSE error, closing');
            evt.close();
        };

        return () => { evt.close(); };
    }, []);

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

**Professional Tailwind styling:**
- `min-h-screen`: Full viewport height
- `bg-gradient-to-br`: Beautiful gradient background with dark mode support
- `container mx-auto`: Centered container with responsive padding
- `text-5xl font-bold bg-gradient-to-r bg-clip-text text-transparent`: Gradient text effect for the heading
- `rounded-2xl shadow-xl backdrop-blur-lg`: Modern glassmorphism card effect
- `animate-pulse`: Loading animation while content streams
- `markdown-content`: Custom class that restores HTML styling for markdown

## Step 9: Deploy Final Version

Deploy your enhanced application:

```bash
vercel --prod
```

## Congratulations! 🎉

You've built a complete SaaS application with:
- ✅ Modern React frontend with Next.js Pages Router
- ✅ TypeScript for type safety
- ✅ FastAPI Python backend
- ✅ Real-time streaming AI responses
- ✅ Beautiful Markdown rendering
- ✅ Professional styling
- ✅ Production deployment on Vercel

## What You've Learned

- How to structure a full-stack application
- Building with Next.js Pages Router
- Understanding client-side rendering for API calls
- Creating API endpoints with FastAPI
- Implementing Server-Sent Events for streaming
- Rendering Markdown content in React
- Deploying full-stack apps to Vercel

## Understanding Pages Router Concepts

**Pages Router Structure:**
- Each file in `pages/` becomes a route
- `pages/index.tsx` → `/`
- `pages/product.tsx` → `/product`
- `pages/api/` → API routes (though we're using Python instead)

**Client-Side Rendering (`"use client"`):**
- Components marked with `"use client"` run primarily in the browser
- Can use React hooks (useState, useEffect)
- Perfect for dynamic, interactive UI
- We use this for all our pages since we're calling a Python backend

In this project, we used client-side components because we needed browser features for real-time streaming and connecting to our FastAPI backend.

## Next Steps

- Add a button to generate new ideas
- Store ideas in a database
- Add user authentication
- Create different idea categories
- Add a copy-to-clipboard feature
- Implement idea saving and sharing

## Troubleshooting

### "Module not found" errors
- Make sure you've installed all npm packages
- Try deleting `node_modules` and running `npm install` again

### API not responding
- Check that your OpenAI API key is set correctly
- Verify you have credits in your OpenAI account

### Streaming not working
- Some browsers block SSE on localhost - try a different browser
- Check the browser console for errors

### ESLint warnings
- ESLint helps catch potential issues in your code
- Yellow squiggly lines are warnings (code will still run)
- Red squiggly lines are errors (should be fixed)
- You can temporarily disable ESLint for a line with `// eslint-disable-next-line`
- Common warnings:
  - "React Hook useEffect has missing dependencies" - Usually safe to ignore for simple demos
  - "Unused variable" - Remove variables you're not using

### TypeScript errors
- Ensure all TypeScript packages are installed
- Restart your development server after installing types

### Deployment issues
- Make sure all files are saved before deploying
- Check that vercel.json is properly formatted
- Ensure your API key is added to Vercel environment variables