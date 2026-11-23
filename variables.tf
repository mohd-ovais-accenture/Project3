variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Free-tier micro EC2 instance type (change to t2.micro if needed)"
}

variable "cpu_threshold" {
  type        = number
  default     = 75
  description = "CPU utilization percentage threshold"
}
