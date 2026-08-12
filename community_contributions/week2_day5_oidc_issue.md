# Fix AWS OIDC Failure Caused by GitHub's July 2026 `sub` Change

## Problem

GitHub Actions fails with:

```text
Could not assume role with OIDC:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

If this started happening on a new repository after GitHub's **July 2026 OIDC update**, the likely cause is that GitHub changed the format of the OIDC `sub` claim.

Older AWS trust policies often expect:

```text
repo:USERNAME_HERE/REPO_NAME_HERE:*
```

But GitHub may now send:

```text
repo:USERNAME_HERE@71346630/REPO_NAME_HERE@1331753531:environment:dev
```

The `@...` values are immutable GitHub owner and repository IDs introduced as part of GitHub's 2026 OIDC hardening.

## 1. Check the actual `sub`

Temporarily add this in `./scripts/deploy.yaml` between the `Checkout code` and `configure-aws-credentials` steps:

```yaml
- name: Inspect GitHub OIDC token
  uses: actions/github-script@v7
  with:
    script: |
      const token = await core.getIDToken('sts.amazonaws.com')
      const payload = JSON.parse(
        Buffer.from(token.split('.')[1], 'base64url').toString()
      )

      console.log('sub:', payload.sub)
```

Run the workflow and copy the exact `sub`.

Example:

```text
repo:nicofilizzola@71346630/mlops-course-twin@1331753531:environment:dev
```

## 2. Update the AWS trust policy

1. Go to **IAM** in the AWS console.
2. Go to **Access Management** > **Roles**.
3. Open your github actions role. It should be named `github-actions-twin-deploy`.
4. Go to **Trust relationships**.

Replace the old `sub` condition:

```json
"token.actions.githubusercontent.com:sub":
  "repo:nicofilizzola/mlops-course-twin:*"
```

with the new immutable format, supporting all environments:

```json
"token.actions.githubusercontent.com:sub": [
  "repo:nicofilizzola@71346630/mlops-course-twin@1331753531:environment:dev",
  "repo:nicofilizzola@71346630/mlops-course-twin@1331753531:environment:test",
  "repo:nicofilizzola@71346630/mlops-course-twin@1331753531:environment:prod"
]
```

## 3. Re-run the workflow

The numeric IDs are stable identifiers, not workflow-run IDs, so they can be safely used in the AWS trust policy.

## In conclusion

The fix is simply:

> Inspect the real GitHub OIDC `sub` and update the AWS trust relationship to match the new immutable format.
