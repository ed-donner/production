# Week4 Exercise


## Summary
Applied context engineering and todo tracking to the Financial Planner Orchestrator Agent.

## Changes

- Extended `PlannerContext` with todo tracking methods `mark_complete()`, `mark_failed()`, `is_done()`, and `todo_status()` to prevent duplicate Lambda invocations across tool calls.

- Updated all three invoke tools to guard against duplicate calls and return `todo_status()` inline so the agent always knows what's left.

- Added `get_todo_status` tool for checking progress without triggering a Lambda call.

- Added `get_planner_instructions()` to embed portfolio summary and agent conditions directly in the system prompt.

# Links

[Changes made to backend/planner ](https://github.com/nsikanikpoh/planner.git)

[Service URL](https://dr2e6eecawq19.cloudfront.net)


