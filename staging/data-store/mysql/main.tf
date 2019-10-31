provider "aws" {

    region = "us-east-2"
}

resource "aws_db_instance" "example" {

    identifier_prefix = "terraform-up-and-running"
    engine            = "mysql"
    allocated_storage = 10
    instance_class    = "db.t2.micro"
    name              = "example_instance"
    username          = "admin"

    password          = "adminadmin"
}

data "terraform_remote_state" "db" {
    backend = "s3"

    config = {
        bucket = "my-terraform-infrastructure-state"
        key = "staging/data-store/mysql/terraform.tfstate"
        region = "us-east-2"
    }
}

terraform{
    backend "s3" {

        bucket = "my-terraform-infrastructure-state"
        key = "staging/data-store/mysql/terraform.tfstate"
        region = "us-east-2"

        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}