# AWS Copilot

AWS has a tool named copilot in [here](https://aws.github.io/copilot-cli/) that simplifies deploying containerized applications on AWS. It provides a simple CLI to create, release, and manage applications very similar to what Vercel does.
This guide is an alternative solution how we deploy in Week 1 day 5 and should be used once the students are comfortable with Docker and AWS concepts explained during Week1 day 5.
Using this method only need the application code used in Vercel, the Dockerfile and AWS account with proper permissions to create resources. All the infrastructure will be created by Copilot, IAM roles, App Runner services, secrects are created automatically by Copilot.

## Prerequisites

- Install the tool: https://github.com/aws/copilot-cli/
 - For mac users: `brew install aws/tap/copilot-cli`

## AWS Credentials

Make sure your AWS CLI is configured with the right credentials. You can do this by running `aws configure` and providing your AWS Access Key ID, Secret Access Key, region, and output format.

## How to use

1. Move to the project directory where your Dockerfile is located, e.g., `cd <SOME_PATH>/saas/`
2. Run `copilot init` and follow the prompts to set up your application. Important to select NO to the question "Would you like to deploy an environment?"
Here are the recommended answers after the ->:
   - Application name -> <APP_NAME>
   - Which workload type best represents your architecture? -> Request-Driven Web Service  (App Runner)
   - What do you want to name this service? -> <SERVICE_NAME>
   - Which Dockerfile would you like to use for <APP_NAME>? -> ./Dockerfile
   - Would you like to deploy an environment? -> **SELECT NO**

No problem, you can deploy your service later:
- Run `copilot env init` to create your environment.
- Run `copilot deploy` to deploy your service.
- Be a part of the Copilot ✨community✨!
  Ask or answer a question, submit a feature request...
  Visit 👉 https://aws.github.io/copilot-cli/community/get-involved/ to see how!

3. Initialize the environment, select your environment name and accept the defaultsin the same style and follow the prompts:
```bash
copilot env init
What is your environment's name? [? for help] -> <ENV_NAME>
Which credentials would you like to use to create <ENV_NAME>?  [Use arrows to move, type to filter, ? for more help]
> Enter temporary credentials
Environment name: <ENV_NAME>
Credential source: Enter temporary credentials
AWS Access Key ID: ****************HDY2
AWS Secret Access Key: ****************l/GB
AWS Session Token: ****************rnJ8
Default environment configuration? Yes, use default.
```
4. Deploy the service to the environment:
```bash
copilot env deploy --name <ENV_NAME>
- Creating the infrastructure for the saas123-saas123 environment.                     [update complete]  [69.5s]
  - An ECS cluster to group your services                                              [create complete]  [5.0s]
  - A security group to allow your containers to talk to each other                    [create complete]  [5.4s]
  - An Internet Gateway to connect to the public internet                              [create complete]  [16.8s]
  - A resource policy to allow AWS services to create log streams for your workloads.  [create complete]  [3.2s]
  - Private subnet 1 for resources with no internet access                             [create complete]  [3.7s]
  - Private subnet 2 for resources with no internet access                             [create complete]  [5.4s]
  - A custom route table that directs network traffic for the public subnets           [create complete]  [11.0s]
  - Public subnet 1 for resources that can access the internet                         [create complete]  [3.7s]
  - Public subnet 2 for resources that can access the internet                         [create complete]  [3.7s]
  - A private DNS namespace for discovering services within the environment            [create complete]  [46.6s]
  - A Virtual Private Cloud to control networking of your AWS resources                [create complete]  [12.4s]
```

## Secret Management

Using the command `copilot secret init` you can add secrets to your application. These secrets will be stored in AWS Systems Manager Parameter Store and will be made available to your application as environment variables. This is the safest way to manage sensitive information like API keys, database credentials, etc. Repeat the prompt for each secret you want to add.

```bash
copilot secret init
What would you like to name this secret? [? for help] -> CLERK_SECRET_KEY
What is the value of secret CLERK_SECRET_KEY1 in environment <ENV_NAME>? [? for help] ->**************************************************
...Put secret CLERK_SECRET_KEY to environment saas123
✔ Successfully put secret CLERK_SECRET_KEY in environment <ENV_NAME> as /copilot/<APP_NAME>/<ENV_NAME>/secrets/CLERK_SECRET_KEY.
You can refer to these secrets from your manifest file by editing the `secrets` section.
```

For each secret you add, you need to update the manifest file located at `copilot/<SERVICE_NAME>/manifest.yml` to include the secrets under the `secrets` section. Here is an example of how to add secrets to your manifest file:

```yaml
secrets:
  CLERK_SECRET_KEY: /copilot/<APP_NAME>/<ENV_NAME>/secrets/CLERK_SECRET_KEY
  ANOTHER_SECRET: /copilot/<APP_NAME>/<ENV_NAME>/secrets/ANOTHER_SECRET
```


## Modify the Dockerfile

You might need to hardcode the "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" in your Dockerfile for the deployment to work properly. Update your Dockerfile as follows:

```Dockerfile
#Build argument for Clerk public key
ARG NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=<YOUR_HARDCODED_KEY_HERE>
```


## Deploy the service

Finally, deploy your service to the environment using the following command:

```bash
copilot deploy app --all
```
