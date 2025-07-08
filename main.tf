locals {
  # Shared
  environment   = "dev"
  app_name      = "my-app-example"
  vpc_id        = "vpc-01234567890"
  subnet_ids    = ["subnet-01234567890", "subnet-01234567890"]
  tags_datalake = { 
    Environment = local.environment
    Name        = local.app_name
  }
  # DynamoDB
  partition_key_name       = "PartitionKey01"
  partition_key_type       = "S"
  stream_enabled           = true
  stream_view_type         = "KEYS_ONLY" 
  kinesis_stream_name      = "kinesis-stream"
  # S3
  bucket_name              = "my-bucket-example"
  bucket_policy_enabled    = true
  bucket_log_name          = "my-bucket-example-log-dev"
  # SecurityGroup to DMS - AWS Database Migration Service
  sg_dms_name                     = "my-app-sg"
  sg_dms_ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http access from internal network"
      cidr_blocks = "10.10.10.0/24"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https access from internal network"
      cidr_blocks = "10.10.10.0/24"
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Mysql access from internal network"
      cidr_blocks = "192.168.10.0/24"
    }
  ]
  sg_dms_egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = -1
      description = "anywhere"
      cidr_blocks = "10.0.0.0/16"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = 6
      description = "anywhere"
      cidr_blocks = "10.10.10.0/24"
    }
  ]
  sg_dms_tags = {
    Name = "my-app-sg-all-custom"
  }
}

###############################################################################################
#                                  DYNAMODB MODULE
###############################################################################################

module "dynamodb" {
  source = "git::https://github.com/gft-laboratory/modules-shared.git//DynamoDB?ref=v0.0.1"

  table_name         = var.dynamodb_name
  partition_key_name = "PartitionKey01"
  partition_key_type = "S"
  # Optional
  stream_enabled      = true
  stream_view_type    = "KEYS_ONLY" # Valid values: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES
  kinesis_stream_name = "${var.dynamodb_name}-kinesis-stream"

  tags_dynamodb = { 
    Environment = var.environment
    Name        = var.dynamodb_name
  }
}

###############################################################################################
# S3 MODULE
###############################################################################################

module "s3" {
  source = "git::https://github.com/gft-laboratory/modules-shared.git//S3?ref=v0.0.1"

  bucket_name          = var.bucket_name
  create_bucket_policy = false

  tags_bucket = { 
    Environment = var.environment
    Name        = var.bucket_name
    Module      = "module-application-validation"
  }
}

###############################################################################################
# SecurityGroup MODULE
###############################################################################################

module "sg_myapp" {
  source = "git::https://github.com/gft-laboratory/modules-shared.git//SecurityGroup?ref=v0.0.1"

  name                     = local.sg_dms_name
  vpc_id                   = local.vpc_id
  ingress_with_cidr_blocks = local.sg_dms_ingress_with_cidr_blocks
  egress_with_cidr_blocks  = local.sg_dms_egress_with_cidr_blocks
  tags                     = local.sg_dms_tags
}