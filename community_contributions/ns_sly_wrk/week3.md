# Week3 Exercise


## Summary
Applied context engineering and a todo tracking tool to the Alex Researcher agent.

## Changes

- Added `compress_for_context()` to cap analysis at 2000 chars before storing to prevent context window overflow.

- Updated `ingest_financial_document` to return type from `Dict` to `str` — returns a minimal confirmation string so the agent does not re-read its own output back into the context window.

- Added `update_todo` tool to allow the agent to explicitly mark each research step as complete, failed, or skipped, reducing the chance of repeated or out-of-order work.

- Updated the `context.py` to include a todo template and integrated with `get_agent_instructions()`. 

- Updated the `server.py` to sync with the updated `tools.py`.

# Changes GitHub Repo link

[Changes made to backend/researcher ](https://github.com/nsikanikpoh/researcher.git)

[Service URL](https://syjmf28xcn.us-east-1.awsapprunner.com)


