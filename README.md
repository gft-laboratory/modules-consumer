# Consumer modules

This repository is responsible to consuming definition modules to build data lake solution.

We've divided the code into distinct modules for better navigation and customization. The modules include:

- `DMS`: Sub-module responsible for provisioning replication instances, source and target endpoints, and migration tasks using AWS Database Migration Service.
- `DynamoDB`: Sub-module for creating non-relational tables used by the application.
- `Glue`: Sub-module responsible for provisioning AWS Glue resources such as databases, tables, jobs, connections, and triggers for data cataloging and ETL processing.
- `IAM-Policy`: Sub-module for creating and optionally attaching custom or managed IAM policies to existing roles.
- `IAM-Role`: Sub-module for creating IAM roles with custom trust policies, used by services like Lambda, Glue, and others.
- `KMS`: Sub-module for creating and managing AWS KMS keys for encrypting data across services like S3, DynamoDB, Secrets Manager, and more.
- `Lambda`: Sub-module responsible for provisioning AWS Lambda functions, including runtime, handler, environment variables, and permissions.
- `RDS-AuroraGlobal`: Sub-module to provision Amazon Aurora Global Database clusters, supporting cross-region replication and high availability for PostgreSQL workloads.
- `S3`: Sub-module for creating private buckets to store application-related objects.
- `SecretsManager`: Sub-module for securely storing sensitive values such as credentials, tokens, and secrets using AWS Secrets Manager.
- `SecurityGroup`: Sub-module for creating customized Security Groups with configurable ingress and egress rules.

Keep in mind, this guide and the corresponding modules are continuously being improved. 

## Usage
Variables/locals are values ​​that are used several times in various parts of the code, it is recommended that these variables be declared at the top of the file.

## How to use. Example:

See [`main.tf`](./main.tf)