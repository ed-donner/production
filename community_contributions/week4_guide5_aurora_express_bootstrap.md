# Guide 5: Aurora Serverless v2 on Free-Tier AWS Accounts

**By Prodhi Manisha**

---

## Summary

On March 25, 2026, AWS launched Aurora PostgreSQL Express Configuration and simultaneously restricted free-tier accounts so they can only create Aurora clusters via that path. Guide 5's `terraform apply` creates the cluster using `aws_rds_cluster`, which calls `CreateDBCluster` without `WithExpressConfiguration=True`. Free-tier accounts get back:

```
InvalidParameterCombination: Free Tier accounts must use Express Configuration
```

This is not a permissions problem, a region mismatch, or a misconfigured `terraform.tfvars`. The Terraform `hashicorp/aws` provider does not expose `WithExpressConfiguration` at all (tracking issue filed March 26, 2026, the day after launch). The core blocker is architectural: `create-db-cluster --with-express-configuration` creates both a cluster and a writer instance in a single API call, which does not map to Terraform's one-resource-per-state model.

This fix replaces the three incomplete shell scripts in `bootstrap/` with two idempotent Python scripts that handle the full cluster lifecycle outside Terraform, then feed the cluster ARN back into Terraform state via `bootstrap.auto.tfvars.json`. All downstream modules (Guide 6 agents, Guide 7 frontend) are unchanged: they read the same outputs from `terraform/5_database/`.

The code is submitted as a PR to [ed-donner/alex](https://github.com/ed-donner/alex). If it has not been merged yet, the working branch is at [prodm93/alex: aurora-express-bootstrap](https://github.com/prodm93/alex/tree/aurora-express-bootstrap) and you can copy the files directly from there.

---

## Design Tension: Cluster State Lives Outside Terraform

Naming this directly: the Aurora cluster is not in Terraform state. That is the necessary consequence of the Terraform provider limitation. The mitigation is `bootstrap.auto.tfvars.json`, a file written by `setup_aurora_express.py` that Terraform auto-loads (Terraform loads all `*.auto.tfvars.json` files automatically, no configuration required). The variable `aurora_cluster_arn` in `variables.tf` carries `default = ""`, which lets the first `terraform apply` run before the cluster exists to create the Secrets Manager secret and IAM role; the second `terraform apply` at the end of the setup script picks up the now-populated ARN and records it in outputs.

One consequence of the cluster being outside Terraform state: `terraform destroy` in `terraform/5_database/` will delete the secret and IAM role but not the cluster. The correct teardown order is `destroy_aurora_express.py` first, then `terraform destroy`. This is called out explicitly in the script output and in the instructions below.

One intentional IAM scope change to disclose: the original `aws_iam_role_policy` scoped `rds-data:ExecuteStatement` and related actions to the cluster ARN. Since the cluster ARN does not exist at first-apply time, the policy now uses `"*"` for `rds-data` actions. Access is still bounded: the `secretsmanager:GetSecretValue` action is scoped to the specific secret ARN, so the Lambda role can only authenticate against the correct credentials.

---

## What the Setup Script Does

`bootstrap/setup_aurora_express.py` is idempotent and safe to re-run. It checks existing state before each step.

| Step | Action |
|------|--------|
| 1 | `terraform init + apply` in `terraform/5_database/`: creates Secrets Manager secret and IAM role |
| 2 | Creates the Aurora Express cluster via `CreateDBCluster(WithExpressConfiguration=True)` |
| 3 | Enables the Data API via `enable_http_endpoint()` |
| 4 | Sets the cluster master password to match the Terraform-generated secret; applies scaling config |
| 5 | Creates the `alex` database |
| 6 | Writes `terraform/5_database/bootstrap.auto.tfvars.json` with the cluster ARN |
| 7 | `terraform apply` again to record the cluster ARN in state and outputs |

---

## Student Instructions

### 1. Configure Terraform variables

Copy `terraform/5_database/terraform.tfvars.example` to `terraform.tfvars` as usual. You only need `aws_region`. The `aurora_cluster_arn` line has been removed from the example: the bootstrap script handles it.

```hcl
aws_region = "us-east-1"
```

### 2. Run the setup script

```bash
cd bootstrap
uv run setup_aurora_express.py
```

Total runtime is roughly 5 to 8 minutes. The script prints each step as it goes.

### 3. Continue with Guide 5 as written

From this point the Terraform outputs are populated correctly. Run the database setup from `backend/database/` as the guide instructs:

```bash
uv run test_data_api.py
uv run run_migrations.py
uv run seed_data.py
uv run verify_database.py
```

### 4. Destroy the cluster when not working

Aurora charges while running. When you are done for the day:

```bash
cd bootstrap
uv run destroy_aurora_express.py
```

The script prompts for confirmation, starts the cluster if it has auto-paused, deletes the writer instance, deletes the cluster, removes `bootstrap.auto.tfvars.json`, and runs a final `terraform apply` to clear the ARN from state. Aurora takes a final automated backup before deletion completes: expect 15 to 30 minutes. The secret and IAM role are kept in place so `setup_aurora_express.py` can recreate the cluster from scratch when you need it again.

### 5. Adjusting capacity (optional)

Aurora Express defaults to `MinCapacity=0.0` (auto-pause when idle) and `MaxCapacity=4.0`. These are no longer Terraform variables. Edit the constants at the top of `setup_aurora_express.py` and re-run the script to apply:

```python
MIN_CAPACITY = 0.0   # 0.0 enables auto-pause; raise to prevent cold starts
MAX_CAPACITY = 4.0   # raise for heavier workloads
```

---

## Notable Design Decisions

**`enable_http_endpoint()` vs `modify_db_cluster(enable_http_endpoint=True)`.** These are two different API calls and are not interchangeable on Serverless v2. The `EnableHttpEndpoint` parameter on `modify_db_cluster` works only for Serverless v1. On a Serverless v2 cluster it silently does nothing: the request succeeds, the Data API remains disabled, and subsequent Data API calls fail with `HttpEndpointNotEnabledException`. The correct call for Serverless v2 is the dedicated `enable_http_endpoint()` operation. The script uses that.

**`modify_db_cluster` retry with tenacity.** After `enable_http_endpoint()` completes, the cluster can briefly accept a status of "available" while still rejecting `modify_db_cluster` with `InvalidDBClusterStateFault`. The script uses tenacity `Retrying` on `rds.exceptions.InvalidDBClusterStateFault` (the typed boto3 exception, not string-matching on the error message) with exponential backoff and a 5-minute stop. Each retry re-runs the availability waiter before attempting the modify.

**`DatabaseErrorException` guard in `rds_execute`.** After `modify_db_cluster(MasterUserPassword=...)`, PostgreSQL can take 30 to 60 seconds to pick up the new credential after the cluster reports "available". The Data API returns `DatabaseErrorException` with `password authentication failed` during that window. `DatabaseErrorException` also wraps genuine SQL errors (bad table name, syntax errors), so the retry does not trigger on the error code alone: it only retries when the error message contains a known transient phrase. Genuine SQL errors still raise immediately.

**Secret ARN is preserved across cluster rebuilds.** The Secrets Manager secret is Terraform-managed and is not touched by `destroy_aurora_express.py`. Guide 6 Lambda functions reference the secret ARN in their environment variables. Recreating the secret would change the ARN and break those functions without a re-deploy. The bootstrap destroy/setup cycle rebuilds only the cluster, leaving the secret in place.

---

## Known Limitations

**`terraform destroy` does not destroy the cluster.** Run `destroy_aurora_express.py` before `terraform destroy` if you want to fully tear down Guide 5 infrastructure. Running `terraform destroy` first leaves an orphaned cluster that continues to charge.

**Scaling is not Terraform-managed.** `min_capacity` and `max_capacity` are constants in `setup_aurora_express.py`, not Terraform variables. Changing them requires editing the script and re-running it.

**Auto-pause cold starts in production.** `MinCapacity=0.0` enables auto-pause, which is appropriate for development. The first request after idle hits a 15 to 30 second resume delay. `DataAPIClient` in `backend/database/src/client.py` handles this transparently with tenacity retry on `DatabaseResumingException` and `BadRequestException: Communications link failure`. If you raise `MinCapacity` to `0.5` or above, auto-pause is disabled and cold starts do not occur; the cluster runs continuously and incurs ACU charges at rest.

---

## Future Path

When `hashicorp/aws` adds `WithExpressConfiguration` support: reintroduce `aws_rds_cluster` in `terraform/5_database/main.tf`, restore `min_capacity` and `max_capacity` as Terraform variables, delete `bootstrap.auto.tfvars.json`, and retire the bootstrap scripts. The Secrets Manager secret, IAM role, database schema, and all downstream modules (Guide 6, Guide 7) are unchanged and require no migration.

---

## Files Changed

**bootstrap/ (replaces three shell scripts):**
- `setup_aurora_express.py`: 7-step idempotent cluster setup
- `destroy_aurora_express.py`: cluster teardown with confirmation prompt
- `pyproject.toml`: uv project; dependencies: `boto3`, `tenacity`
- Deleted: `create_express_cluster.sh`, `destroy_express_cluster.sh`, `wait_for_cluster.sh`

**terraform/5_database/:**
- `main.tf`: removed `aws_rds_cluster`; `rds-data` IAM policy scoped to `"*"`
- `variables.tf`: removed `min_capacity`, `max_capacity`; `aurora_cluster_arn` gets `default = ""`
- `outputs.tf`: outputs read from `var.aurora_cluster_arn` instead of resource attribute
- `terraform.tfvars.example`: simplified; `aurora_cluster_arn` removed

**backend/database/:**
- `pyproject.toml`: added `tenacity>=9.1.2`
- `src/client.py`: tenacity retry on `execute()` and `begin_transaction()` for auto-pause resume

---

## References

- [AWS announcement: Aurora PostgreSQL now on Free Tier, March 25, 2026](https://aws.amazon.com/about-aws/whats-new/2026/03/amazon-aurora-postgresql-aws-free-tier)
- [AWS docs: Aurora Free Tier restrictions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-free-tier.html)
- [AWS docs: Create with Express Configuration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_GettingStartedAurora.AuroraPostgreSQL.ExpressConfig.html)
- [Terraform provider tracking issue for WithExpressConfiguration](https://github.com/hashicorp/terraform-provider-aws/issues)
