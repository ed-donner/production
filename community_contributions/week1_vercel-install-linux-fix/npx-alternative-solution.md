# Alternative Solution for Vercel CLI Installation on Ubuntu 26.04

## Issue

When following the Day 1 tutorial and running the command:
```bash
npm install -g vercel
```

On Ubuntu 26.04, I encountered the following error:

```
npm ERR! code EACCES
npm ERR! syscall mkdir
npm ERR! path /usr/local/lib/node_modules
npm ERR! errno -13
npm ERR! Error: EACCES: permission denied, mkdir '/usr/local/lib/node_modules'
```

This is a common permission issue when trying to install global npm packages on Linux systems.

## Solution

Instead of using `npm install -g vercel`, I used `npx vercel` which bypasses the global installation issue:

```bash
npx vercel
```

This command will:
1. Prompt you to install the vercel package if it's not already installed
2. Run the vercel CLI without requiring global installation
3. Avoid the permission issues associated with global npm packages

## Example Output

```
Need to install the following packages:
  vercel@54.21.1
Ok to proceed? (y) y
npm WARN deprecated stream-to-promise@2.2.0: Deprecated. Use node:stream/promises and node:stream/consumers instead.
npm WARN deprecated tar@7.5.7: Old versions of tar are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
Vercel CLI 54.21.1 (Node.js 22.22.1)
> NOTE: The Vercel CLI now collects telemetry regarding usage of the CLI.
> This information is used to shape the CLI roadmap and prioritize features.
> You can learn more, including how to opt-out if you'd not like to participate in this program, by visiting the following URL:
> https://vercel.com/docs/cli/about-telemetry
> No existing credentials found. Please log in:
> 
  Visit vercel.com/device and enter QPNP-WTXQ
```

## Additional Notes

- This solution works on Ubuntu 26.04, but should be applicable to other Linux distributions as well
- Using `npx` is generally a good practice for CLI tools that you don't use frequently
- If you prefer to use the global installation method, you can fix the permissions issue by:
  1. Using `sudo npm install -g vercel` (not recommended for security reasons)
  2. Changing npm's default directory to a user-writable location (see [npm documentation](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally))

## System Information

- OS: Ubuntu 26.04
- Node.js version: 22.22.1
- npm version: (not specified)

---

Contributed by: Ebrahim Mousavi