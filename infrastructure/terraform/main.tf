terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.75.0"

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "momo-terraform-state"
    region     = "ru-central1-a"
    key        = "terraform.tfstate"
    // Access and secret keys are set in backend.tfvars file
    access_key = var.access_key
    secret_key = var.secret_key

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  token = var.token
  zone  = var.zone
}

resource "yandex_vpc_network" "net" {
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "Main"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  folder_id      = var.folder_id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_iam_service_account" "sa-kube" {
  name      = "sa-kube"
  folder_id = var.folder_id
}

resource "yandex_iam_service_account_iam_binding" "k8s-admin" {
  service_account_id = yandex_iam_service_account.sa-kube.id
  role               = "vpc.publicAdmin"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-kube.id}",
  ]
}

resource "yandex_iam_service_account_iam_binding" "k8s-clagent" {
  service_account_id = yandex_iam_service_account.sa-kube.id
  role               = "k8s.clusters.agent"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-kube.id}",
  ]
}

resource "yandex_iam_service_account_iam_binding" "k8s-editor" {
  service_account_id = yandex_iam_service_account.sa-kube.id
  role               = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-kube.id}",
  ]
}

resource "yandex_resourcemanager_cloud_iam_binding" "k8s-editor" {
  cloud_id = var.cloud_id
  role     = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.sa-kube.id}",
  ]
}

// Kube cluster
resource "yandex_kubernetes_cluster" "zonal_momo_cluster" {
  name = "momo-k8s-cluster"

  network_id         = yandex_vpc_network.net.id
  folder_id          = var.folder_id
  cluster_ipv4_range = "10.11.0.0/16"
  service_ipv4_range = "10.12.0.0/16"

  master {
    version = "1.21"
    zonal {
      zone      = yandex_vpc_subnet.subnet.zone
      subnet_id = yandex_vpc_subnet.subnet.id
    }

    public_ip = true

    #security_group_ids = [yandex_vpc_security_group.kube-.id]
    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "06:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.sa-kube.id
  node_service_account_id = yandex_iam_service_account.sa-kube.id

  labels = {
    env = "momo-prod"
  }

  release_channel = "REGULAR"

  depends_on = [
    yandex_iam_service_account.sa-kube
  ]

}

resource "yandex_kubernetes_node_group" "group" {
  cluster_id = yandex_kubernetes_cluster.zonal_momo_cluster.id
  name       = "momo-k8s-node-group"
  version    = "1.21"

  labels = {
    "env" = "momo-prod"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.subnet.id]
    }

    resources {
      memory = var.memory
      cores  = var.cores
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "04:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "04:00"
      duration   = "3h"
    }
  }
}
