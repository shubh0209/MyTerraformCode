#Defining an output variable
output "alb_dns_name"{
    value = aws_lb.example.dns_name
    description = "DNS name of application load balancer"
}