# 🚀 Export vers Debian 12 - Guide Rapide

Ce guide vous accompagne pour transférer et installer le projet LLDP Discovery sur un serveur Debian 12.

## 📋 Méthodes de transfert

### Méthode 1 : Script automatique (Recommandé)

Depuis votre machine Windows, utilisez le script de transfert automatique :

```bash
# Dans WSL ou Git Bash
./transfer_to_debian.sh user@192.168.1.100

# Avec chemin personnalisé
./transfer_to_debian.sh user@debian-server:/opt/lldp-discovery

# Mode simulation (test sans transfert)
./transfer_to_debian.sh -n user@192.168.1.100
```

### Méthode 2 : SCP manuel

```bash
# Créer une archive
tar -czf lldp-discovery.tar.gz --exclude='.git' --exclude='lldp-env' --exclude='output/*.log' .

# Transférer l'archive
scp lldp-discovery.tar.gz user@debian-server:~/

# Sur le serveur Debian
ssh user@debian-server
tar -xzf lldp-discovery.tar.gz
cd LLDP-discover
```

### Méthode 3 : Git Clone

```bash
# Sur le serveur Debian
git clone https://votre-repo/lldp-discovery.git
cd lldp-discovery
```

## 🔧 Installation sur Debian

Une fois les fichiers transférés :

### 1. Installation automatique

```bash
# Rendre le script exécutable
chmod +x install_debian.sh

# Lancer l'installation
./install_debian.sh
```

### 2. Configuration système (optionnel)

```bash
# Configuration avancée du système
chmod +x setup_debian_system.sh
./setup_debian_system.sh
```

### 3. Configuration des switches

```bash
# Configurer les credentials
cp .env.example .env
nano .env

# Configurer les switches
nano python/switches_config.json
nano ansible/inventory.ini
```

### 4. Test et exécution

```bash
# Activer l'environnement
source lldp-env/bin/activate

# Tester la connectivité
python3 python/test_connectivity.py

# Lancer la découverte
./run_discovery.sh python -v
# ou
./run_discovery.sh ansible -vv
```

## 🛠️ Scripts disponibles

| Script | Description |
|--------|-------------|
| `install_debian.sh` | Installation complète automatique |
| `setup_debian_system.sh` | Configuration système optimisée |
| `run_discovery.sh` | Lancement rapide de la découverte |
| `transfer_to_debian.sh` | Transfert depuis Windows |
| `cleanup_lldp.sh` | Nettoyage des fichiers temporaires |

### 📡 Approches Ansible disponibles

En cas de problèmes avec les modules réseau Ansible, deux approches sont disponibles :

1. **Approche standard (recommandée)** : Utilise les modules réseau Ansible
   ```bash
   ./run_discovery.sh ansible -i ansible/inventory.ini
   ```

2. **Approche SSH directe (alternative)** : Utilise SSH direct si les modules réseau ne fonctionnent pas
   ```bash
   ./run_discovery.sh ansible -i ansible/inventory_ssh.ini
   cd ansible && ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv
   ```

### 🔧 Résolution des problèmes Ansible

Si vous obtenez des erreurs comme "network os arubaoss is not supported" :

1. **Vérifier la version d'Ansible :**
   ```bash
   ansible --version
   # Doit être >= 6.0.0
   ```

2. **Réinstaller Ansible si nécessaire :**
   ```bash
   pip uninstall ansible ansible-core
   pip install "ansible>=6.0.0,<8.0.0"
   ```

3. **Utiliser l'approche SSH directe :**
   ```bash
   # Installer sshpass si pas déjà fait
   sudo apt install sshpass
   
   # Lancer avec l'inventaire SSH
   cd ansible
   ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv
   ```

## ⚡ Utilisation rapide

### Avec les alias configurés

Après installation, ces commandes sont disponibles :

```bash
# Recharger les alias
source ~/.bashrc

# Activer l'environnement
lldp-activate

# Lancer découverte Python
lldp-python -v

# Lancer découverte Ansible  
lldp-ansible -vv

# Voir les logs
lldp-logs

# Afficher résultats
lldp-output

# Nettoyer
./cleanup_lldp.sh
```

### Variables d'environnement

```bash
# Charger la configuration
source .env

# Ou définir manuellement
export ARUBA_USERNAME="admin"
export ARUBA_PASSWORD="votre_password"

# Lancer avec variables
python3 python/lldp_discovery.py -v
```

## 🔒 Configuration sécurisée

### Permissions recommandées

```bash
# Scripts exécutables
chmod +x *.sh

# Fichiers de configuration protégés
chmod 600 .env
chmod 600 python/switches_config.json
chmod 600 ansible/inventory.ini

# Répertoire de sortie
chmod 755 output/
```

### Ansible Vault (recommandé)

```bash
# Chiffrer l'inventaire
ansible-vault encrypt ansible/inventory.ini

# Éditer l'inventaire chiffré
ansible-vault edit ansible/inventory.ini

# Lancer avec vault
ansible-playbook -i ansible/inventory.ini ansible/lldp_discovery.yml --ask-vault-pass
```

## 🚨 Dépannage

### Problèmes courants

1. **Permission denied**
   ```bash
   chmod +x *.sh
   ```

2. **Python non trouvé**
   ```bash
   sudo apt install python3 python3-pip python3-venv
   ```

3. **Erreur modules Python**
   ```bash
   source lldp-env/bin/activate
   pip install -r requirements.txt
   ```

4. **Timeout SSH**
   ```bash
   # Vérifier connectivité
   ping 192.168.1.10
   telnet 192.168.1.10 22
   ```

5. **Erreur "network os arubaoss is not supported"**
   ```bash
   # Corriger automatiquement
   ./fix_ansible.sh
   
   # Ou manuellement
   pip uninstall ansible ansible-core
   pip install "ansible>=6.0.0,<8.0.0"
   ansible-galaxy collection install arubanetworks.aos_switch --force
   ```

6. **Collection ansible.netcommon ne supporte pas Ansible version X.X.X**
   ```bash
   # Utiliser l'approche SSH directe
   cd ansible
   ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv
   ```

### Logs de debug

```bash
# Logs détaillés Python
python3 python/lldp_discovery.py -v

# Logs Ansible très verbeux  
ansible-playbook -i ansible/inventory.ini ansible/lldp_discovery.yml -vvv

# Logs système
tail -f /var/log/syslog
journalctl -f
```

## 📊 Vérification de l'installation

### Tests de base

```bash
# Version Python
python3 --version

# Modules installés
pip list | grep -E "(netmiko|paramiko|ansible)"

# Connectivité réseau
nmap -p 22 192.168.1.10

# Test LLDP
ssh admin@192.168.1.10 "show lldp neighbors"
```

### Tests fonctionnels

```bash
# Test connectivité switches
python3 python/test_connectivity.py

# Test découverte simple
./run_discovery.sh python -c python/switches_config.json -o /tmp/test.json

# Vérifier sortie
cat /tmp/test.json | jq .
```

## 🔄 Automatisation

### Service systemd

```bash
# Activer le service (créé par setup_debian_system.sh)
sudo systemctl enable lldp-discovery.timer
sudo systemctl start lldp-discovery.timer

# Vérifier le statut
sudo systemctl status lldp-discovery.timer
```

### Cron job manuel

```bash
# Éditer crontab
crontab -e

# Ajouter tâche horaire
0 * * * * cd /path/to/lldp-discovery && ./run_discovery.sh python >> output/cron.log 2>&1
```

## 📞 Support

En cas de problème :

1. Vérifiez les logs : `tail -f output/lldp_discovery.log`
2. Testez la connectivité : `./run_discovery.sh python --test-only`
3. Consultez les issues sur GitHub
4. Utilisez le mode debug : `-vvv` pour Ansible, `-v` pour Python
