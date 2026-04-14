# Week2 Exercise


## Summary
Organized S3 storage into prefixed folders and added two background tools to the 
Bedrock integration.

## Changes

- Added `conversations/`, `contacts/`, and `unanswered/` S3 prefixes for cleaner storage organization.
- Added `save_contact` tool — captures visitor name and email automatically when shared in conversation.
- Added `save_unanswered_question` tool — flags and stores questions outside the model's context for human follow-up.

# AWS App Runner deployment and GitHub Repo link

[My Digital Twin](https://d2tqpaebctwtf9.cloudfront.net//)

[GitHub Link](https://github.com/nsikanikpoh/ai-saas-idea.git)

[API Gateway](https://kuojtbwv61.execute-api.us-east-1.amazonaws.com/)
