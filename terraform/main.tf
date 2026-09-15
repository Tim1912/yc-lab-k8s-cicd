terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "= 0.228.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "./key.json"
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

# 1. Сеть VPC и подсеть
resource "yandex_vpc_network" "lab_network" {
  name = "lab-network"
}

resource "yandex_vpc_subnet" "lab_subnet" {
  name           = "lab-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.lab_network.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

# 2. Сервисный аккаунт для Kubernetes
resource "yandex_iam_service_account" "k8s_sa" {
  name = "k8s-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_images_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# 3. Реестр контейнеров (YCR)
resource "yandex_container_registry" "lab_registry" {
  name = "lab-registry"
}

# 4. Кластер Managed Kubernetes
resource "yandex_kubernetes_cluster" "lab_cluster" {
  name        = "lab-k8s-cluster"
  network_id  = yandex_vpc_network.lab_network.id
  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_sa.id

  master {
    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.lab_subnet.id
    }
    public_ip = true
  }
}

resource "yandex_kubernetes_node_group" "lab_node_group" {
  cluster_id = yandex_kubernetes_cluster.lab_cluster.id
  name       = "lab-node-group"

  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      type = "network-hdd"
      size = 64
    }
    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.lab_subnet.id]
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }
}

# 5. Кластер Managed PostgreSQL
resource "yandex_mdb_postgresql_cluster" "lab_pg" {
  name        = "lab-postgresql"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.lab_network.id

  config {
    version = "15"
    resources {
      resource_preset_id = "s2.micro"
      disk_size          = 10
      disk_type_id       = "network-ssd"
    }
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.lab_subnet.id
  }
}

resource "yandex_mdb_postgresql_user" "db_user" {
  cluster_id = yandex_mdb_postgresql_cluster.lab_pg.id
  name       = "db_user"
  password   = var.db_password
}

resource "yandex_mdb_postgresql_database" "app_db" {
  cluster_id = yandex_mdb_postgresql_cluster.lab_pg.id
  name       = "app_db"
  owner      = yandex_mdb_postgresql_user.db_user.name
}