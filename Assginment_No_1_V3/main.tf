provider "aws" {
  region = "us-east-1"
}

# # 1. Create vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production-vpc1"
  }
}

# This CIDR block determines the range of IP addresses allocated for your apps in the VPC. 
# For an Anypoint VPC, the size of this CIDR needs to be a number between 24 (256 Ips) and 16 (65,536 IPs). 


# # 2. Create Internet Gateway
/* point no. 2

Q1 What is the purpose of having internet gateway within a VPC?
    An internet gateway provides a target in your VPC route tables for internet-routable traffic. 
    For communication using IPv4, the internet gateway also performs network address translation (NAT).

Q2 Does a VPC need an Internet gateway?
    If a VPC does not have an Internet Gateway, then the resources in the VPC cannot be accessed 
    from the Internet (unless the traffic flows via a corporate network and VPN/Direct Connect).

*/
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    Name = "aws_internet_gateway_1"
  }
}

# # 3. Create Custom Route Table
/*
what is the use of cidr block in vpc?
    CIDR stands for Classless Inter-Domain Routing.
    This CIDR block determines the range of IP addresses allocated for your apps in the VPC. 

what is route table?
    A route table contains a set of rules, called routes and
    that determine where network traffic from your subnet or gateway is directed.
*/
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id
  route {
    cidr_block = "0.0.0.0/0" //default block
    gateway_id = aws_internet_gateway.gw.id
  }

  # route {
  #   ipv6_cidr_block = "::/0" 
  #   gateway_id      = aws_internet_gateway.gw.id
  # }

  tags = {
    Name = "Prod-route-table-1"
  }
}

/*
1) Internet gateway - It provide target to route table inside your VPC
2) route table - it has a rule to create route/path to send traffic at destination.
3) subnet - provide a shortest distance to route the traffic to destination.
4) cidr block - it has range of Ip addresses allocated to our server.
*/

# # 4. Create a Subnet 

/*
What is a subnet within a VPC?
    A subnet, or subnetwork, is a network inside a network. 
    Subnets make networks more efficient. 
    Through subnetting, network traffic can travel a shorter distance without passing through unnecessary routers to reach its destination.

How many subnets can I create per VPC? 
    Currently you can create 200 subnets per VPC.

Why do we have subnets?
    One goal of a subnet is to split a large network into a grouping of smaller, 
    interconnected networks to help minimize traffic. 
    This way, traffic doesn't have to flow through unnecessary routs, increasing network speeds. 
    Subnetting, the segmentation of a network address space, improves address allocation efficiency.

Could you deploy an instance into a VPC without a subnet?
    However, if you delete your default subnets or default VPC, 
    you must explicitly specify a subnet in another VPC in which to launch your instance, 
    because you can't launch instances into EC2-Classic. 
    If you do not have another VPC, you must create a nondefault VPC and nondefault subnet.

How do subnets talk to each other AWS?
    All subnets (regardless of whether they are Public or Private) 
    within the same Amazon VPC can communicate with each other by default. 
    Communication should be made via the private IP address of the resources, to ensure that the traffic 
    stays within the VPC.
*/
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1d" // 1a, 1b, 1c we can choose any one of these.
  tags = {
    Name = "prod-subnet"
  }
}

# # 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# Create a launch configuration and attach the security group
resource "aws_launch_configuration" "test_lc" {
  name_prefix          = "Test-lc"
  image_id             = "ami-007855ac798b5175e"
  instance_type        = "t2.micro"
  lifecycle {
    create_before_destroy = true
  }
}

# Create an auto scaling group using the launch configuration
resource "aws_autoscaling_group" "example_asg" {
  name                      = "Demo-asg"
  vpc_zone_identifier       = [aws_subnet.subnet-1.id]
  launch_configuration      = aws_launch_configuration.test_lc.id
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  termination_policies      = ["OldestInstance", "Default"]
  target_group_arns         = [aws_lb_target_group.assgin1_tg.arn]
  
  tag {
    key                 = "Name"
    value               = "my-instance"
    propagate_at_launch = true
  }
}

#create target gp 
resource "aws_lb_target_group" "assgin1_tg" {
  name     = "example"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.prod-vpc.id
}
#create ELB and attached to asg
resource "aws_elb" "example_elb" {
  name            = "example-elb"
  subnets         = [aws_subnet.subnet-1.id]
  security_groups = [aws_security_group.vpc_security_group.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}

#create security group for rds
resource "aws_security_group" "vpc_security_group" {
  name_prefix = "rds_"
  vpc_id   = aws_vpc.prod-vpc.id
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an S3 bucket for backups
resource "aws_s3_bucket" "s3_bucket-1" {
  bucket = "my-rds-backup-bucket123"
}

# Create an RDS instance with S3 backup
resource "aws_db_instance" "my_rds_instance" {
  identifier             = "my-rds-instance"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "mydatabase"
  username               = "admin"
  password               = "admin123"
  parameter_group_name     = "default.mysql5.7"
  backup_retention_period  = 7
  vpc_security_group_ids   = [aws_security_group.vpc_security_group.id]
  db_subnet_group_name     = aws_db_subnet_group.SB.name
  skip_final_snapshot      = true
  tags = {
    Name = "My RDS Instance"
  }

}

resource "aws_subnet" "rds_SB1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "rds_subnet1"
  }
}
resource "aws_subnet" "rds_SB2" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  tags = {
    Name = "rds_subnet1"
  }
}

#db subnet group name
resource "aws_db_subnet_group" "SB" {
  name        = "example-db-subnet-group"
  subnet_ids = [aws_subnet.rds_SB1.id, aws_subnet.rds_SB2.id]
  tags = {
    Name = "example-db-subnet-group"
  }
}

resource "aws_db_snapshot" "rds_snapshot" {
  db_instance_identifier = aws_db_instance.my_rds_instance.id
  db_snapshot_identifier = "testsnapshot1234"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.s3_bucket-1.id
  acl    = "private"
}

resource "aws_iam_role" "example" {
  name = "example"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "example" {
  statement {
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.s3_bucket-1.arn,
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.s3_bucket-1.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "example" {
  name   = "example"
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

resource "aws_kms_key" "example" {
  deletion_window_in_days = 10
}

resource "aws_rds_export_task" "example" {
  export_task_identifier = "example"
  source_arn             = aws_db_snapshot.rds_snapshot.db_snapshot_arn
  s3_bucket_name         = aws_s3_bucket.s3_bucket-1.id
  iam_role_arn           = aws_iam_role.example.arn
  kms_key_id             = aws_kms_key.example.arn

  export_only = ["database"]
  s3_prefix   = "my_prefix/example1"
}
