variable "zone" {}
variable "vpc_id" {}
variable "subnet" {}
variable "image_id" {}
variable "instance_name" {}
variable "instance_type" {}
variable "servers" {}

resource "alicloud_vswitch" "subnet" {
  name              = "subnet"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.subnet}"
  availability_zone = "${var.zone}"
}

# ------------------------------------------------------------------------
# セキュリティグループの作成
resource "alicloud_security_group" "sg-subnet" {
  name   = "SecurityGroupForSubnet"
  vpc_id = "${var.vpc_id}"
}

resource "alicloud_security_group_rule" "inbound_ssh" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 100
  security_group_id = "${alicloud_security_group.sg-subnet.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "inbound" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 100
  security_group_id = "${alicloud_security_group.sg-subnet.id}"
  cidr_ip           = "${var.subnet}"
}

resource "alicloud_security_group_rule" "outbound" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 100
  security_group_id = "${alicloud_security_group.sg-subnet.id}"
  cidr_ip           = "0.0.0.0/0"
}

# ------------------------------------------------------------------------
# Master ECSの作成
resource "alicloud_instance" "server" {
  count = "${var.servers}"
  host_name = "${var.instance_name}${count.index}"
  instance_name = "${var.instance_name}${count.index}"
  availability_zone = "${var.zone}"
  image_id = "${var.image_id}"
  instance_type = "${var.instance_type}"
  security_groups = ["${alicloud_security_group.sg-subnet.id}"]
  vswitch_id = "${alicloud_vswitch.subnet.id}"
  user_data = "${file("machine/provision.sh")}"
}

# ------------------------------------------------------------------------
output "switch_id" {
  value = "${alicloud_vswitch.subnet.id}"
}

output "security_group_id" {
  value = "${alicloud_security_group.sg-subnet.id}"
}

output "server_instance_ip" {
  value = "${alicloud_instance.server.*.ip}"
}
