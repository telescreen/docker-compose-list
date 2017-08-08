/*
 * API KEYはとても重要なデータです。
 * terraform本体のファイルには記述せず、
 * 変数ファイル(sample.tfvars)に記述しています。
 */
variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "zone" {}
variable "image_id" {
  default = "m-6web5jezbcytjj20tgvk"
}
variable "instance_type" {
  default = "ecs.xn4.small"
}
variable "vpc_ip" {
  default = "10.18.128.0/20"
}
variable "subnet_ip" {
  default = "10.18.129.0/24"
}

# Alicloud Providerの設定
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "alicloud_vpc" "vpc" {
  name = "vpc-cluster"
  cidr_block = "${var.vpc_ip}"
}

# ------------------------------------------------------------------------
# Coreサーバー作成
module "machine" {
  source = "./machine"
  zone = "${var.zone}"
  vpc_id = "${alicloud_vpc.vpc.id}"
  subnet = "${var.subnet_ip}"
  image_id = "${var.image_id}"
  instance_name = "docker"
  instance_type = "${var.instance_type}"
  servers = 3
}

# ECSに紐付けるEIP(グローバルIP)の作成
resource "alicloud_eip" "manager-eip" {
  internet_charge_type = "PayByTraffic"
}
# ------------------------------------------------------------------------
output "server_ip" {
  value = ["${module.machine.server_instance_ip}"]
}
