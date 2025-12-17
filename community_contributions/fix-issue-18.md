#%% md
# Clerk Logging Configuration Guide

This guide covers how to configure `CLERK_LOGGING` in your Clerk application, both through environment variables and programmatically.

## Overview

Clerk logging helps you debug and monitor authentication flows in your application. You can enable different levels of logging to see what's happening under the hood.

---

## Method 1: Using Environment Variables

### Setting in `.env` File

Create or edit your `.env.local` file (or `.env` file) in your project root:

```env
CLERK_LOGGING=true
```

### Log Levels

You can specify different log levels:

```env
# Enable all logging
CLERK_LOGGING=true

# Or specify a log level
CLERK_LOGGING=debug
CLERK_LOGGING=info
CLERK_LOGGING=warn
CLERK_LOGGING=error
```

### Platform-Specific Setup

#### Next.js

Add to `.env.local`:
```env
CLERK_LOGGING=true
```

The environment variable will be automatically picked up by Clerk.

#### Node.js/Express

Add to `.env`:
```env
CLERK_LOGGING=true
```
---

## Method 2: Programmatic Configuration

### Next.js (App Router)

```typescript
export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ClerkProvider
        {...pageProps}
        debug={true}
        telemetry={true}
    >
      <Component {...pageProps} />
    </ClerkProvider>
  );
}
```

## Log Levels Explained

| Level | Description |
|-------|-------------|
| `debug` | Most verbose - shows all logs including internal operations |
| `info` | General informational messages about normal operations |
| `warn` | Warning messages for potentially problematic situations |
| `error` | Only error messages |

---

## Best Practices

1. **Development**: Enable debug logging to see detailed information
   ```env
   CLERK_LOGGING=debug
   ```

2. **Production**: Disable or use error-level logging only
   ```env
   CLERK_LOGGING=error
   ```

3. **Security**: Never commit `.env` files with sensitive keys to version control


---

## Troubleshooting

### Logs Not Appearing

1. Verify the environment variable is loaded:
   ```javascript
   console.log(process.env.CLERK_LOGGING);
   ```

2. Check browser console (frontend) or terminal (backend)

3. Ensure you've restarted your development server after changing `.env` files

4. For Next.js, ensure you're using the correct prefix (`NEXT_PUBLIC_` for client-side)

### Too Many Logs

Reduce verbosity by changing the log level:
```env
CLERK_LOGGING=warn
```

Or disable completely:
```env
CLERK_LOGGING=false
```

---

## Additional Resources

- [Clerk Documentation](https://clerk.com/docs)
- [Environment Variables Best Practices](https://clerk.com/docs/deployments/clerk-environment-variables)
- [Debugging Guide](https://clerk.com/docs/debugging)
