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
        let controller: AbortController | null = null;
        let isConnecting = false;

        const connectWithFreshToken = async () => {
            if (isConnecting) return;
            isConnecting = true;

            try {
                // Abort any existing connection
                if (controller) {
                    controller.abort();
                }
                controller = new AbortController();

                const jwt = await getToken();
                if (!jwt) {
                    setIdea('Authentication required');
                    isConnecting = false;
                    return;
                }

                console.log('Connecting with fresh token...');

                await fetchEventSource('/api', {
                    headers: { Authorization: `Bearer ${jwt}` },
                    signal: controller.signal,
                    onmessage(ev) {
                        console.log('Received message:', ev.data);
                        buffer += ev.data;
                        setIdea(buffer);
                    },
                    onerror(err) {
                        console.error('SSE onerror called:', err);
                        isConnecting = false;

                        // Handle 403 errors by reconnecting with fresh token
                        if (err instanceof Response && err.status === 403) {
                            console.log('Token expired in onerror, reconnecting...');
                            buffer = '';
                            setIdea('Refreshing connection...');
                            setTimeout(() => connectWithFreshToken(), 1000);
                            return;
                        }

                        console.log('Non-403 error, letting fetchEventSource handle it');
                    },
                    onopen: async (response) => {
                        console.log('SSE onopen called, status:', response.status);

                        if (response.ok) {
                            console.log('SSE connection opened successfully');
                            isConnecting = false;
                        } else if (response.status === 403) {
                            console.log('403 detected in onopen, triggering reconnect');
                            isConnecting = false;
                            // Manually trigger reconnect for 403
                            buffer = '';
                            setIdea('Refreshing connection...');
                            setTimeout(() => connectWithFreshToken(), 1000);
                            throw new Error('Authentication failed - triggering reconnect');
                        } else {
                            console.log('Non-403 error in onopen:', response.status);
                            isConnecting = false;
                            throw new Error(`HTTP ${response.status}`);
                        }
                    },
                    onclose() {
                        console.log('SSE connection closed');
                        isConnecting = false;
                    }
                });
            } catch (error) {
                console.error('Failed to connect:', error);
                isConnecting = false;

                // Only show connection failed if not manually aborted
                if (!controller?.signal.aborted) {
                    // If it's a network error, try to reconnect a few times
                    if (error instanceof TypeError || (error instanceof Error && error.message?.includes('fetch'))) {
                        console.log('Network error, retrying...');
                        setTimeout(() => connectWithFreshToken(), 2000);
                    } else {
                        setIdea('Connection failed. Please refresh the page.');
                    }
                }
            }
        };

        connectWithFreshToken();

        // Cleanup function
        return () => {
            if (controller) {
                controller.abort();
            }
        };
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
