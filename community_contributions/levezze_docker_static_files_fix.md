# FastAPI + Next.js Static Export: Routing Issues and Solutions

This document outlines issues encountered when serving a Next.js static export through FastAPI in a Docker container, along with their solutions.

## Issue 1: Missing Environment Variable Loading

### Problem

The FastAPI server (`api/server.py`) was attempting to access environment variables using `os.getenv()`, but these variables were not being loaded from the `.env` file. This caused the application to fail when trying to configure Clerk authentication.

### Solution

Add explicit `.env` file loading at the top of `server.py`:

```python
from dotenv import load_dotenv

load_dotenv(".env.local")
```

This ensures that environment variables from `.env.local` (or `.env`) are loaded into the process before any configuration code runs.

## Issue 1.5: Type Safety and Error Handling

### Problem

Two type-related issues were encountered:

1. `os.getenv()` can return `None`, which caused type checking issues when passing values to libraries expecting strings
2. The OpenAI chat completion messages parameter needed explicit type hints for proper validation

### Solution

Add proper null checks and type hints:

```python
# Add null check for environment variables
clerk_jws = os.getenv("CLERK_JWKS_URL")
if not clerk_jws:
    raise ValueError("Couldn't get Clerk JWS URL")
```

```python
# Add explicit type hint for OpenAI messages
from openai.types.chat import ChatCompletionMessageParam

prompt: list[ChatCompletionMessageParam] = [
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": user_prompt},
]
```

## Issue 2: Next.js Static Pages Not Being Served

### Problem

When building Next.js with `output: "export"` and serving the static files through FastAPI, navigation to routes like `/product` resulted in 404 errors, despite the corresponding `product.html` file existing in the `static` directory.

### Symptoms

```
INFO: 172.17.0.1:37862 - "GET /product HTTP/1.1" 404 Not Found
INFO: 172.17.0.1:37862 - "GET /_next/data/[build-id]/product.json HTTP/1.1" 404 Not Found
```

The home page (`/`) worked correctly, but any other routes failed.

### Root Cause

The original code had two conflicting approaches:

1. An explicit route for `/`:
   ```python
   @app.get("/")
   async def serve_root():
       return FileResponse(static_path / "index.html")
   ```

2. A catch-all StaticFiles mount:
   ```python
   app.mount("/", StaticFiles(directory="static", html=True), name="static")
   ```

When both are present, FastAPI's routing priority means the explicit route takes precedence, and the `StaticFiles` mount with `html=True` doesn't properly handle requests for routes like `/product`.

Additionally, Next.js client-side routing (using `<Link>` components) attempts to fetch JSON data files from `/_next/data/[build-id]/[page].json`. These files don't exist in static exports, causing the navigation to fail before falling back to full page loads.

### What We Tried

1. **Removing the explicit `/` route**: We commented out the explicit root route handler to let StaticFiles handle all routes. However, `StaticFiles(directory="static", html=True)` still didn't properly serve `product.html` at `/product`.

2. **Using `html=True` parameter**: While this parameter should theoretically make StaticFiles serve `product.html` when `/product` is requested, it has known issues when mounted at the root path `/`.

### Solution

Replace the `StaticFiles` mount with an explicit catch-all route that handles Next.js static export patterns:

```python
# Serve static files (our Next.js export) - MUST BE LAST!
static_path = Path("static")
if static_path.exists():
    # Mount _next directory for Next.js assets
    app.mount("/_next", StaticFiles(directory="static/_next"), name="next-static")

    # Catch-all route for HTML pages
    @app.get("/{full_path:path}")
    async def serve_static_or_spa(full_path: str):
        # Handle root path
        if full_path == "":
            return FileResponse(static_path / "index.html")

        # Try exact file match first (for .svg, .ico, etc)
        file_path = static_path / full_path
        if file_path.is_file():
            return FileResponse(file_path)

        # Try with .html extension for Next.js pages
        html_path = static_path / f"{full_path}.html"
        if html_path.is_file():
            return FileResponse(html_path)

        # Try index.html in directory
        index_path = static_path / full_path / "index.html"
        if index_path.is_file():
            return FileResponse(index_path)

        # Fallback to 404 or index for SPA routing
        return FileResponse(static_path / "404.html", status_code=404)
```

### Why This Works

1. **Separate `/_next` mount**: Next.js assets (JS, CSS, etc.) are served directly from the `/_next` directory, which works reliably with `StaticFiles`.

2. **Explicit path resolution**: The catch-all route explicitly checks for files in this order:
   - Exact file match (handles static assets like `.svg`, `.ico`)
   - File with `.html` extension (handles Next.js pages like `product.html` for `/product`)
   - `index.html` in a directory (handles directory-based routes)
   - 404 fallback

3. **Proper Next.js static export pattern**: Next.js static exports create `product.html`, `about.html`, etc., and this solution correctly maps `/product` → `product.html`.

## Docker Build Considerations

When making changes to `api/server.py`, remember to rebuild the Docker image:

```bash
# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Rebuild the image
docker build \
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" \
  -t consultation-app .

# Run the container
docker run -p 8000:8000 \
  -e CLERK_SECRET_KEY="$CLERK_SECRET_KEY" \
  -e CLERK_JWKS_URL="$CLERK_JWKS_URL" \
  -e OPENAI_API_KEY="$OPENAI_API_KEY" \
  consultation-app
```

## Additional Notes

### Common Pitfall: `.env` File with Trailing Space

During debugging, we discovered the `.env` file was actually named `.env ` (with a trailing space). This caused `cat .env` to fail with "No such file or directory" even though the file existed.

**Solution**: Rename the file to remove the trailing space:
```bash
mv ".env " .env
```

**Prevention**: Use `ls -la | cat -A` to show invisible characters in filenames.

## Summary

The key issues were:
1. Missing `.env` file loading in the FastAPI server
2. Lack of type safety checks for environment variables
3. FastAPI's `StaticFiles` with `html=True` not properly serving Next.js static exports when mounted at `/`

The solution involves:
1. Explicitly loading environment variables with `python-dotenv`
2. Adding null checks and type hints for safety
3. Implementing a custom catch-all route that properly handles Next.js static export file patterns

This approach provides reliable routing for Next.js static exports served through FastAPI, handling both direct navigation and static assets correctly.
