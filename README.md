# LLDP Discovery pour Switches Aruba 2530 et 6100

Ce projet permet de découvrir automatiquement les équipements connectés aux switches Aruba 2530 et 6100 via le protocole LLDP (Link Layer Discovery Protocol). Il récupère les adresses MAC, IP et hostname des équipements connectés et génère des rapports au format JSON.

## 🎯 Objectifs

- Récupérer les informations des équipements connectés : adresses MAC, IP et hostname
- Supporter les switches Aruba 2530 et 6100
- Fournir des solutions en Python et Ansible
- Générer des rapports au format JSON structurés

## 📁 Structure du projet

```
LLDP-discover/
├── python/                    # Scripts Python
│   ├── lldp_discovery.py     # Script principal de découverte
│   └── switches_config.json  # Configuration des switches
├── ansible/                   # Playbooks Ansible
│   ├── lldp_discovery.yml    # Playbook principal
│   ├── inventory.ini         # Inventaire des switches
│   ├── requirements.yml      # Dépendances Ansible
│   └── filter_plugins/       # Filtres personnalisés
│       └── aruba_filters.py
├── output/                    # Répertoire de sortie
├── requirements.txt           # Dépendances Python
└── README.md                 # Documentation
```

## 🚀 Installation

### Prérequis

- Python 3.8 ou supérieur
- Ansible 2.9 ou supérieur (pour l'approche Ansible)
- Accès SSH aux switches Aruba
- Connectivité réseau vers les switches

### Installation sur Debian 12

1. **Mettre à jour le système :**

```bash
sudo apt update && sudo apt upgrade -y
```

2. **Installer Python et pip :**

```bash
sudo apt install python3 python3-pip python3-venv git -y
```

3. **Créer un environnement virtuel (recommandé) :**

```bash
python3 -m venv lldp-env
source lldp-env/bin/activate
```

4. **Installer les dépendances Python :**

```bash
pip install -r requirements.txt
```

### Installation Ansible

1. **Installer Ansible :**

```bash
pip install ansible
```

2. **Installer les collections Aruba :**

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

## 🐧 Installation sur Debian 12

### Installation automatique

Pour une installation complète et automatisée sur Debian 12 :

```bash
# Cloner ou transférer le projet
git clone <votre-repo> lldp-discovery
# ou
scp -r LLDP-discover/ user@debian-server:~/

# Se rendre dans le répertoire
cd lldp-discovery

# Rendre les scripts exécutables
chmod +x *.sh

# Installation des dépendances
./install_debian.sh

# Configuration système (optionnel mais recommandé)
./setup_debian_system.sh
```

### Installation manuelle

Si vous préférez une installation manuelle :

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation des paquets nécessaires
sudo apt install -y python3 python3-pip python3-venv git jq ssh nmap

# Création de l'environnement virtuel
python3 -m venv lldp-env
source lldp-env/bin/activate

# Installation des dépendances Python
pip install -r requirements.txt

# Installation des collections Ansible
cd ansible
ansible-galaxy collection install -r requirements.yml
cd ..
```

### Configuration rapide

1. **Configurer les variables d'environnement :**

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer vos credentials
nano .env

# Charger les variables
source .env
```

2. **Tester l'installation :**

```bash
# Activer l'environnement
source lldp-env/bin/activate

# Tester la connectivité
python3 python/test_connectivity.py

# Lancer une découverte de test
./run_discovery.sh python -v
```

### Scripts d'aide disponibles

- `install_debian.sh` : Installation automatique complète
- `setup_debian_system.sh` : Configuration système optimisée
- `run_discovery.sh` : Script de lancement rapide
- `activate_env.sh` : Activation rapide de l'environnement
- `cleanup_lldp.sh` : Nettoyage des fichiers temporaires

### Alias bash configurés

Après l'installation, ces alias seront disponibles :

```bash
lldp-activate     # Activer l'environnement virtuel
lldp-python -v    # Lancer découverte Python avec verbosité
lldp-ansible -vv  # Lancer découverte Ansible avec verbosité
lldp-logs         # Voir les logs en temps réel
lldp-output       # Afficher le JSON de sortie formaté
lldp-check        # Tester la connectivité aux switches
```

## ⚙️ Configuration

### Configuration Python

Éditez le fichier `python/switches_config.json` :

```json
{
  "switches": [
    {
      "host": "192.168.1.10",
      "username": "admin",
      "password": "votre_mot_de_passe",
      "device_type": "aruba_os",
      "model": "2530",
      "description": "Aruba 2530 Switch - Bâtiment A"
    },
    {
      "host": "192.168.1.11",
      "username": "admin", 
      "password": "votre_mot_de_passe",
      "device_type": "aruba_os",
      "model": "6100",
      "description": "Aruba 6100 Switch - Bâtiment B"
    }
  ]
}
```

### Configuration Ansible

Éditez le fichier `ansible/inventory.ini` :

```ini
[aruba_switches]
aruba-2530-01 ansible_host=192.168.1.10 ansible_user=admin ansible_password=votre_mot_de_passe
aruba-6100-01 ansible_host=192.168.1.20 ansible_user=admin ansible_password=votre_mot_de_passe

[aruba_switches:vars]
ansible_connection=network_cli
ansible_network_os=arubaoss
```

## 🏃‍♂️ Utilisation

### Approche Python

1. **Exécution basique :**

```bash
python3 python/lldp_discovery.py
```

2. **Avec options personnalisées :**

```bash
python3 python/lldp_discovery.py -c python/switches_config.json -o output/ma_decouverte.json -v
```

### Approche Ansible

1. **Exécution du playbook :**

```bash
cd ansible
ansible-playbook -i inventory.ini lldp_discovery.yml
```

2. **Avec verbosité :**

```bash
ansible-playbook -i inventory.ini lldp_discovery.yml -vv
```

## 📊 Format de sortie JSON

Le fichier JSON généré contient la structure suivante :

```json
{
  "discovery_timestamp": "2025-07-10T10:30:00",
  "switches": {
    "192.168.1.10": {
      "switch_ip": "192.168.1.10",
      "timestamp": "2025-07-10T10:30:00",
      "neighbors_count": 3,
      "neighbors": [
        {
          "local_port": "1/1/1",
          "remote_chassis_id": "aa:bb:cc:dd:ee:ff",
          "remote_port_id": "GigabitEthernet0/1",
          "remote_system_name": "PC-USER-001",
          "remote_system_description": "Windows 10 Workstation",
          "remote_port_description": "Network Adapter",
          "management_addresses": ["192.168.1.100"],
          "ip_addresses": ["192.168.1.100"],
          "mac_address": "aa:bb:cc:dd:ee:ff",
          "hostname": "PC-USER-001"
        }
      ]
    }
  },
  "summary": {
    "total_switches": 2,
    "successful_connections": 2,
    "total_neighbors": 5
  }
}
```

## 🛠️ Options de ligne de commande (Python)

- `-c, --config` : Fichier de configuration des switches (défaut: `python/switches_config.json`)
- `-o, --output` : Fichier de sortie JSON (défaut: `output/lldp_discovery.json`)
- `-v, --verbose` : Mode verbose pour plus de logs

## 📝 Logs

Les logs sont automatiquement générés dans :
- Fichier : `output/lldp_discovery.log`
- Console : Affichage en temps réel

## 🔒 Sécurité

⚠️ **Important** : Ne jamais commiter les mots de passe dans le code !

Recommandations :
- Utiliser des variables d'environnement pour les credentials
- Utiliser Ansible Vault pour chiffrer les mots de passe
- Configurer des comptes de service dédiés avec permissions minimales

### Exemple avec variables d'environnement :

```bash
export ARUBA_USERNAME="admin"
export ARUBA_PASSWORD="votre_mot_de_passe"
python3 python/lldp_discovery.py
```

## 🧪 Tests et validation

### Vérification de connectivité

```powershell
# Test de connectivité SSH
ssh admin@192.168.1.10

# Test des commandes LLDP sur le switch
show lldp neighbors detail
show arp
```

### Tests du script Python

```bash
# Lancement avec mode verbose
python3 python/lldp_discovery.py -v

# Vérification du fichier de sortie
cat output/lldp_discovery.json | jq .

# Si jq n'est pas installé :
sudo apt install jq -y
```

## 🐛 Dépannage

### Erreurs communes

1. **Timeout de connexion :**
   - Vérifier la connectivité réseau
   - Augmenter le timeout dans le code

2. **Erreur d'authentification :**
   - Vérifier les credentials
   - Confirmer les permissions du compte

3. **Pas de voisins LLDP :**
   - Vérifier que LLDP est activé sur les switches
   - Confirmer que les équipements supportent LLDP

### Commandes de diagnostic

```bash
# Vérification LLDP sur le switch
show lldp configuration
show lldp statistics

# Test de parsing des données
python3 -c "import json; print(json.load(open('output/lldp_discovery.json')))"

# Vérification des logs
tail -f output/lldp_discovery.log

# Test de connectivité réseau
ping 192.168.1.10
nmap -p 22 192.168.1.10
```

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amelioration`)
3. Commit les changements (`git commit -am 'Ajout de fonctionnalité'`)
4. Push vers la branche (`git push origin feature/amelioration`)
5. Créer une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- Créer une issue sur GitHub
- Consulter la documentation Aruba LLDP
- Vérifier les logs de debug
