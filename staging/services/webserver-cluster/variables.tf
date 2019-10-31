#Defining an input variable
variable "server_port" {
    description = "port server will use for http requests"
    type = number
    default = 8080
}