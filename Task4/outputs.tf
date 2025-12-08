output "portal_public_ip" {
  description = "Публичный IP-адрес Портала. Используйте его для подключения по SSH."
  value = yandex_compute_instance.portal_vm.network_interface.0.nat_ip_address
}

output "processing_internal_ip" {
  description = "Внутренний IP-адрес сервера обработки. Доступен внутри сети."
  value = yandex_compute_instance.processing_vm.network_interface.0.ip_address
}
