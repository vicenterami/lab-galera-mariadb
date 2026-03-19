terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Crear una red privada para el clúster Galera
resource "libvirt_network" "galera_net" {
  name      = var.libvirt_network
  mode      = "nat"
  domain    = var.domain
  addresses = [var.network_cidr]
}

# 2. Usar la imagen de Ubuntu desde tu vmstore
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-base.qcow2"
  pool   = "default"
  source = var.path_to_image
  format = "qcow2"
}

# 3. Crear discos para los nodos basados en el tamaño de la variable
resource "libvirt_volume" "node_volume" {
  count          = var.cluster_size
  name           = "galera-node-${count.index + 1}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = var.diskSize
}

# 4. Crear un Cloud-Init por cada VM
resource "libvirt_cloudinit_disk" "commoninit" {
  count          = var.cluster_size
  name           = "commoninit-${count.index + 1}.iso"
  pool           = "default"
  user_data = templatefile("${path.module}/config/cloud_init.cfg", {
    hostname = "galera-node-${count.index + 1}"
    # Pasamos la llave pública al template
    ssh_key  = file(var.ssh_key_path) 
  })
  network_config = templatefile("${path.module}/config/network_config.cfg", {
    # Genera IPs: .11, .12, .13
    ip_address = "192.168.100.1${count.index + 1}" 
  })
}

# 5. Crear las VMs
resource "libvirt_domain" "galera_node" {
  count  = var.cluster_size
  name   = "galera-node-${count.index + 1}"
  memory = var.memoryMB
  vcpu   = var.cpu

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  network_interface {
    network_id     = libvirt_network.galera_net.id
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.node_volume[count.index].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

output "ips_nodos_galera" {
  description = "IPs estáticas asignadas a los nodos"
  # Generamos la lista de IPs basada en el contador para el output
  value       = [for i in range(var.cluster_size) : "192.168.100.1${i + 1}"]
}
