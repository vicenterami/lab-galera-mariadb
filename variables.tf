variable "cluster_size" {
  type        = number
  description = "Número de nodos en el clúster Galera"
  default     = 3
}

variable "memoryMB" {
  type        = number
  description = "Memoria en MB por nodo"
  default     = 2048
}

variable "cpu" {
  type        = number
  description = "Número de CPUs por nodo"
  default     = 2
}

variable "diskSize" {
  type        = number
  description = "Tamaño del disco en bytes (por defecto 10GB)"
  default     = 10737418240
}

variable "path_to_image" {
  type        = string
  description = "Ruta absoluta a la imagen de Ubuntu en vmstore"
  # NOTA: Cambia 'vicenterog' si tu usuario es diferente
  default     = "/home/vicenterog/vmstore/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "ssh_key_path" {
  type        = string
  description = "Ruta absoluta a la llave SSH pública"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "domain" {
  type        = string
  description = "Dominio para el clúster"
  default     = "galera.local"
}

variable "libvirt_network" {
  type        = string
  description = "Nombre de la red de libvirt a crear"
  default     = "galera_net"
}

variable "network_cidr" {
  type        = string
  description = "Rango de IPs para la red de libvirt"
  default     = "192.168.100.0/24"
}
