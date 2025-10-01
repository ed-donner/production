# Issue description

When using amazon.nova-lite-v1:0, amazon.nova-pro-v1:0 or amazon.nova-micro-v1:0 as the BEDROCK_MODEL_ID, the lambda function will return an error: 'Invalid message format for bedrock'.

Using cloudwatch the following error can be found:
```Bedrock validation error: An error occurred (ValidationException) when calling the Converse operation: Invocation of model ID amazon.nova-lite-v1:0 with on-demand throughput isn’t supported. Retry your request with the ID or ARN of an inference profile that contains this model.```

In Amazon Bedrock under 'Model access' we can see that the Nova models can only be used through an inference profile by clikcing on 'Cross-region inference' next to the models.

# Fix description

Use the inference profile ARN or ID instead of the model ID.
Example: 
```dotenv
BEDROCK_MODEL_ID=arn:aws:bedrock:us-east-1:<yourawsaccountid>:inference-profile/us.amazon.nova-lite-v1:0
```
or
```dotenv
BEDROCK_MODEL_ID=us.amazon.nova-lite-v1:0
```

When not using BEDROCK_MODEL_ID in your .env make sure to change the default value in server.py
