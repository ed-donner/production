# Finale: AgentCore Region Mismatch and Permissions Fix

**I really cannot recommend this enough: use `us-west-2` as your default AWS region for the entire finale project.** Most of the issues below stem from running the AgentCore runtime in a different region (in my case `sa-east-1`) while the models, inference profiles, and code interpreter all live in `us-west-2`. Switching to `us-west-2` from the start eliminates every single permissions issue described here.

**If you really don't want to change your default region to `us-west-2` or still keep hitting issues regardless**, scroll down below for fixes to try/what worked for me!

## What went wrong

When you run `uv run agentcore launch`, the CLI creates an IAM execution role with an auto-generated inline policy scoped to whatever region you deploy in. If your default region is anything other than `us-west-2`, three things break:

1. **Inference profile access**: the auto-generated policy covers `arn:aws:bedrock:<your-region>:<account>:*` but cross-region inference profiles (like `us.amazon.nova-micro-v1:0`) resolve to `arn:aws:bedrock:us-west-2:<account>:inference-profile/...`. Your policy does not match that ARN.

2. **Code interpreter access**: the `CodeInterpreter("us-west-2")` client calls `bedrock-agentcore` APIs in `us-west-2`, but the auto-generated role has no `bedrock-agentcore:StartCodeInterpreterSession` or related actions at all; those are not included by default.

3. **IAM user vs. execution role shenanigans**: even if your IAM user has `AmazonBedrockFullAccess` via a user group, that does not help. AgentCore assumes a separate execution role at runtime. Your user's permissions are irrelevant to what the container can do. The separation is common for AWS services, but it creates a whole slew of odd permission errors when it comes to AgentCore deployment.

## The fixes:

### Step 1: Set deployment region

First, set the Bedrock AgentCore **deployment region** by running:

```bash
uv run agentcore configure -e first.py --region us-west-2
```

or, for the second part of finale using `looper.py`:

```bash
uv run agentcore configure -e looper.py --region us-west-2
```  

This is the same fix as Andy C. had originally proposed, and it rides along with the additional fixes outlined below.

### Step 2: Run patched code (set model inference profile regions and IDs)

Next, run the updated versions of `first.py` and `looper.py` which:
- explicitly set the model *inference profile region* to `us-west-2`
- explicitly use inference profiles rather than foundation (or default behind-the-scenes) model IDs
    - If you are using Claude Sonnet 4.6 (or other newer Bedrock foundation models), simply changing the runtime region is not enough. These models can no longer be invoked directly using their foundation model IDs

Of note, Claude Sonnet 4--the model used by default for this course--has been sunset, and many model IDs listed via AgentCore's endpoints have been sunset and are unusable. I'd highly recommend using the latest model releases, if possible.

If you already created a runtime in another region, delete `.bedrock_agentcore.yaml` by running `rm .bedrock_agentcore.yaml` and re-run `uv run agentcore launch` targeting `us-west-2`. The CLI will scaffold a fresh role, ECR repo, and runtime.

#### What changed in the code:

The original course code relies on Strands' default Agent() configuration. That no longer works reliably for newer Bedrock models because the runtime will attempt to use the default region and foundation model IDs.

##### `first.py`

###### 1. Import `BedrockModel`

Change:

```python
from strands import Agent, tool
```

to:

```python
from strands import Agent, tool
from strands.models import BedrockModel
```

###### 2. Define the model configuration

Add:

```python
MODEL_ID = "us.amazon.nova-micro-v1:0"
MODEL_REGION = "us-west-2"
```

(or another inference profile of your choice).

###### 3. Replace the default agent

Replace:

```python
app = BedrockAgentCoreApp()
agent = Agent()
```

or (if you've already reached the tools section):

```python
app = BedrockAgentCoreApp()
agent = Agent(tools=[take_square_root])
```

with:

```python
app = BedrockAgentCoreApp()

model = BedrockModel(
    model_id=MODEL_ID,
    region_name=MODEL_REGION,
)

agent = Agent(
    model=model,
    tools=[take_square_root],
)
```

##### `looper.py`

###### 1. Import `BedrockModel`

Add:

```python
from strands.models import BedrockModel
```

###### 2. Define the model configuration

Near the top of the file add:

```python
MODEL_ID = "us.amazon.nova-pro-v1:0"
MODEL_REGION = "us-west-2"
```

Nova Pro performed substantially better than Nova Micro for multi-step tool use during testing.

###### 3. Replace the default agent

Replace:

```python
tools = [create_todos, mark_complete, list_todos, execute_python]
agent = Agent(system_prompt=system_prompt, tools=tools)
```

with:

```python
tools = [create_todos, mark_complete, list_todos, execute_python]

model = BedrockModel(
    model_id=MODEL_ID,
    region_name=MODEL_REGION,
)

agent = Agent(
    model=model,
    system_prompt=system_prompt,
    tools=tools,
)
```

###### 4. Update the system prompt (optional)

I also had noticeably better results after changing the final line of the system prompt from:

```text
Now use the todo list tools, create a plan, carry out the steps, and reply with the solution.
```

to:

```text
Now use the todo list tools, create a plan, carry out the steps, and reply with the solution. You must carry out all plans sequentially. Do not skip steps.
```

This isn't required for deployment, but it noticeably reduced the model skipping planned tool calls.

### Step 3: Add code interpreter permissions

In this step, you will need to manually patch the auto-generated IAM role's inline policy to add code interpreter permissions for `looper.py`. The role is named something like `AmazonBedrockAgentCoreSDKRuntime-<region>-<hash>`. You can find it by running the following CLI command:

```bash
aws iam list-roles --query "Roles[?starts_with(RoleName,'AmazonBedrockAgentCoreSDKRuntime')].[RoleName]" --output text
```

Attach these as a separate inline policy by running the following two CLI commands (**replace `<region>-<hash>` with the suffix from your actual role name.**):

**Command 1:**
```bash
aws iam put-role-policy \
    --role-name AmazonBedrockAgentCoreSDKRuntime-<region>-<hash> \
    --policy-name AllowCodeInterpreter \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": [
                "bedrock-agentcore:CreateCodeInterpreter",
                "bedrock-agentcore:StartCodeInterpreterSession",
                "bedrock-agentcore:InvokeCodeInterpreter",
                "bedrock-agentcore:StopCodeInterpreterSession",
                "bedrock-agentcore:GetCodeInterpreterSession",
                "bedrock-agentcore:ListCodeInterpreterSessions"
            ],
            "Resource": "arn:aws:bedrock-agentcore:us-west-2:aws:code-interpreter/aws.codeinterpreter.v1"
        }]
    }'
```


**Command 2:**
```bash
aws iam put-role-policy \
    --role-name AmazonBedrockAgentCoreSDKRuntime-<region>-<hash> \
    --policy-name AllowStartCodeInterpreterSession \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": "bedrock-agentcore:StartCodeInterpreterSession",
            "Resource": "arn:aws:bedrock-agentcore:us-west-2:aws:code-interpreter/aws.codeinterpreter.v1"
        }]
    }'
```

## On model choices

Much to my chagrin, I was prompted to sign a formal usage agreement with Anthropic through Bedrock AgentCore to be able to use Claude for this project. I couldn't be fussed and decided to opt for open-source models to circumvent this roadblock entirely; however, not all alternative options are created equally.

### Nova Micro and reasoning: not recommended

Nova Micro (and to a lesser extent other smaller Nova models) emits `<thinking>...</thinking>` tags as literal text when given tool-use instructions in the system prompt. This is not the native Bedrock extended thinking API; the model is writing chain-of-thought directly into its text output.

Beyond the cosmetic issue, the deeper problem is that Nova Micro with reasoning enabled is still not capable enough to use tools reliably. It will spend tokens on lengthy reasoning blocks and then fail to actually invoke the tools correctly: skipping steps, creating duplicate todo items, or abandoning the tool-use flow entirely and narrating what it "would have done." Disabling reasoning removes the noise, but does not fix the underlying tool-use quality.

**Recommendation**: use Nova Pro (`us.amazon.nova-pro-v1:0`) for this project. It handles multi-step tool-use competently without producing spurious thinking blocks. The cost difference is negligible for a learning exercise.

If you do want to venture out and suppress reasoning on a smaller model, you can disable it at the API level (I haven't tried this and shudder to think about the generated output):

```python
model = BedrockModel(
    model_id=MODEL_ID,
    region_name=MODEL_REGION,
    additional_request_fields={
        "reasoningConfig": {
            "type": "disabled"
        }
    }
)
```

This stops the `<thinking>` tags from appearing but does not improve the model's ability to follow through on tool calls.

## LLaMA models: don't use 'em

LLaMA models are incompatible with streaming functionality and throw errors right away. Not recommended for this project.

## Why this happened

These are generally conjectures/informed guesses. There are a few plausible reasons, but without AWS stating it explicitly, it's impossible to know which is correct:

- Inference profiles became mandatory for models like Claude Sonnet 4. Previously you could invoke the foundation model directly; now you have to invoke an inference profile. It is possible that AWS changed inference profile ARN semantics between late 2025 and mid 2026; profiles are now account-owned resources (`arn:aws:bedrock:<region>:<account>:inference-profile/...`) rather than global foundation model ARNs (`arn:aws:bedrock:*::foundation-model/...`). The auto-generated policy was written for the old pattern.
- The auto-generated AgentCore execution role appears not to include permissions for inference profile ARNs and Code Interpreter. Whether that's a regression, an SDK bug, or simply because AgentCore assumes a different deployment pattern isn't obvious.
- The course and tooling assume us-west-2. Once you start deploying from another default region like sa-east-1, you expose cross-region assumptions that the generated IAM policy doesn't account for.

## Links

- [Strands Agents: Amazon Bedrock model provider docs](https://strandsagents.com/docs/user-guide/concepts/model-providers/amazon-bedrock/)
- [AgentCore Code Interpreter: getting started and IAM permissions](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/code-interpreter-getting-started.html)
- [AgentCore runtime IAM permissions](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-permissions.html)
- [LibreChat issue on Nova thinking tags with tool-use](https://github.com/danny-avila/LibreChat/issues/9833)
