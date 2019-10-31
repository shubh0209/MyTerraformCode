provider "aws" {

    region = "us-east-2"
}

#Defining a data source
data "aws_vpc" "default"{
    default = true
}

data "aws_subnet_ids" "default" {

    vpc_id = data.aws_vpc.default.id
}
#Defining launch configuration for auto-scaling group
resource "aws_launch_configuration" "example"{

    image_id = "ami-0d5d9d301c853a04a"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]
    key_name  = "MyKP2"

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    lifecycle {
        create_before_destroy = true
    }
}
#Defining an auto scaling group
resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {

        key = "name"
        value = "terraform-asg-example"
        propagate_at_launch = "true"
    }

}
#Defining security group for web server
resource "aws_security_group" "instance" {
    name  = "terraform-example-instance"

    ingress {

        from_port = var.server_port
        to_port = var.server_port
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

}
#Defining an application load balancer
resource "aws_lb" "example"{

    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id]
}

#Defining a listener for the application load balancer
resource "aws_lb_listener" "http" {

    load_balancer_arn = aws_lb.example.arn
    port = 80
    protocol = "HTTP"

    #By Default, return a simple 404 error page
    default_action {

        type = "fixed-response"

        fixed_response {

            content_type = "text/plain"
            message_body = "404: page not found"
            status_code  = 404
        }
    }
}
#Defining a security group for application load balancer
resource "aws_security_group" "alb"{

    name = "terraform-example-alb"

    ingress {

        from_port = 80
        to_port   = 80
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {

        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#Defining a target group for ASG
resource "aws_lb_target_group" "asg"{

    name  = "terraform-example-asg"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 30 
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

#Defining listener rule for application load balancer
resource "aws_lb_listener_rule" "asg" {

    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition  {
        field = "path-pattern"
        values = ["*"]
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

#Defining an output variable
output "alb_dns_name"{
    value = aws_lb.example.dns_name
    description = "DNS name of application load balancer"
}
#Changing the backend to a s3 bucket 
terraform {
    backend "s3" {
        bucket = "my-terraform-infrastructure-state"
        region = "us-east-2"
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
        key = "staging/services/webserver-cluster/terraform.tfstate"
    }
}
