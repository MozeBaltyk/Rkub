# Local resources

###
### Cloud-init
###

# non-airgap
locals {
  cloud_init_config = yamlencode({
    packages = [
      "ansible",
      "make"
    ]
  })
}

# Convert our cloud-init config to userdata
# Userdata runs at first boot when the droplets are created
data "cloudinit_config" "server_config" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content      = local.cloud_init_config
  }
}

# airgap
locals {
  cloud_init_airgap_config = yamlencode({
    yum_repos = {
      epel-release = {
        name = "Extra Packages for Enterprise Linux 8 - Release"
        baseurl = "http://download.fedoraproject.org/pub/epel/8/Everything/$basearch"
        enabled = true
        failovermethod = "priority"
        gpgcheck = true
        gpgkey = "http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8"
      }
    },
    packages = [
      "epel-release",
      "s3fs-fuse",
      "git",
      "ansible",
      "make"
    ],
    write_files = [{
      owner       = "root:root"
      path        = "/etc/passwd-s3fs"
      permissions = "0600"
      content     = "${var.spaces_access_key_id}:${var.spaces_access_key_secret}"
    }],
    runcmd = [
      "systemctl daemon-reload",
      "mkdir -p ${var.mount_point}",
      "s3fs ${var.terraform_backend_bucket_name} ${var.mount_point} -o url=https://${var.region}.digitaloceanspaces.com",
      "echo \"s3fs#${var.terraform_backend_bucket_name} ${var.mount_point} fuse _netdev,allow_other,nonempty,use_cache=/tmp/cache,url=https://${var.region}.digitaloceanspaces.com 0 0\" >> /etc/fstab",
      "systemctl daemon-reload",
    ]
  })
}

# Convert our cloud-init config to userdata
# Userdata runs at first boot when the droplets are created
data "cloudinit_config" "server_airgap_config" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content      = local.cloud_init_airgap_config
  }
}
