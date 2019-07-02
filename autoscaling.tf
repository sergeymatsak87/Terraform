resource "aws_launch_configuration" "lc_conf" {
  name_prefix     = "lc"
  image_id        = "${lookup(var.amis, var.region)}"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.allow_ssh.id}"]
  key_name        = "deployer-key"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_security_group.allow_ssh", "aws_key_pair.deployer"]
}

resource "aws_autoscaling_group" "as_conf" {
  name                      = "as"
  launch_configuration      = "${aws_launch_configuration.lc_conf.name}"
  min_size                  = 1
  max_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = ["${data.aws_subnet_ids.subnet_ids.ids}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Team"
    value               = "Dev"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "Type"
    value               = "webserver"
    propagate_at_launch = false
  }

  depends_on = ["data.aws_subnet_ids.subnet_ids"]
}

resource "aws_autoscaling_attachment" "as_attachment" {
  autoscaling_group_name = "${aws_autoscaling_group.as_conf.id}"
  alb_target_group_arn   = "${aws_lb_target_group.alb_target_group.arn}"
}

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_subnet}"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Main VPC"
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id     = "${aws_vpc.main.id}"
  depends_on = ["aws_subnet.private_subnets"]
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "private_subnets" {
  count                   = "${length(var.private_subnets)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_subnets[count.index]}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "private"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "${var.ssh_pub_key}"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.your_subnet}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
