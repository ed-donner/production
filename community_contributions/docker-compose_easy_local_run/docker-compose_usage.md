# Docker Compose for easier local deployment and testing

* No need to preload terminal session with env vars, docker compose will get them from
  the `.env` file.

## Add image name to dockerfile

To be able to aim docker compose to the right image we should add a name to the final
image on our `Dockerfile`:

Change:

```dockerfile
FROM python:3.13-slim
```

To:

```dockerfile
FROM python:3.13-slim as backend
```

## Writing your `docker-compose` file from terminal commands

* `docker build` arguments goes to `build` entry on the service:

  ```sh
  docker build \
    --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="$NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" \
    -t consultation-app .
  ```

  Becomes:

  ```yml
  build:
    context: .                    # Same period at the end of the command. (Current folder)
    target: backend               # Dockerfile target image for multistage ones.
    args:                         # Same one as on the command line.
      - NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY}
  image: consultation-app         # Same as on the command line.
  ```

* `docker run` ones goes to the service entry itself:

  ```sh
  docker run -p 8000:8000 \
    -e CLERK_SECRET_KEY="$CLERK_SECRET_KEY" \
    -e CLERK_JWKS_URL="$CLERK_JWKS_URL" \
    -e OPENAI_API_KEY="$OPENAI_API_KEY" \
    consultation-app
  ```

  Becomes:

  ```yml
  backend:
    container_name: SaaS_Backend  # Your preferred name so you don't get random ones.
    build:
      ...                         # See above.
    image: consultation-app       # Same as on the command line.
    environment:                  # Same ones as on the command line.
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - CLERK_JWKS_URL=${CLERK_JWKS_URL}
      - CLERK_SECRET_KEY=${CLERK_SECRET_KEY}
    ports:                        # Same one as on the command line.
      - "8000:8000"
    restart: on-failure
    platform: linux/amd64         # Ensure image creation for the right architecture.
  ```

  *No matter you are running on a ARM MAC, it should work on emulation out of the box,
  otherwise, well...\
  maybe MACs are not that "fully compatible" as they claim.* 😉

## Build and run your service locally on one single command

This command will build and run your service on your local docker engine.\
*(Run it on the same folder)*

```sh
docker compose up -d --build
```

* With the `--build` flag it will build the image if not already build or it detects
  changes on files, then it will run it locally on your docker engine.

* The `-d` flag detaches execution, so your return back yo your terminal while the service
  runs in background. Remove it if you prefer your terminal stick attached to the service
  and see logs there.

If your `.env` file is not located on the same folder use the `--env-file` flag.\
*(Recommended for safety, specially if you use AI agents that read your whole workspace)*

```sh
docker compose --env-file path_to_env_file/.env up -d --build
```

To stop down your service just run:

```sh
docker compose down
```
