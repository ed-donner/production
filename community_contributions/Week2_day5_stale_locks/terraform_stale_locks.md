## Destroy scripts and stale locks
When running terraform destroy scripts it is possible to encounter stale state locks.
Here is a modified version of destroy.sh created by a helpful AI companion.

The script should work on GitHub Actions. Adding the AWS region environment variables to the workflow (as in deploy) for consistency:

This will work on GitHub Actions. Here's why:
Bash compatibility: GitHub Actions uses bash by default, so PIPESTATUS works
Standard tools: Ubuntu runners include grep, sed, tee, and zip
File paths: /tmp/ exists on Ubuntu runners
Environment variables: The workflow now sets the required AWS variables
The script will:
Detect lock errors from Terraform output
Extract the lock ID using sed (works on Linux)
Force unlock stale locks automatically
Retry the destroy operation
The changes are ready to use. When you run the destroy workflow on GitHub Actions, it will automatically handle stale state locks