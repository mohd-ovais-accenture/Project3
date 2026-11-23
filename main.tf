data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "ec2_no_high_risk_ports_sg" {
  name        = "project3-ec2-restricted-sg"
  description = "Security group with zero high-risk inbound ports"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "monitored_ec2" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_no_high_risk_ports_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              CORES=$(nproc)
              for i in $(seq 1 "$CORES"); do
                yes > /dev/null &
              done
              sleep 300
              pkill -f "yes > /dev/null" || true
              EOF

  tags = {
    Name = "project3-cpu-monitored-ec2"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_spike_alarm" {
  alarm_name          = "project3-ec2-cpu-spike-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "Triggers when EC2 CPU utilization exceeds 75% for 2 minutes"

  dimensions = {
    InstanceId = aws_instance.monitored_ec2.id
  }
}

output "ec2_instance_id" {
  value = aws_instance.monitored_ec2.id
}

output "cloudwatch_alarm_name" {
  value = aws_cloudwatch_metric_alarm.cpu_spike_alarm.alarm_name
}
