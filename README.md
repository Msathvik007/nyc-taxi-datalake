# nyc-taxi-datalake

Infrastructure-as-code and pipeline code for the NYC Taxi Data Lake project.

## Structure
- `terraform/`: AWS infrastructure (S3, Glue, Lambda, Step Functions, Redshift Serverless, EventBridge/SNS)
- `glue/`: Glue job scripts (A/B/C)
- `lambdas/`: Lambda functions (quality gates + Redshift runner)

## Branching
- `main`: stable releases
- `dev`: active development (open PRs into `dev`, then `dev` → `main`)
