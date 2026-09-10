from bedrock_agentcore import BedrockAgentCoreApp
from strands import Agent, tool
from strands.models import BedrockModel
import math

MODEL_ID="us.amazon.nova-micro-v1:0"
MODEL_REGION="us-west-2"

@tool
def take_square_root(input_number: float):
    """Calculate the square root of the given number"""
    return str(math.sqrt(input_number))

app = BedrockAgentCoreApp()
model = BedrockModel(model_id=MODEL_ID, region_name=MODEL_REGION)
agent = Agent(model=model, tools=[take_square_root])

@app.entrypoint
def invoke(payload):
    """Make a simple call to a Strands Agent"""
    user_message = payload.get("prompt")
    result = agent(user_message)
    return result.message

if __name__ == "__main__":
    app.run()