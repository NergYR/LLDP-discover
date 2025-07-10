# 🖥️ Commandes à exécuter sur la machine distante Debian 12

## 📥 Étape 1 : Réception des fichiers

### Si vous utilisez le script de transfert automatique :
```bash
# Les fichiers arrivent automatiquement, passer à l'étape 2
```

### Si vous recevez une archive :
```bash
# Extraire l'archive
cd ~
tar -xzf lldp-discovery.tar.gz
cd LLDP-discover
```

### Si vous clonez depuis Git :
```bash
cd ~
git clone https://votre-repo/lldp-discovery.git
cd lldp-discovery
```

## 🚀 Étape 2 : Installation automatique (RECOMMANDÉ)

```bash
# Rendre le script exécutable
chmod +x install_debian.sh

# Lancer l'installation complète
./install_debian.sh
```

**⏰ Durée estimée : 3-5 minutes**

## 🔧 Étape 3 : Configuration

### Configuration des credentials (OBLIGATOIRE)
```bash
# Copier le modèle d'environnement
cp .env.example .env

# Éditer les credentials
nano .env
```

**Contenu du fichier .env :**
```bash
ARUBA_USERNAME=admin
ARUBA_PASSWORD=votre_mot_de_passe
ARUBA_DEFAULT_TIMEOUT=30
```

### Configuration des switches (OBLIGATOIRE)
```bash
# Éditer la configuration Python
nano python/switches_config.json
```

**Exemple de configuration :**
```json
{
    "switches": [
        {
            "host": "192.168.1.10",
            "device_type": "aruba_os",
            "username": "admin",
            "password": "votre_password",
            "timeout": 30
        },
        {
            "host": "192.168.1.11", 
            "device_type": "aruba_os",
            "username": "admin",
            "password": "votre_password",
            "timeout": 30
        }
    ]
}
```

### Configuration Ansible
```bash
# Éditer l'inventaire Ansible
nano ansible/inventory.ini
```

**Exemple d'inventaire :**
```ini
[aruba_switches]
switch1 ansible_host=192.168.1.10 ansible_network_os=arubaoss
switch2 ansible_host=192.168.1.11 ansible_network_os=arubaoss

[aruba_switches:vars]
ansible_user=admin
ansible_password=votre_password
ansible_connection=network_cli
ansible_become=no
```

## ✅ Étape 4 : Tests

### Activer l'environnement
```bash
# Activer l'environnement virtuel Python
source lldp-env/bin/activate

# Ou utiliser le script rapide
./activate_env.sh
```

### Test de connectivité
```bash
# Tester la connexion aux switches
python3 python/test_connectivity.py
```

### Test de découverte rapide
```bash
# Test avec Python (recommandé)
./run_discovery.sh python --test

# Test avec Ansible
./run_discovery.sh ansible --check
```

## 🎯 Étape 5 : Première exécution complète

### Méthode Python (RECOMMANDÉE)
```bash
# Exécution avec logs détaillés
./run_discovery.sh python -v

# Ou directement
python3 python/lldp_discovery.py -v
```

### Méthode Ansible (alternative)
```bash
# Approche standard
./run_discovery.sh ansible -vv

# Ou directement
cd ansible
ansible-playbook -i inventory.ini lldp_discovery.yml -vv
```

### Si problème avec Ansible - Approche SSH directe
```bash
# Installation de sshpass si nécessaire
sudo apt install sshpass

# Utiliser l'inventaire SSH
cd ansible
ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv
```

## 📊 Étape 6 : Vérification des résultats

```bash
# Voir les fichiers générés
ls -la output/

# Afficher le résultat JSON
cat output/lldp_discovery_$(date +%Y%m%d).json | jq .

# Voir les logs
tail -f output/lldp_discovery.log
```

## 🚨 En cas de problème - SOLUTIONS RAPIDES

### Solution universelle (répare tout)
```bash
# Script de réparation automatique
chmod +x quick_fix.sh
./quick_fix.sh

# Puis réactiver l'environnement
./activate_env.sh
```

### Problème spécifique Ansible
```bash
# Réparation Ansible uniquement
chmod +x fix_ansible.sh
./fix_ansible.sh
```

### Diagnostic rapide
```bash
# Vérifier l'environnement
echo "Python: $(python3 --version)"
echo "Environnement virtuel: $VIRTUAL_ENV"
echo "Ansible: $(ansible --version 2>/dev/null || echo 'Non installé')"

# Tester connectivité réseau
ping -c 3 192.168.1.10
ssh -o ConnectTimeout=5 admin@192.168.1.10 exit
```

### Test minimal
```bash
# Test de connectivité basique
python3 -c "
import socket
try:
    sock = socket.create_connection(('192.168.1.10', 22), timeout=5)
    sock.close()
    print('✅ Connexion SSH OK')
except:
    print('❌ Problème de connexion')
"
```

## 🔄 Utilisation quotidienne

### Commandes rapides (après installation)
```bash
# Activer l'environnement
source ~/.bashrc  # Recharge les alias
lldp-activate     # Ou ./activate_env.sh

# Lancer une découverte
lldp-python -v    # Ou ./run_discovery.sh python -v

# Voir les résultats
lldp-output       # Ou ls -la output/

# Voir les logs en temps réel
lldp-logs         # Ou tail -f output/lldp_discovery.log
```

### Nettoyage périodique
```bash
# Nettoyer les anciens fichiers
./cleanup_lldp.sh

# Nettoyer les logs de plus de 7 jours
find output/ -name "*.log" -mtime +7 -delete
```

## ⚙️ Configuration avancée (optionnel)

### Service systemd automatique
```bash
# Installer la configuration système avancée
chmod +x setup_debian_system.sh
./setup_debian_system.sh

# Activer le service de découverte automatique
sudo systemctl enable lldp-discovery.timer
sudo systemctl start lldp-discovery.timer

# Vérifier le statut
sudo systemctl status lldp-discovery.timer
```

### Cron job manuel
```bash
# Éditer le crontab
crontab -e

# Ajouter une ligne pour exécution toutes les heures
0 * * * * cd /home/$USER/LLDP-discover && ./run_discovery.sh python >> output/cron.log 2>&1
```

## 📋 Checklist de validation

- [ ] Archive extraite ou fichiers reçus
- [ ] Script `install_debian.sh` exécuté avec succès
- [ ] Fichier `.env` configuré avec les bons credentials
- [ ] Fichier `python/switches_config.json` configuré
- [ ] Test de connectivité réussi
- [ ] Première découverte réussie
- [ ] Fichier JSON généré dans `output/`
- [ ] Logs visibles dans `output/lldp_discovery.log`

## 🆘 Numéros d'urgence (codes d'erreur)

### Erreur "ansible_date_time is undefined"
```bash
# Solution automatique (recommandée)
chmod +x fix_ansible_facts.sh
./fix_ansible_facts.sh

# Puis retenter
cd ansible && ansible-playbook -i inventory.ini lldp_discovery.yml --check

# Si ça ne marche toujours pas, utiliser l'approche SSH :
cd ansible && ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv
```

### Erreur "externally-managed-environment"
```bash
./quick_fix.sh  # Solution automatique
```

### Erreur "network os arubaoss is not supported"
```bash
./fix_ansible.sh  # Solution automatique
# OU utiliser l'approche SSH :
cd ansible && ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv
```

### Erreur "No module named 'netmiko'"
```bash
source lldp-env/bin/activate
pip install -r requirements.txt
```

### Erreur "Connection timeout"
```bash
# Vérifier la connectivité réseau
ping 192.168.1.10
telnet 192.168.1.10 22

# Augmenter le timeout dans switches_config.json
nano python/switches_config.json  # "timeout": 60
```

## 📞 Support

**En cas de problème persistant :**

1. **Collecter les logs :**
   ```bash
   # Logs de la dernière exécution
   tail -100 output/lldp_discovery.log > debug.log
   
   # Informations système
   echo "=== SYSTEM INFO ===" >> debug.log
   uname -a >> debug.log
   python3 --version >> debug.log
   pip list | grep -E "(ansible|netmiko)" >> debug.log
   ```

2. **Test de diagnostic complet :**
   ```bash
   # Exécuter avec maximum de détails
   ./run_discovery.sh python -v -d > diagnostic.log 2>&1
   ```

3. **Envoyer les fichiers :** `debug.log` et `diagnostic.log`

---

**🎉 Félicitations ! Votre système de découverte LLDP est maintenant opérationnel !**
