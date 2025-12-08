variable "token" {
  description = "OAuth-токен"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "ID облака (Cloud ID)"
  type        = string
}

variable "folder_id" {
  description = "ID каталога (Folder ID), где создаются ресурсы"
  type        = string
}

variable "zone_a" {
  description = "Зона доступности для Портала"
  type        = string
  default     = "ru-central1-a"
}

variable "zone_b" {
  description = "Зона доступности для Обработки данных"
  type        = string
  default     = "ru-central1-b"
}

variable "ssh_key_path" {
  description = "Путь к публичному SSH-ключу"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
