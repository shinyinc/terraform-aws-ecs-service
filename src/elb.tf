resource "aws_iam_server_certificate" "service" {
  name = "wildcard-certificate-${var.component}-${var.deployment_identifier}"
  private_key = "${file(var.service_certificate_private_key)}"
  certificate_body = "${file(var.service_certificate_body)}"
}

resource "aws_elb" "service" {
  name = "elb-${var.service_name}-${var.component}-${var.deployment_identifier}"
  subnets = ["${split(",", var.private_subnet_ids)}"]

  internal = true

  security_groups = [
    "${aws_security_group.service_elb.id}"
  ]

  listener {
    instance_port = "${var.service_port}"
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.service.arn}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:${var.service_port}/health"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 60

  tags {
    Name = "elb-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DevelopmentIdentifier = "${var.deployment_identifier}"
    Service = "${var.service_name}"
  }
}
