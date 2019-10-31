output "address" {
    value = "aws_db_instance.example.address"
    description = "connect to database at this endpoint"
}

output "port" {
    value = "aws_db_instance.example.port"
    description = "The port database is listening on."
}