# Configuration Ansible pour Aruba OS Switches

## Collection requise

La bonne collection pour les switches Aruba OS (2530, 6100) est :

```bash
ansible-galaxy collection install arubanetworks.aos_switch
```

## Modules disponibles

Cette collection fournit les modules suivants :

- `arubanetworks.aos_switch.arubaoss_command` - Exécuter des commandes sur ArubaOS
- `arubanetworks.aos_switch.arubaoss_config` - Configurer ArubaOS
- `arubanetworks.aos_switch.arubaoss_facts` - Récupérer les facts ArubaOS

## Configuration de l'inventaire

```ini
[aruba_switches]
switch1 ansible_host=192.168.1.10 ansible_user=admin ansible_password=password

[aruba_switches:vars]
ansible_connection=network_cli
ansible_network_os=arubaoss
ansible_become=yes
ansible_become_method=enable
```

## Exemple de playbook

```yaml
---
- hosts: aruba_switches
  gather_facts: no
  tasks:
    - name: Récupérer les voisins LLDP
      arubanetworks.aos_switch.arubaoss_command:
        commands:
          - show lldp neighbors detail
      register: lldp_output

    - name: Afficher les résultats
      debug:
        var: lldp_output.stdout[0]
```

## Commandes Aruba OS utiles

- `show lldp neighbors detail` - Détails des voisins LLDP
- `show arp` - Table ARP
- `show system` - Informations système
- `show interfaces` - État des interfaces
- `show lldp configuration` - Configuration LLDP
- `show lldp statistics` - Statistiques LLDP

## Variables d'environnement

Pour une sécurité renforcée, utilisez des variables d'environnement :

```bash
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_GATHERING=explicit
export ANSIBLE_TIMEOUT=30
```
