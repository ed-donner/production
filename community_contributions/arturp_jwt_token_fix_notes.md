# Issue description

The original implementation of long-running Server-Sent Events (SSE) had an issue where the connection would break after a JWT token expired. Clerk.com’s default JWT tokens have a 60-second expiration. This caused a 403 Forbidden error when the backend API and LLM communication exceeded this time, leading to a permanent failure and a broken user experience.

# Fix description

This fix introduces robust token refresh and connection management logic to prevent session failures. The updated process seamlessly handles expired tokens by automatically re-establishing the SSE connection with a new JWT, ensuring an uninterrupted user experience.

Enhancements include::

1. **Error Handling**: The code now specifically detects **403 Forbidden** errors in the `onopen` and `onerror` callbacks.
2. **Automatic Reconnection**: Upon a 403 error, the system automatically calls  `connectWithFreshToken()` to obtain a new JWT and reconnect.
3. **Clean Connection Management**: Uses `AbortController` to gracefully terminate the existing connection before initiating a new one.
4. **Concurrency Control**: `isConnecting` flag prevents multiple, simultaneous reconnection attempts.
5. **Token Refresh**: Each reconnection cycle fetches a new, valid JWT using `getToken()`.

Handling token expiration flow:
```
Token expires → 403 error → Detect in onopen/onerror → Abort current connection → Get fresh token → Reconnect
```

This ensures seamless user experience even during extended sessions where tokens expire.