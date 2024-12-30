provider "aws" {
  profile = "kanth_testuser"
  region = "us-east-1"
}

# Data source to find an existing ACM certificate
data "aws_acm_certificate" "existing_cert" {
  domain      = "*.deemmonsxl.xyz"  # Replace with your actual domain name
  statuses    = ["ISSUED"]
  most_recent = true
}

# Output to confirm the certificate ARN
output "acm_certificate_arn" {
  value = data.aws_acm_certificate.existing_cert.arn
}

# Data source to find an existing Route 53 hosted zone
data "aws_route53_zone" "existing_zone" {
  name         = "deemmonsxl.xyz"  # Replace with your domain name
  private_zone = false
}

# Create Route 53 DNS record for ACM certificate validation
resource "aws_route53_record" "validation" {
  name    = "_84cde90c742d9f399abc0afe063c697f.deemmonsxl.xyz"  # Use the validation name from ACM output
  type    = "CNAME"                                             # DNS validation record type
  ttl     = 60
  records = ["_4bd5c540b81a1b345e02b929df303e1c.djqtsrsxkq.acm-validations.aws."]  # Use the validation value from ACM output

  zone_id = data.aws_route53_zone.existing_zone.zone_id
}

# Create ACM certificate validation resource
resource "aws_acm_certificate_validation" "validation" {
  certificate_arn = data.aws_acm_certificate.existing_cert.arn

  validation_record_fqdns = [
    aws_route53_record.validation.fqdn
  ]
}

# Define Auto Scaling Group for Blue Environment
resource "aws_launch_template" "blue_lt" {
  name_prefix          = "blue-template"
  image_id      = "ami-040baf2d4cf79dfa7"  # Provide the correct AMI ID
  instance_type = "t3.micro"
  key_name = "git-2024"

  tags ={
    Name = "Blue-ec2"
  }
}

resource "aws_autoscaling_group" "blue_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = ["subnet-0d63da31ae0352dec"]
  launch_template {
    id = aws_launch_template.blue_lt.id
    version = "$Latest"
    
  }

  target_group_arns = [aws_lb_target_group.blue_tg.arn]
}

# Define Auto Scaling Group for Green Environment
resource "aws_launch_template" "green_lt" {
  name_prefix =           "green-template"
  image_id      = "ami-0e7ba2d73ecdcd533"  # Provide the correct AMI ID for the new version
  instance_type = "t3.micro"
  key_name = "git-2024"

  tags = {
    Name = "Green-ec2"
  }
}

resource "aws_autoscaling_group" "green_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = ["subnet-0d63da31ae0352dec"]
  launch_template {
    id  = aws_launch_template.green_lt.id
    version = "$Latest"
    
  }

  target_group_arns = [aws_lb_target_group.green_tg.arn]
}

# Define ALB for Blue Environment
resource "aws_lb" "blue_alb" {
  name               = "blue-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-0d63da31ae0352dec","subnet-006a6f2a8eb19d5d1"]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "blue_https" {
  load_balancer_arn = aws_lb.blue_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.existing_cert.arn
  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = 200
      content_type = "text/plain"
      message_body = "Blue Environment"
    }
  }
}

resource "aws_lb_listener" "blue_listener" {
  load_balancer_arn = aws_lb.blue_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "Blue Environment"
    }
  }
}

resource "aws_lb_target_group" "blue_tg" {
  name     = "blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-083ba7e0b42236aa6"
}

# Define ALB for Green Environment
resource "aws_lb" "green_alb" {
  name               = "green-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-0d63da31ae0352dec","subnet-006a6f2a8eb19d5d1"]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "green_https" {
  load_balancer_arn = aws_lb.green_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.existing_cert.arn
  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = 200
      content_type = "text/plain"
      message_body = "Green Environment"
    }
  }
}

resource "aws_lb_listener" "green_listener" {
  load_balancer_arn = aws_lb.green_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "Green Environment"
    }
  }
}

resource "aws_lb_target_group" "green_tg" {
  name     = "green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-083ba7e0b42236aa6"
}

# Route 53 Configuration for Blue Record
resource "aws_route53_record" "blue_record" {
  zone_id = data.aws_route53_zone.existing_zone.zone_id  # Corrected this line
  name    = "blue.deemmonsxl.xyz"
  type    = "A"
  alias {
    name                   = aws_lb.blue_alb.dns_name
    zone_id                = aws_lb.blue_alb.zone_id
    evaluate_target_health = true
  }
}

# Route 53 Configuration for Green Record
resource "aws_route53_record" "green_record" {
  zone_id = data.aws_route53_zone.existing_zone.zone_id  # Corrected this line
  name    = "green.deemmonsxl.xyz"
  type    = "A"
  alias {
    name                   = aws_lb.green_alb.dns_name
    zone_id                = aws_lb.green_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "traffic_policy" {
  zone_id = data.aws_route53_zone.existing_zone.zone_id  # Corrected to use the data source for existing zone
  name    = "www.deemmonsxl.xyz"
  type    = "A"
  alias {
    name                   = aws_lb.blue_alb.dns_name
    zone_id                = aws_lb.blue_alb.zone_id
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight           = 100
  }

  set_identifier   = "blue"  # Correct use of set_identifier
  }


resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "aurora-serverless-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  database_name           = "bluegreen"
  master_username         = "kanth"
  master_password         = "lselp20221"
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  skip_final_snapshot     = true
  backup_retention_period = 5

  scaling_configuration {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 4
    seconds_until_auto_pause = 300
}
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
}



