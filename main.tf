locals {
  region            = "us-east-2"
  vpc_id            = "vpc-0200956108a7c9a91"
  vpc_glue_id       = "vpc-0200956108a7c9a91"
  private_subnet_id = "subnet-0b7874098e6995a22"
}



module "dynamodb" {
  source = "git::https://github.com/gft-laboratory/modules-shared.git//DynamoDB?ref=v0.0.1"

  table_name         = "my-dynamoDB"
  partition_key_name = "PartitionKey01"
  partition_key_type = "S"
  # Optional
  stream_enabled      = true
  stream_view_type    = "KEYS_ONLY" # Valid values: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES
  kinesis_stream_name = "my-dynamoDB-kinesis-stream"

  tags_dynamodb = { 
    Environment = var.environment
    Name        = "my-dynamoDB"
  }
}



module "s3_shared" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/S3?ref=v0.0.1"

  bucket_name          = "bucket-shared-${data.aws_caller_identity.current.account_id}-${local.region}"
  create_bucket_policy = true
  bucket_policy        = templatefile("${path.module}/json_policy/bucket_policy.json.tmpl", {
    bucket_arn = module.s3_shared.bucket_arn
})

  kms_key_id          = module.kms_shared.key_id

  enable_versioning   = false 
  enable_notification = false
  create_lifecycle    = false


  tags_bucket = {
    Terraform = "true"
    Name = "bucket-shared-${data.aws_caller_identity.current.account_id}-${local.region}"
  }

  depends_on = [
    module.kms_shared
  ]
}



module "kms_shared" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/KMS?ref=v0.0.1"

  alias                   = "kms_default"
  description             = "Key used for encryption"
  enable_key_rotation     = true
  is_enabled              = true
  deletion_window_in_days = 7
  tags = {
    Terraform = "true"
  }
}



module "shared_iam_role" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/IAM-Roles?ref=v0.0.1"

  name               = "shared-role-service"
  assume_role_policy = file("./json_role/shared_assume_role.json")
  tags_iam_role      = {
    Terraform        = "true"
  }
}



module "shared_iam_policies" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/IAM-Policy?ref=v0.0.1"

  policy_name                     = "shared_custom_policy"
  policy_description              = "Custom policy to shared Service"
  policy_path                     = "/"
  role_attach_policy_managed_name = module.shared_iam_role.iam_role_name
  policy_document                 = templatefile("${path.module}/json_policy/shared_assume_policy.json.tmpl", {
    bucket_arn = module.s3_glue_assets.bucket_arn
    secretmanager_shared_arn = module.secret_manager_shared.secret_arn
  })

  depends_on = [ module.glue_iam_role ]
}



module "secret_manager_shared" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  # checkov:skip=CKV_SECRET_6: The value in private_key will be changed by customer
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/SecretsManager?ref=v0.0.1"

  secret_name     = "secret-shared"
  description     = "Armazenamento de segredo shared"
  secret_value    = jsonencode({
    hostname = "sftp.host.com",
    port = "22",
    username = "admin"
    private_key_str = ""
  })
  kms_key_id      = module.kms_shared.key_id
  enable_rotation = false
  tags = {
    Terraform = "true"
  }
}



module "glue_connection_shared" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/Glue/glue-connection?ref=v0.0.1"

  enabled                = true
  connection_name        = "glue_connection"
  connection_type        = "NETWORK"
  connection_description = "Conexão Default para os Jobs do Glue"

  physical_connection_requirements = {
    availability_zone      = "us-east-2a"
    security_group_id_list = [module.glue_securitygroup_connection.sg_id]
    subnet_id              = local.private_subnet_id
  }

  tags = {
    Project = "NAD"
    Terraform = "true"
  }

  depends_on = [ module.glue_securitygroup_connection ]
}



####################################################
#  _____ __     __ _______  _    _   ____   _   _  #
# |  __ \\ \   / /|__   __|| |  | | / __ \ | \ | | #
# | |__) |\ \_/ /    | |   | |__| || |  | ||  \| | #
# |  ___/  \   /     | |   |  __  || |  | || . ` | #
# | |       | |      | |   | |  | || |__| || |\  | #
# |_|       |_|      |_|   |_|  |_| \____/ |_| \_| #
####################################################
                                                                                             
##############################################
#  Glue Job de Python
##############################################

module "glue_job_python_shared" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/Glue/glue-job?ref=v0.0.1"

  job_name          = "job-to-python-shared"
  job_description   = "Glue Job that runs Python script"
  role_arn          = module.shared_iam_role.iam_role_arn

  glue_version      = "1.0"
  max_retries       = 0
  timeout           = 30

  connections       = [module.glue_connection_shared.name]

  command = {
    name            = "pythonshell"
    python_version  = 3
    script_location = format("s3://%s/script/%s.py", module.s3_shared.s3_bucket_name, module.s3_shared.s3_bucket_name)
  }

  default_arguments = {
    "--TempDir" = format("s3://%s/temp/", module.s3_shared.s3_bucket_name)
    "--enable-metrics" = "true"
    "--extra-py-files" = format("s3://%s/python/dependencies.zip", module.s3_shared.s3_bucket_name)
    "--secret_name" = module.secret_manager_shared.secret_name

    # Configurações do Python UI
    "--enable-continuous-cloudwatch-log" = "true"
    "--continuous-log-logGroup" = format("/aws-glue/python-jobs/%s", module.s3_shared.s3_bucket_name)
  }

  tags = {
    Terraform = "true"
  }

  depends_on = [ 
    module.s3_shared, 
    module.glue_connection_shared,
    module.secret_manager_shared
    ]
}

resource "null_resource" "upload_s3_python_shared" {
  provisioner "local-exec" {
    command = "aws s3 cp ./src/etl_glue_job/job-to-python-shared.py s3://${module.s3_shared.s3_bucket_name}/script/job-to-python-shared.py"
  }
  triggers = {
    filemd5 = filesha256("${path.module}/glue_files/src/etl_glue_job/job-to-python-shared.py")
  }
  depends_on = [ module.s3_shared ]
}



#########################################
#   _____  _____          _____   _  __ #
#  / ____||  __ \  /\    |  __ \ | |/ / #
# | (___  | |__) |/  \   | |__) || ' /  #
#  \___ \ |  ___// /\ \  |  _  / |  <   #
#  ____) || |   / ____ \ | | \ \ | . \  #
# |_____/ |_|  /_/    \_\|_|  \_\|_|\_\ #
#########################################                                      
                                      
############################################
#  Glue Job de Spark
############################################

module "glue_job_spark_shared" {
  # checkov:skip=CKV_TF_1: It's not necessary work with commit hash
  source = "git::ssh://git@github.com/gft-laboratory/modules-shared.git//modules/Glue/glue-job?ref=v0.0.1"

  job_name          = "job-to-spark-shared"
  job_description   = "Glue Job that runs Spark script"
  role_arn          = module.glue_iam_role.iam_role_arn

  glue_version      = "5.0"
  max_retries       = 0
  timeout           = 30
  worker_type       = "G.1X"
  number_of_workers = 5

  command = {
    name            = "glueetl"
    script_location = format("s3://%s/script/%s.py", module.s3_shared.s3_bucket_name, module.s3_shared.s3_bucket_name)
  }

  connections = [module.glue_connection_shared.name]

  default_arguments = {
    "--TempDir" = format("s3://%s/temp/", module.s3_shared.s3_bucket_name)
    "--job-bookmark-option"          = "job-bookmark-disable"
    "--input"                        = "bucket_name - substitua-me"
    "--output"                       = "bucket_name - substitua-me"
    "--enable-job-insights"          = "true"
    "--enable-metrics"               = "true"
    "--enable-observability-metrics" = "true"

    # Configurações do Spark UI
    "--enable-spark-ui"              = "true"
    "--spark-event-logs-path"        = format("s3://%s/sparkHistoryLogs/", module.s3_shared.s3_bucket_name)
    "--enable-continuous-cloudwatch-log" = "true"
    "--continuous-log-logGroup" = format("/aws-glue/spark-jobs/%s", module.s3_shared.s3_bucket_name)

    # Configuração do Data Catalog
    "--enable-glue-datacatalog"      = "true"

    # Configuração de Lineage
    #"--generate-lineage-events" = "true"
    #"--domain-id"               = "0000000"
    "--enable-auto-scaling"      = "true"
  }

  tags = {
    Terraform = "true"
  }

  depends_on = [
    module.shared_iam_role, 
    module.s3_shared
  ]
}

resource "null_resource" "upload_s3_spark_shared" {
  provisioner "local-exec" {
    command = "aws s3 cp ./src/etl_glue_job/job-to-spark-shared.py s3://${module.s3_shared.s3_bucket_name}/script/job-to-spark-shared.py"
  }
  triggers = {
    filemd5 = filesha256("${path.module}/glue_files/src/etl_glue_job/job-to-spark-shared.py")
  }
  depends_on = [ module.s3_shared ]
}