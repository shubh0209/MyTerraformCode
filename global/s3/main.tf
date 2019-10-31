provider "aws" {

    region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {

    bucket = "my-terraform-infrastructure-state"

    #Prevent accidental deletion of bucket
    lifecycle {
        prevent_destroy = true
    }

    #Enable versioning so that we can see full history of our state files
    versioning {
        enabled = true
    }

    #Enable server side encryption by default
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}
resource "aws_dynamodb_table" "terraform_locks" {

    name  = "terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}
terraform {
    backend "s3" {
        bucket = "my-terraform-infrastructure-state"
        region = "us-east-2"
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
        key = "global/s3/terraform.tfstate"
    }
}

