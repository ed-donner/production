# Welcome back to the Production Repo!

## And welcome to the AWS Bedrock AgentCore Finale

![Course Image](../assets/finale.png)

_If you're looking at this in Cursor, please right click on the filename in the Explorer on the left, and select "Open preview", to view it in formatted glory._

### Step 1: IAM (groan)

You're all pros now, so you get pro-level instructions!

1. Sign in to the AWS console as your root user
2. Go to IAM and User Groups
3. Create a new User Group called "AgentAccess"
4. Add it to user aiengineer
5. Attach policies: `AmazonBedrockFullAccess`, `AWSCodeBuildAdminAccess`, `BedrockAgentCoreFullAccess`

Also as of today: you'd need to have access to Claude Sonnet 4 model in us-west-2.

#### Now sign in as your IAM user.

1. Navigate to AWS Bedrock AgentCore
2. Select Observability in the sidebar
3. Select the option to turn this on - I have an option to only enable the free tier, which I chose

And save.

### Step 2: reading assignment

The main Amazon Bedrock AgentCore landing page:  
https://aws.amazon.com/bedrock/agentcore/

The user guide, examples and reference:  
https://aws.github.io/bedrock-agentcore-starter-toolkit/index.html

And more links as FYI:

The AgentCore Python SDK:  
https://github.com/aws/bedrock-agentcore-sdk-python

The AgentCore Starter Toolkit (CLI):  
https://github.com/aws/bedrock-agentcore-starter-toolkit  

### Step 3 - introducing the uv project in this folder

I have added just a few dependencies to this project:  
- bedrock-agentcore
- strands-agents
- bedrock-agentcore-starter-toolkit
- pydantic

So if you do a `cd finale` and then `uv sync` you will have all those packages installed.

### Step 4 - making your first agent

Make a new file in this directory called `first.py`

Put in this code:

```python
from bedrock_agentcore import BedrockAgentCoreApp
from strands import Agent, tool
import math

app = BedrockAgentCoreApp()
agent = Agent()

@app.entrypoint
def invoke(payload):
    """Make a simple call to a Strands Agent"""
    user_message = payload.get("prompt")
    result = agent(user_message)
    return result.message

if __name__ == "__main__":
    app.run()
```

Now run this to test the server locally:

`uv run first.py`

Leave this server running, and open a new Terminal in Cursor, and send in a message:

`curl -X POST http://localhost:8080/invocations -H "Content-Type: application/json" -d '{"prompt": "Hello can you hear me??"}'`

Or on a Windows PC if you don't have curl:

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/invocations" -Method Post -Headers @{ "Content-Type" = "application/json" } -Body '{"prompt": "Hello can you hear me??"}'
```

### Step 5 - deploy!

Here is the big command - but also please see the super-valuable heads up from student Andy C. below.

`uv run agentcore configure -e first.py`  
and pick all the defaults.

NOTE FROM ANDY C.:

> My default aws region is set for "us-east-2" but the Claude model we're using is only available in "us-west-2". This caused a number of different errors when trying to deploy the AgentCore suite. This can easily be corrected with a flag that points to the model's region:  
> `uv run agentcore configure -e first.py --region us-west-2`  
> Once I did that, everything in the AgentCore lesson went without a hitch. It was so fun and easy!


After you run the command (my one, or use Andy's flag if your Bedrock is in a different region):  

`uv run agentcore launch`

And then...

`uv run agentcore invoke '{"prompt": "Hello can you hear me??"}'`

Goodness! Do you realize everything that happened:  
- AgentCore built a container
- AgentCore deployed it to ECR
- AgentCore set up all the IAM
- AgentCore deployed something like App Runner
- AgentCore sent it a message

It's like a Week, in a Minute!!

### Step 6 - AND NOW - tools with Strands

Add this to the top of first.py, under the imports but above the variable assignments:

```python
@tool
def take_square_root(input_number: float):
    """Calculate the square root of the given number"""
    return str(math.sqrt(input_number))
```

And change `agent = Agent()` to `agent = Agent(tools=[take_square_root])`

And then:

`uv run agentcore launch`

`uv run agentcore invoke '{"prompt": "Use your tool to calculate the square root of 1234567 to 3 decimal places"}'`

That's tool use!!

### Step 7 ###

And now - a new, more powerful agent - the looper!

First, delete `first.py` - we can only have 1 python module with an entrypoint.

Create `looper.py` with this contents:

```python
from bedrock_agentcore import BedrockAgentCoreApp
from strands import Agent, tool
from typing import List
from pydantic import BaseModel, Field


app = BedrockAgentCoreApp()


class ToDoItem(BaseModel):
    description: str = Field(..., description="The text describing the task")
    completed: bool = Field(False, description="Whether the task is complete")


todos = []

system_prompt = """
You are given a problem to solve, by using your todo tools to plan a list of steps, then carrying out each step in turn.
Now use the todo list tools, create a plan, carry out the steps, and reply with the solution.
"""

def get_todo_report() -> str:
    """Get a report of all todos."""
    result = ""
    for index, todo in enumerate(todos):
        completed = "X" if todo.completed else " "
        start = "[strike][green]" if todo.completed else ""
        end = "[/strike][/green]" if todo.completed else ""
        result += f"Todo #{index + 1}: [{completed}] {start}{todo.description}{end}\n"
    return result


@tool
def create_todos(descriptions: List[str]) -> str:
    """Add new todos from a list of descriptions and return the full list"""
    for desc in descriptions:
        todos.append(ToDoItem(description=desc))
    return get_todo_report()


@tool
def mark_complete(index: int) -> str:
    """Mark complete the todo at the given position (starting from 1) and return the full list"""
    if 1 <= index <= len(todos):
        todos[index - 1].completed = True
    else:
        return "No todo at this index."
    return get_todo_report()


@tool
def list_todos() -> str:
    """Return the full list of todos with completed ones checked off"""
    return get_todo_report()


tools = [create_todos, mark_complete, list_todos]
agent = Agent(system_prompt=system_prompt, tools=tools)


@app.entrypoint
async def invoke(payload):
    """Our Agent function"""
    user_message = payload.get("prompt")
    stream = agent.stream_async(user_message)
    async for event in stream:
        if "data" in event:
            yield event["data"]  # Stream data chunks
        elif "message" in event:
            yield "\n" + get_todo_report()


if __name__ == "__main__":
    app.run()

```

`uv run agentcore configure -e looper.py`

Pick all the defaults. Then:

`uv run agentcore launch`

And then...

`uv run agentcore invoke '{"prompt": "A train leaves Boston at 2:00 pm traveling 60 mph. Another train leaves New York at 3:00 pm traveling 80 mph toward Boston. When do they meet?"}'`

How cool is that?!

### Step 8: Add Code Interpreter

Under the imports, add this:

```python
from bedrock_agentcore.tools.code_interpreter_client import CodeInterpreter
import json

code_client = CodeInterpreter("us-west-2")

@tool
def execute_python(code: str) -> str:
    """Execute Python code in the code interpreter."""
    response = code_client.invoke("executeCode", {"language": "python", "code": code})
    output = []
    for event in response["stream"]:
        if "result" in event and "content" in event["result"]:
            content = event["result"]["content"]
            output.append(content)
    return json.dumps(output[-1])
```

Update the system prompt:

```python
system_prompt = """
You are given a problem to solve, by using your todo tools to plan a list of steps, then carrying out each step in turn.
You also have access to an execute_python tool to run Python.
Your plan should include solving the problem without Python, then writing and executing Python code to validate your solution.
To use the execute_python tool to validate your solution, you must have a task on your todo list prefixed with "Write Python code to...".
Now use the todo list tools, create a plan, carry out the steps, and reply with the solution.
"""
```

Update the print method to highlight coding tasks:

```python
def get_todo_report() -> str:
    """Get a report of all todos."""
    result = ""
    for index, todo in enumerate(todos):
        completed = "X" if todo.completed else " "
        start = "[strike][green]" if todo.completed else ""
        end = "[/strike][/green]" if todo.completed else ""
        start += "[red]" if "python" in todo.description.lower() else ""
        end += "[/red]" if "python" in todo.description.lower() else ""
        result += f"Todo #{index + 1}: [{completed}] {start}{todo.description}{end}\n"
    return result
```

And the final step - change the line that sets to tools to add the new tool:

`tools = [create_todos, mark_complete, list_todos, execute_python]`

And now:

`uv run agentcore launch`

And then...

`uv run agentcore invoke '{"prompt": "A train leaves Boston at 2:00 pm traveling 60 mph. Another train leaves New York at 3:00 pm traveling 80 mph toward Boston. When do they meet?"}'`

What fun!

### Step 9: Observability

1. Go back to AWS Console as your IAM user
2. Go to the Amazon Bedrock AgentCore service
3. Select Observability on the left
4. Examine your agents, sessions and traces
5. I'm intrigued to see how it retried with throttling issues, explaining why it was so slow..

## AND THAT'S IT! Agent deployment in minutes.

Your assignment: keep going! How about adding a NextJS frontend, add the other tool (browser automation), make this into a full personal Sidekick!

