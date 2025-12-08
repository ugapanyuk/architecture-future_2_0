terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone_a
}

# Создаем главную сеть (VPC) для всего проекта
resource "yandex_vpc_network" "future_network" {
  name = "future-network"
}

# Создаем NAT-шлюз
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# Создаем таблицу маршрутизации
resource "yandex_vpc_route_table" "nat_route" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.future_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# Публичная подсеть (Зона А)
resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet-a"
  zone           = var.zone_a
  network_id     = yandex_vpc_network.future_network.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

# Частная подсеть (Зона Б)
resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private-subnet-b"
  zone           = var.zone_b
  network_id     = yandex_vpc_network.future_network.id
  v4_cidr_blocks = ["10.10.2.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
}

# ВМ: BI-Портал
resource "yandex_compute_instance" "portal_vm" {
  name        = "vm-portal"
  platform_id = "standard-v3"
  zone        = var.zone_a

  # Конфигурация ресурсов (Эконом-режим)
  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  # Политика прерывания (Spot/Preemptible)
  scheduling_policy {
    preemptible = true
  }

  # Загрузочный диск (Система)
  boot_disk {
    initialize_params {
      # ID образа Ubuntu 22.04 LTS  
      image_id = "fd80mrhj8fl2oe87o4e1" 
      # 10 ГБ
      size     = 10 
      type     = "network-hdd"
    }
  }

  # Сетевой интерфейс
  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    # Включаем публичный IP
    nat       = true
  }

  # Передаем SSH-ключ внутрь машины
  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
  }
}

# Создаем отдельный диск для Озера Данных
resource "yandex_compute_disk" "data_lake_disk" {
  name       = "disk-data-lake"
  type       = "network-hdd"
  # Обязательно в той же зоне, что и сервер обработки
  zone       = var.zone_b 
  size       = 10  
}

# ВМ: Сервер Обработки Данных
resource "yandex_compute_instance" "processing_vm" {
  name        = "vm-processing"
  platform_id = "standard-v3"
  zone        = var.zone_b 

  resources {
    cores  = 2
    memory = 4 
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      size     = 10
      type     = "network-hdd"
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.data_lake_disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnet.id
    nat       = false 
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
  }
}
