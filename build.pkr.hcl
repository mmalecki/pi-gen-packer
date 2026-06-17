locals {
  op = [
    "OPERATOR_USER=${var.operator_user_name}",
    "OPERATOR_GROUP=${var.operator_user_name}",
  ]

  etc_hosts = "sed -i \"s/raspberrypi/$(hostname)/\" /etc/hosts"
  hotplug_network_interfaces = "systemctl mask systemd-networkd-wait-online.service"
  block_wifi = "rfkill block wifi"

  server_builds = [
    "arm-image.home",
    "arm-image.infra",
    "arm-image.rapiscope",
  ]

  desktop_builds = [
    "source.arm-image.media",
  ]
}

build {
  sources = concat(local.server_builds, local.desktop_builds)

  name = "common"

  provisioner "shell" {
    script = "scripts/common.sh"
  }

  provisioner "shell" {
    script = "scripts/wifi.sh"
    environment_vars = [
      "WIFI_SSID=${var.wifi_ssid}",
      "WIFI_PASS=${var.wifi_pass}"
    ]
  }

  provisioner "shell" {
    only = local.server_builds
    script = "scripts/systemd.sh"
  }

  provisioner "shell" {
    script = "scripts/install-docker.sh"
    environment_vars = local.op
  }

  provisioner "shell" {
    script = "scripts/install-cloud-init.sh"
  }

  provisioner "shell" {
    only = ["arm-image.home"]
    script = "scripts/install-home-assistant.sh"
    environment_vars = local.op
  }

  provisioner "shell" {
    only = ["arm-image.rapiscope"]
    script = "scripts/install-rapiscope.sh"
  }

  provisioner "shell" {
    only = ["arm-image.media"]
    script = "scripts/install-media.sh"
  }

  provisioner "file" {
    only = ["arm-image.home"]

    destination = "/etc/cloud/cloud.cfg.d/home.cfg"
    content = templatefile("templates/cloud-init-common.tmpl", {
      hostname = "home"
      cmds : [
        local.etc_hosts,
        # local.block_wifi,
        local.hotplug_network_interfaces,
        "cd /srv/home-assistant && docker compose up -d",
      ]
    })
  }

  provisioner "file" {
    only = ["arm-image.infra"]

    destination = "/etc/cloud/cloud.cfg.d/infra.cfg"
    content = templatefile("templates/cloud-init-common.tmpl", {
      hostname = "infra"
      cmds : [
        local.etc_hosts,
        local.block_wifi,
      ]
    })
  }

  provisioner "file" {
    only = ["arm-image.rapiscope"]

    destination = "/etc/cloud/cloud.cfg.d/rapiscope.cfg"
    content = templatefile("templates/cloud-init-common.tmpl", {
      hostname = "rapiscope"
      cmds : [
        local.etc_hosts,
        local.hotplug_network_interfaces,
      ]
    })
  }

  provisioner "file" {
    only = ["arm-image.media"]

    destination = "/etc/cloud/cloud.cfg.d/media.cfg"
    content = templatefile("templates/cloud-init-common.tmpl", {
      hostname = "media"
      cmds : [
        local.etc_hosts,
      ]
    })
  }

  provisioner "shell" {
    only = local.server_builds
    script = "scripts/systemd-post.sh"
  }
}
