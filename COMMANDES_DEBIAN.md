# 🖥️ Commandes à exécuter sur la machine distante Debian 12

## 📥 Étape 1 : Récupération des fichiers

### Option A : Via transfert SCP (depuis votre machine Windows)
```bash
# Sur votre machine Windows (WSL/Git Bash)
./transfer_to_debian.sh user@IP_DEBIAN

# Puis sur la machine Debian
cd LLDP-discover
```

### Option B : Via Git Clone (directement sur Debian)
```bash
git clone https://votre-repo/lldp-discovery.git
cd lldp-discovery
```

### Option C : Via archive manuelle
```bash
# Extraire l'archive transférée
tar -xzf lldp-discovery.tar.gz
cd LLDP-discover
```

## 🚀 Étape 2 : Installation automatique

```bash
# Rendre les scripts exécutables
chmod +x *.sh

# Lancer l'installation complète
./install_debian.sh
```

**Cette commande va automatiquement :**
- Installer Python 3, pip, venv
- Créer l'environnement virtuel `lldp-env`
- Installer toutes les dépendances Python
- Installer Ansible et les collections nécessaires
- Configurer les permissions
- Créer les alias utiles

## 🔧 Étape 3 : Configuration

### Configuration des credentials
```bash
# Copier le template de configuration
cp .env.example .env

# Éditer les credentials (remplacer par vos vraies valeurs)
nano .env
```

**Contenu du fichier .env :**
```bash
ARUBA_USERNAME=admin
ARUBA_PASSWORD=votre_mot_de_passe
ARUBA_ENABLE_PASSWORD=votre_mot_de_passe_enable
DEFAULT_TIMEOUT=30
SSH_PORT=22
```

### Configuration des switches
```bash
# Éditer la liste des switches
nano python/switches_config.json
```

**Exemple de contenu :**
```json
{
    "switches": [
        {
            "ip": "192.168.1.10",
            "hostname": "SW-ARUBA-01",
            "device_type": "hp_comware_ssh",
            "port": 22
        },
        {
            "ip": "192.168.1.11", 
            "hostname": "SW-ARUBA-02",
            "device_type": "hp_comware_ssh",
            "port": 22
        }
    ]
}
```

### Configuration Ansible
```bash
# Éditer l'inventaire Ansible
nano ansible/inventory.ini
```

**Exemple de contenu :**
```ini
[aruba_switches]
192.168.1.10 ansible_host=192.168.1.10 hostname=SW-ARUBA-01
192.168.1.11 ansible_host=192.168.1.11 hostname=SW-ARUBA-02

[aruba_switches:vars]
ansible_network_os=arubaoss
ansible_user=admin
ansible_password=votre_mot_de_passe
ansible_connection=network_cli
ansible_become=yes
ansible_become_method=enable
ansible_become_password=votre_mot_de_passe_enable
```

## ✅ Étape 4 : Test de fonctionnement

### Test rapide de l'environnement
```bash
# Activer l'environnement virtuel
source lldp-env/bin/activate

# Vérifier les versions
python3 --version
ansible --version
pip list | grep -E "(netmiko|paramiko|ansible)"
```

### Test de connectivité
```bash
# Tester la connectivité aux switches
python3 python/test_connectivity.py
```

### Premier test de découverte
```bash
# Test avec Python (recommandé pour débuter)
./run_discovery.sh python -v

# Vérifier le résultat
cat output/lldp_discovery_$(date +%Y%m%d).json | jq .
```

## 🎯 Étape 5 : Utilisation normale

### Commandes principales
```bash
# Activer l'environnement (à faire à chaque session)
source lldp-env/bin/activate

# Ou utiliser le script rapide
./activate_env.sh

# Lancer découverte Python (simple et fiable)
./run_discovery.sh python -v

# Lancer découverte Ansible (plus avancé)
./run_discovery.sh ansible -vv

# Lancer test de connectivité seulement
./run_discovery.sh test
```

### Avec les alias (si configurés)
```bash
# Recharger les alias
source ~/.bashrc

# Utiliser les alias
lldp-activate    # Activer l'environnement
lldp-python -v   # Découverte Python
lldp-ansible -vv # Découverte Ansible
lldp-logs        # Voir les logs
lldp-output      # Voir les résultats
```

## 🚑 En cas de problème

### Solution universelle (réparation rapide)
```bash
# Si quelque chose ne marche pas
./quick_fix.sh

# Puis réactiver l'environnement
./activate_env.sh

# Et relancer un test
./run_discovery.sh test
```

### Diagnostic des erreurs courantes
```bash
# Vérifier l'environnement
echo $VIRTUAL_ENV
which python3
which ansible

# Tester connectivité réseau
ping 192.168.1.10
ssh -o ConnectTimeout=5 admin@192.168.1.10 exit

# Vérifier les modules Python
pip list | grep netmiko
```

### Utiliser l'approche SSH directe en cas d'erreur Ansible
```bash
# Si les modules réseau Ansible ne marchent pas
cd ansible
ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv
```

## 📊 Vérification des résultats

### Consulter les logs
```bash
# Logs de la dernière exécution
tail -f output/lldp_discovery.log

# Logs avec horodatage
tail -f output/lldp_discovery_$(date +%Y%m%d).log
```

### Consulter les résultats JSON
```bash
# Dernier fichier généré
ls -la output/*.json | tail -1

# Afficher avec formatage
cat output/lldp_discovery_$(date +%Y%m%d).json | jq .

# Compter les équipements découverts
cat output/lldp_discovery_$(date +%Y%m%d).json | jq '.switches[].neighbors | length'
```

## 🔄 Automatisation (optionnel)

### Créer une tâche cron
```bash
# Éditer crontab
crontab -e

# Ajouter ligne pour exécution toutes les heures
0 * * * * cd /path/to/LLDP-discover && source lldp-env/bin/activate && ./run_discovery.sh python >> output/cron.log 2>&1
```

### Utiliser le service systemd (si configuré)
```bash
# Activer le service automatique
sudo systemctl enable lldp-discovery.timer
sudo systemctl start lldp-discovery.timer

# Vérifier le statut
sudo systemctl status lldp-discovery.timer
```

## 📝 Résumé des commandes essentielles

```bash
# 1. Installation (une seule fois)
chmod +x *.sh && ./install_debian.sh

# 2. Configuration (une seule fois)
cp .env.example .env && nano .env
nano python/switches_config.json

# 3. Utilisation quotidienne
source lldp-env/bin/activate
./run_discovery.sh python -v

# 4. En cas de problème
./quick_fix.sh && ./activate_env.sh

# 5. Voir les résultats
cat output/lldp_discovery_$(date +%Y%m%d).json | jq .
```

---

## ⚡ Séquence complète d'installation

Voici la séquence complète à copier-coller :

```bash
# Récupération des fichiers (choisir une méthode)
# ... transfert ou git clone ...

# Installation et configuration
cd LLDP-discover
chmod +x *.sh
./install_debian.sh
cp .env.example .env
nano .env  # Configurer vos credentials
nano python/switches_config.json  # Configurer vos switches

# Test
source lldp-env/bin/activate
python3 python/test_connectivity.py
./run_discovery.sh python -v

# Vérification
cat output/lldp_discovery_$(date +%Y%m%d).json | jq .
```

**🎯 Voilà ! Votre système de découverte LLDP est prêt à fonctionner.**
