# Issue description

I was trying to access **Bedrock Nova Lite** from **ap-south-1** region i.e. Mumbai but facing below issue as reported in **Cloudwatch**

`Bedrock validation error: An error occurred (ValidationException) when calling the Converse operation: Invocation of model ID amazon.nova-lite-v1:0 with on-demand throughput isn’t supported. Retry your request with the ID or ARN of an inference profile that contains this model.`

# Fix description

That error usually happens when you try to call an Amazon Bedrock model directly by its model ID (like amazon.nova-lite-v1:0) without going through an inference profile.

For some Bedrock models—especially foundation models like Amazon Nova—on-demand throughput is not supported. Instead, you must invoke them using an inference profile ARN that has the correct provisioning.

As a solution, I performed below steps and it worked for me.

1. Go to **Bedrock** -> **Infer** -> **Cross-region inference**.

2. Make sure you're at your desired region i.e ap-south-1 in my case.

3. Search `Model = Nova Lite` under Inference profiles.

4. Copy the `Inference profile ID` or `Inference profile ARN` from the result for Nova Lite.

5. Edit the Lambda Environment variables and paste it to `BEDROCK_MODEL_ID`.
