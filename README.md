# Laboratorio: Clúster de Base de Datos en Alta Disponibilidad (HA) con Galera MariaDB

## 📖 Descripción General

Este proyecto es una implementación práctica de un clúster de base de datos distribuido y en Alta Disponibilidad (HA). Utiliza MariaDB con Galera Cluster desplegado sobre máquinas virtuales (KVM/libvirt), aprovisionadas con Terraform y configuradas automáticamente con Ansible.

El objetivo principal es aplicar los principios de los sistemas distribuidos: replicación síncrona multi-maestro, tolerancia a fallos y eliminación del Punto Único de Falla (SPOF).

---

## 🧠 Conceptos Aprendidos: ¿Qué hicimos y por qué funciona?

Durante esta actividad, pusimos a prueba varios conceptos fundamentales de los sistemas distribuidos:

### Alta Disponibilidad (HA) y Eliminación de SPOF:

- En una arquitectura tradicional (1 servidor de BD), si el servidor cae, la aplicación se detiene (SPOF).
- ¿Qué hicimos? Levantamos 3 nodos. Al apagar uno abruptamente (`virsh destroy`), el sistema continuó operando con los 2 restantes sin interrupción del servicio.

### Replicación Multi-Maestro (Active-Active):

- A diferencia del modelo tradicional "Maestro-Esclavo" (donde solo el maestro escribe), Galera permite que todos los nodos lean y escriban simultáneamente. Los datos escritos en el node1 se replican sincrónicamente en el node3 casi al instante.

### Quorum y Teorema CAP:

- Galera utiliza un sistema de Quorum (mayoría de votos) para evitar el problema del "Split-Brain" (cerebro dividido). Por eso se recomiendan clústeres de números impares (3, 5, 7).
- Al caer el Nodo 2, los nodos 1 y 3 formaron una mayoría (2 de 3, >50%), manteniendo el Quorum y asegurando la Consistencia de los datos.

---

## 🏗️ Arquitectura e Infraestructura

- **Virtualización:** QEMU/KVM (libvirt)  
- **Aprovisionamiento (IaC):** Terraform (main.tf). Crea 3 VMs basadas en Ubuntu.  
- **Gestión de Configuración:** Ansible (playbook.yml). Instala y configura el software.  
- **Clúster:** MariaDB 10.6 + Galera 4.  

---

## 🚀 Despliegue Paso a Paso

### 1. Despliegue de Infraestructura (Terraform)

Se definió la red y las 3 máquinas virtuales usando el proveedor de libvirt.

```bash
terraform init
terraform apply -auto-approve
```
### 2. Configuración Base (Ansible Playbook)

El playbook de Ansible se encargó de preparar las máquinas.

``` bash
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml
```

**¿Qué hizo el Playbook?**

- Actualizó repositorios.

- Instaló mariadb-server, mariadb-client, galera-4 y rsync.

- Apagó el servicio de MariaDB (fundamental antes de inyectar la configuración).

- Copió la plantilla galera.cnf.j2 a cada nodo, insertando dinámicamente sus IPs para que supieran cómo encontrarse entre sí.

---

### 3. Arranque del Clúster (El "Bootstrapping")

Aquí es donde repasamos los comandos de Ansible "rápidos". No podíamos simplemente encender los 3 nodos a la vez porque se quedarían esperando conectarse a un clúster inexistente.

**Paso A: Crear el Componente Primario (Nodo 1)**

``` bash
ansible -i ansible/inventory.yml node1 -m command -a "galera_new_cluster" -b
```

**Explicación:** El comando galera_new_cluster inicia MariaDB pasando un parámetro especial (--wsrep-new-cluster). Esto le dice al Nodo 1: "No busques a nadie, tú eres el origen del clúster".

**Paso B: Unir los Nodos Restantes (Nodo 2 y 3)**

``` bash
ansible -i ansible/inventory.yml node2,node3 -m service -a "name=mariadb state=started" -b
```

**Explicación:** Ahora que el clúster existe gracias al Nodo 1, encendemos MariaDB de forma normal en los nodos 2 y 3. Al leer su configuración (galera.cnf), detectan la IP del Nodo 1, se conectan a él y solicitan una copia del estado de la base de datos (SST - State Snapshot Transfer vía rsync).

**Paso C: Verificación**

``` bash
ansible -i ansible/inventory.yml node1 -m command -a 'mysql -u root -e "SHOW STATUS LIKE \"wsrep_cluster_size\";"' -b
```

**Explicación:** Ejecuta una consulta SQL rápida. Si devuelve 3, significa que los 3 nodos están sincronizados y vivos.

---

## 🌪️ Pruebas de Caos: Simulando un Fallo

Para comprobar la resiliencia del sistema, realizamos la siguiente secuencia:

Escritura inicial: Creamos una base de datos test_ha y escribimos un mensaje desde el Nodo 1.

Lectura remota: Leímos ese mismo mensaje desde el Nodo 3, comprobando la replicación síncrona.

**El Fallo: Simulamos un corte de energía en el Nodo 2 usando KVM:**

``` bash 
virsh destroy galera-node-2
```

**Comprobación de supervivencia:**

Al revisar el clúster desde el Nodo 1, el tamaño (wsrep_cluster_size) se redujo a 2.

A pesar de la falla, el clúster siguió operando. Insertamos un nuevo dato desde el Nodo 3 y lo leímos exitosamente desde el Nodo 1, demostrando que se eliminó el Punto Único de Falla.

---


# Laboratorio: Clúster de Base de Datos en Alta Disponibilidad (HA) con Galera MariaDB y Keepalived

## 📖 Descripción General

Este proyecto es una implementación práctica de un clúster de base de datos distribuido y en Alta Disponibilidad (HA). Utiliza MariaDB con Galera Cluster desplegado sobre máquinas virtuales (KVM/libvirt), aprovisionadas con Terraform y configuradas automáticamente (Zero Touch) con Ansible.

El objetivo principal es aplicar los principios de los sistemas distribuidos: replicación síncrona multi-maestro, tolerancia a fallos, balanceo de IPs y eliminación del Punto Único de Falla (SPOF) utilizando Keepalived para failover transparente.

---

## 🧠 Conceptos Aprendidos: ¿Qué hicimos y por qué funciona?

Durante esta actividad, pusimos a prueba varios conceptos fundamentales de los sistemas distribuidos de nivel producción:

### Alta Disponibilidad (HA) y Eliminación de SPOF:
- En una arquitectura tradicional (1 servidor de BD), si el servidor cae, la aplicación se detiene (SPOF).
- Levantamos 3 nodos. Al apagar uno abruptamente (`virsh destroy`), el sistema continuó operando con los restantes sin interrupción del servicio.

### IP Virtual (VIP) y Failover Transparente (Keepalived):
- Para que la caída de un nodo sea invisible para la aplicación cliente, implementamos Keepalived. Esto crea una IP Virtual (`192.168.100.200`) que "flota" entre los servidores.
- Si el nodo Máster (Nodo 1) cae, el nodo Backup (Nodo 2) detecta la falta de latidos (heartbeats) y asume la IP en menos de 1 segundo.

### Replicación Multi-Maestro (Active-Active):
- A diferencia del modelo tradicional "Maestro-Esclavo", Galera permite que todos los nodos lean y escriban simultáneamente. Los datos escritos en un nodo se replican sincrónicamente en los demás.

### Quorum, Teorema CAP y Split-Brain:
- Galera utiliza un sistema de Quorum (mayoría de votos) para evitar el "Split-Brain" (cerebro dividido). Al caer 1 nodo, los 2 restantes mantienen el Quorum (>50%), asegurando la consistencia de los datos.

---

## 🏗️ Arquitectura e Infraestructura

- **Virtualización:** QEMU/KVM (libvirt).
- **Aprovisionamiento (IaC):** Terraform (`main.tf`). Crea 3 VMs basadas en Ubuntu.
- **Gestión de Configuración:** Ansible (`playbook.yml`). Instala y orquesta todo el software.
- **Clúster:** MariaDB 10.6 + Galera 4.
- **Balanceo/Alta Disponibilidad:** Keepalived (Gestión de IP Virtual).

---

## 🚀 Despliegue Paso a Paso

### 1. Despliegue de Infraestructura (Terraform)
Se definió la red y las 3 máquinas virtuales usando el proveedor de libvirt.
```bash
terraform init
terraform apply -auto-approve
```

### 2. Configuración Base (Ansible Playbook)
El playbook de Ansible preparó las máquinas mediante un despliegue automatizado.
```bash
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -b
```
**¿Qué hace el Playbook actualmente?**
- Instala MariaDB, Galera, Keepalived y **HAProxy** en todos los nodos.
- Configura la **IP Virtual (192.168.100.200)** entre Node 1 y Node 2.
- Configura **HAProxy (Puerto 3307)** para balancear la carga entre los 3 nodos usando Round Robin.
- **Automatización de Usuarios:** Crea automáticamente el usuario `admin` y el usuario de salud `haproxy` en el Nodo 1 (replicándose al clúster).


### 3. Recuperación y Arranque del Clúster (Troubleshooting Real)
Como Ansible detuvo todos los nodos de golpe durante la configuración, Galera activó su protección anti-corrupción, bloqueando el arranque manual (safe_to_bootstrap: 0).

Solución aplicada: Forzamos al Nodo 1 como líder legítimo modificando su estado interno:

```bash
ansible -i ansible/inventory.yml node1 -m shell -a "sed -i 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/' /var/lib/mysql/grastate.dat" -b
```
Tras esto, iniciamos el clúster (Componente Primario):

```bash
ansible -i ansible/inventory.yml node1 -m command -a "galera_new_cluster" -b
```
Finalmente, iniciamos el servicio en los nodos restantes, los cuales se sincronizaron automáticamente (SST):
```bash
ansible -i ansible/inventory.yml node2,node3 -m service -a "name=mariadb state=started" -b
```

### 4. Verificación del Balanceo de Carga (HAProxy)
Para comprobar que el tráfico se distribuye equitativamente a través de la VIP:
```bash
# Ejecutar este comando varias veces desde tu máquina host
ansible -i ansible/inventory.yml node3 -m command -a "mysql -h 192.168.100.200 -P 3307 -u admin -padmin123 -e 'SHOW VARIABLES LIKE \"hostname\";'" -b
```

## 🌪️ Pruebas de Caos (Chaos Engineering)

Para comprobar la resiliencia absoluta del sistema, simulamos apagones catastróficos usando KVM (virsh destroy).

### Prueba 1: Failover de la IP Virtual (VIP)

    - Confirmamos que la IP 192.168.100.200 estaba en el Nodo 1.

    - Simulamos la destrucción del Nodo 1:

```bash
virsh destroy galera-node-1
```
    - Verificamos que el Nodo 2 detectó la caída y robó la IP automáticamente:

```bash
ansible -i ansible/inventory.yml node2 -m shell -a "ip a | grep 192.168.100.200" -b
```
(Resultado exitoso: La VIP apareció en el Nodo 2 en menos de 1 segundo).

### Prueba 2: Supervivencia del Clúster

Al revisar el clúster desde el Nodo 2 tras la caída del líder:

```bash
ansible -i ansible/inventory.yml node2 -m command -a 'mysql -e "SHOW STATUS LIKE \"wsrep_cluster_size\";"' -b
```

El tamaño (wsrep_cluster_size) se redujo a 2. A pesar de la falla del líder, la base de datos se mantuvo operativa, transaccional y sin interrupción para los clientes. ¡Alta Disponibilidad comprobada!

### Prueba 3: Supervivencia del Balanceo y la VIP
1. "Matamos" al nodo que tiene la VIP actualmente (ej. Node 1).
2. Verificamos que la VIP se mueve al Node 2.
3. Volvemos a lanzar la consulta de balanceo a la VIP:
```bash
ansible -i ansible/inventory.yml node3 -m command -a "mysql -h 192.168.100.200 -P 3307 -u admin -padmin123 -e 'SHOW VARIABLES LIKE \"hostname\";'" -b
```

---

## ⚖️ Balanceo de Carga con HAProxy
Para evitar sobrecargar un solo nodo, se implementó HAProxy en todos los servidores escuchando en el puerto `3307`. 
- **Flujo:** Cliente -> VIP (192.168.100.200) -> Puerto 3307 (HAProxy) -> Puerto 3306 (MariaDB Node 1, 2 o 3).
- Se configuró el algoritmo `roundrobin` y un usuario dedicado `admin` para las conexiones.