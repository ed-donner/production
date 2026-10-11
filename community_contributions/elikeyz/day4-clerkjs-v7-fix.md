# Day 4: Healthcare Consultation Assistant

## Build a Professional Healthcare Application

Today, you'll transform your SaaS into a healthcare consultation assistant that helps doctors generate patient summaries, action items, and patient-friendly emails from their visit notes.

## What You'll Build

A healthcare application that:

- Takes doctor's consultation notes as input
- Generates professional summaries for medical records
- Creates actionable next steps for the doctor
- Drafts patient-friendly email communications
- Uses structured forms with date pickers
- Streams AI-generated content in real-time

## Prerequisites

- Completed Day 3 (authentication and subscriptions working)
- Your app deployed to Vercel

## Step 1: Install Additional Dependencies

We need a date picker for the consultation form:

```bash
npm install react-datepicker
npm install --save-dev @types/react-datepicker
```

## Step 2: Update the Backend API

Replace `api/index.py` with a new endpoint that handles consultation data:

```python
import os
from fastapi import FastAPI, Depends  # type: ignore
from fastapi.responses import StreamingResponse  # type: ignore
from pydantic import BaseModel  # type: ignore
from fastapi_clerk_auth import ClerkConfig, ClerkHTTPBearer, HTTPAuthorizationCredentials  # type: ignore
from openai import OpenAI  # type: ignore

app = FastAPI()
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


@app.post("/api")
def consultation_summary(
    visit: Visit,
    creds: HTTPAuthorizationCredentials = Depends(clerk_guard),
):
    user_id = creds.decoded["sub"]  # Available for tracking/auditing
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
```

Note the key changes:

- Changed from `@app.get("/api")` to `@app.post("/api")` to accept form data
- Added a `Visit` model to validate incoming data
- Structured prompts for healthcare-specific output

## Step 3: Update Application Configuration

First, import the date picker styles in `pages/_app.tsx`:

```tsx
import { ClerkProvider } from '@clerk/nextjs';
import type { AppProps } from 'next/app';
import 'react-datepicker/dist/react-datepicker.css';
import '../styles/globals.css';

export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ClerkProvider {...pageProps}>
      <Component {...pageProps} />
    </ClerkProvider>
  );
}
```

Now update `pages/_document.tsx` to reflect the healthcare focus:

```tsx
import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
  return (
    <Html lang="en">
      <Head>
        <meta name="description" content="AI-powered medical consultation summaries" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
```

## Step 4: Create the Consultation Form

Replace `pages/product.tsx` with the new healthcare interface:

```tsx
"use client"

import { useState, FormEvent } from 'react';
import { Show, useAuth } from '@clerk/nextjs';
import DatePicker from 'react-datepicker';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkBreaks from 'remark-breaks';
import { fetchEventSource } from '@microsoft/fetch-event-source';
import { PricingTable, UserButton } from '@clerk/nextjs';
import Head from 'next/head';

function ConsultationForm() {
    const { getToken } = useAuth();

    // Form state
    const [patientName, setPatientName] = useState('');
    const [visitDate, setVisitDate] = useState<Date | null>(new Date());
    const [notes, setNotes] = useState('');

    // Streaming state
    const [output, setOutput] = useState('');
    const [loading, setLoading] = useState(false);

    async function handleSubmit(e: FormEvent) {
        e.preventDefault();
        setOutput('');
        setLoading(true);

        const jwt = await getToken();
        if (!jwt) {
            setOutput('Authentication required');
            setLoading(false);
            return;
        }

        const controller = new AbortController();
        let buffer = '';

        await fetchEventSource('/api', {
            signal: controller.signal,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${jwt}`,
            },
            body: JSON.stringify({
                patient_name: patientName,
                date_of_visit: visitDate?.toISOString().slice(0, 10),
                notes,
            }),
            onmessage(ev) {
                buffer += ev.data;
                setOutput(buffer);
            },
            onclose() {
                setLoading(false);
            },
            onerror(err) {
                console.error('SSE error:', err);
                controller.abort();
                setLoading(false);
            },
        });
    }

    return (
        <div className="container mx-auto px-4 py-12 max-w-3xl">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-8">
                Consultation Notes
            </h1>

            <form onSubmit={handleSubmit} className="space-y-6 bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
                <div className="space-y-2">
                    <label htmlFor="patient" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Patient Name
                    </label>
                    <input
                        id="patient"
                        type="text"
                        required
                        value={patientName}
                        onChange={(e) => setPatientName(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                        placeholder="Enter patient's full name"
                    />
                </div>

                <div className="space-y-2">
                    <label htmlFor="date" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Date of Visit
                    </label>
                    <DatePicker
                        id="date"
                        selected={visitDate}
                        onChange={(d: Date | null) => setVisitDate(d)}
                        dateFormat="yyyy-MM-dd"
                        placeholderText="Select date"
                        required
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                    />
                </div>

                <div className="space-y-2">
                    <label htmlFor="notes" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                        Consultation Notes
                    </label>
                    <textarea
                        id="notes"
                        required
                        rows={8}
                        value={notes}
                        onChange={(e) => setNotes(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                        placeholder="Enter detailed consultation notes..."
                    />
                </div>

                <button
                    type="submit"
                    disabled={loading}
                    className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white font-semibold py-3 px-6 rounded-lg transition-colors duration-200"
                >
                    {loading ? 'Generating Summary...' : 'Generate Summary'}
                </button>
            </form>

            {output && (
                <section className="mt-8 bg-gray-50 dark:bg-gray-800 rounded-xl shadow-lg p-8">
                    <div className="markdown-content prose prose-blue dark:prose-invert max-w-none">
                        <ReactMarkdown remarkPlugins={[remarkGfm, remarkBreaks]}>
                            {output}
                        </ReactMarkdown>
                    </div>
                </section>
            )}
        </div>
    );
}

export default function Product() {
    return (
        <>
            <Head>
                <title>Healthcare Consultation Assistant</title>
            </Head>
            <main className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800">
                {/* User Menu in Top Right */}
                <div className="absolute top-4 right-4">
                    <UserButton showName={true} />
                </div>

                {/* Subscription Protection */}
                <Show
                    when={{ plan: 'premium_subscription' }}
                    fallback={
                        <div className="container mx-auto px-4 py-12">
                            <header className="text-center mb-12">
                                <h1 className="text-5xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-4">
                                    Healthcare Professional Plan
                                </h1>
                                <p className="text-gray-600 dark:text-gray-400 text-lg mb-8">
                                    Streamline your patient consultations with AI-powered summaries
                                </p>
                            </header>
                            <div className="max-w-4xl mx-auto">
                                <PricingTable />
                            </div>
                        </div>
                    }
                >
                    <ConsultationForm />
                </Show>
            </main>
        </>
    );
}
```

## Step 5: Update the Landing Page

Update `pages/index.tsx` to reflect the healthcare focus:

```tsx
"use client"

import Link from 'next/link';
import { Show, SignInButton, UserButton } from '@clerk/nextjs';
import Head from 'next/head';

export default function Home() {
  return (
    <>
      <Head>
          <title>Healthcare Consultation Assistant</title>
      </Head>
      <main className="min-h-screen bg-linear-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800">
        <div className="container mx-auto px-4 py-12">
          {/* Navigation */}
          <nav className="flex justify-between items-center mb-12">
            <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-200">
              MediNotes Pro
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
                  <UserButton showName={true} />
                </div>
              </Show>
            </div>
          </nav>

          {/* Hero Section */}
          <div className="text-center py-16">
            <h2 className="text-6xl font-bold bg-linear-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-6">
              Transform Your
              <br />
              Consultation Notes
            </h2>
            <p className="text-xl text-gray-600 dark:text-gray-400 mb-12 max-w-2xl mx-auto">
              AI-powered assistant that generates professional summaries, action items, and patient communications from your consultation notes
            </p>

            {/* Features Grid */}
            <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto mb-12">
              <div className="relative group">
                <div className="absolute inset-0 bg-linear-to-r from-blue-600 to-cyan-600 rounded-xl blur opacity-25 group-hover:opacity-40 transition duration-300"></div>
                <div className="relative bg-white dark:bg-gray-800 p-6 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 backdrop-blur-sm">
                  <div className="text-3xl mb-4">📋</div>
                  <h3 className="text-lg font-semibold mb-2 text-gray-900 dark:text-gray-100">Professional Summaries</h3>
                  <p className="text-gray-600 dark:text-gray-400 text-sm">
                    Generate comprehensive medical record summaries from your notes
                  </p>
                </div>
              </div>
              <div className="relative group">
                <div className="absolute inset-0 bg-linear-to-r from-emerald-600 to-green-600 rounded-xl blur opacity-25 group-hover:opacity-40 transition duration-300"></div>
                <div className="relative bg-white dark:bg-gray-800 p-6 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 backdrop-blur-sm">
                  <div className="text-3xl mb-4">✅</div>
                  <h3 className="text-lg font-semibold mb-2 text-gray-900 dark:text-gray-100">Action Items</h3>
                  <p className="text-gray-600 dark:text-gray-400 text-sm">
                    Clear next steps and follow-up actions for every consultation
                  </p>
                </div>
              </div>
              <div className="relative group">
                <div className="absolute inset-0 bg-linear-to-r from-purple-600 to-pink-600 rounded-xl blur opacity-25 group-hover:opacity-40 transition duration-300"></div>
                <div className="relative bg-white dark:bg-gray-800 p-6 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 backdrop-blur-sm">
                  <div className="text-3xl mb-4">📧</div>
                  <h3 className="text-lg font-semibold mb-2 text-gray-900 dark:text-gray-100">Patient Emails</h3>
                  <p className="text-gray-600 dark:text-gray-400 text-sm">
                    Draft clear, patient-friendly email communications automatically
                  </p>
                </div>
              </div>
            </div>

            <Show when="signed-out">
              <SignInButton mode="modal">
                <button className="bg-linear-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                  Start Free Trial
                </button>
              </SignInButton>
            </Show>
            <Show when="signed-in">
              <Link href="/product">
                <button className="bg-linear-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-bold py-4 px-8 rounded-xl text-lg transition-all transform hover:scale-105">
                  Open Consultation Assistant
                </button>
              </Link>
            </Show>
          </div>

          {/* Trust Indicators */}
          <div className="text-center text-sm text-gray-500 dark:text-gray-400">
            <p>HIPAA Compliant • Secure • Professional</p>
          </div>
        </div>
      </main>
    </>
  );
}
```

## Step 6: Update Backend Dependencies

Make sure `requirements.txt` includes Pydantic for data validation:

```txt
fastapi
uvicorn
openai
fastapi-clerk-auth
pydantic
```

## Step 7: Deploy Your Healthcare App

Deploy your transformed application:

```bash
vercel --prod
```

## Step 8: Test the Consultation Flow

1. Visit your production URL
2. Sign in with your account
3. Navigate to the consultation form
4. Try entering sample consultation notes:

**Example Input:**

- **Patient Name:** Jane Smith
- **Date:** Today's date
- **Notes:**

  ```txt
  Patient presents with persistent cough for 2 weeks. No fever.
  Chest clear on examination. Blood pressure 120/80.
  Likely viral bronchitis. Prescribed rest and fluids.
  Follow up if symptoms persist beyond another week.
  ```

You'll receive:

1. A professional summary for medical records
2. Clear next steps for the doctor
3. A patient-friendly email draft

## What's Happening?

Your healthcare app now:

- **Accepts structured input**: Form data with patient name, date, and notes
- **Validates data**: Using Pydantic models on the backend
- **Generates structured output**: Three distinct sections for different purposes
- **Maintains security**: All data is transmitted with JWT authentication
- **Supports subscriptions**: Only premium users can access the tool

## Architecture Changes from Day 3

1. **POST instead of GET**: The API now accepts form data via POST requests
2. **Structured prompts**: System and user prompts guide the AI output format
3. **Form validation**: Both frontend (required fields) and backend (Pydantic) validation
4. **Date handling**: Proper date picker with ISO format conversion
5. **Professional UI**: Healthcare-focused design with clear sections

## Security Considerations

**Important:** This is a demonstration application. For production healthcare use:

- Implement proper HIPAA compliance measures
- Add data encryption at rest and in transit
- Implement audit logging for all access
- Add role-based access control (doctor vs admin)
- Ensure proper data retention policies
- Add patient consent management

## Troubleshooting

### "Method not allowed" error

- Make sure the API endpoint uses `@app.post("/api")` not `@app.get("/api")`
- Verify the fetch request uses `method: 'POST'`

### Date picker not styled correctly

- Ensure `react-datepicker/dist/react-datepicker.css` is imported in `pages/_app.tsx`
- Check that the date picker has the correct className for Tailwind styling

### Form data not sending

- Check browser console for errors
- Verify all required fields are filled
- Ensure the JWT token is being retrieved successfully

### Output not formatting correctly

- Make sure the markdown-content styles are applied (from Day 2)
- Verify ReactMarkdown plugins are imported

## Customization Ideas

### Add More Fields

```typescript
// Add specialty selection
const [specialty, setSpecialty] = useState('General Practice');

// Add urgency level
const [urgency, setUrgency] = useState<'routine' | 'urgent' | 'emergency'>('routine');
```

### Enhanced Templates

Create different prompt templates for different specialties:

```python
def get_system_prompt(specialty: str) -> str:
    prompts = {
        "cardiology": "Focus on cardiac symptoms and cardiovascular health...",
        "pediatrics": "Use child-friendly language in patient communications...",
        "psychiatry": "Include mental health considerations and resources..."
    }
    return prompts.get(specialty, system_prompt)
```

### Export Options

Add buttons to export the generated content:

```typescript
const handleExportPDF = () => {
    // Generate PDF from markdown
};

const handleCopyEmail = () => {
    // Copy email section to clipboard
};
```

## Next Steps

Congratulations! You've built a professional healthcare consultation assistant with:

- ✅ Structured medical data input
- ✅ AI-powered content generation
- ✅ Professional and patient-friendly outputs
- ✅ Secure authentication and subscriptions
- ✅ Modern, accessible UI

### Potential Enhancements

1. **Template library**: Pre-built templates for common conditions
2. **Voice input**: Dictation support for notes
3. **Multi-language**: Support for patient emails in different languages
4. **Integration**: Connect with EHR systems
5. **Analytics**: Track consultation patterns and time saved
6. **Collaboration**: Allow multiple doctors to share templates

Your healthcare assistant is ready to help medical professionals save time and improve patient communication!
