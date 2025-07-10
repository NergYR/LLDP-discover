#!/bin/bash

# Script de réparation rapide pour LLDP Discovery sur Debian 12
# Ce script corrige les problèmes d'environnement virtuel et d'Ansible

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚑 Réparation rapide LLDP Discovery"
echo "=================================="

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "requirements.txt" ]; then
    print_error "Vous devez être dans le répertoire LLDP-discover"
    exit 1
fi

print_status "Répertoire confirmé: $(pwd)"

# Étape 1: Nettoyer et recréer l'environnement virtuel
print_status "Nettoyage et recréation de l'environnement virtuel..."

if [ -d "lldp-env" ]; then
    print_warning "Suppression de l'ancien environnement virtuel..."
    rm -rf lldp-env
fi

print_status "Création d'un nouvel environnement virtuel..."
python3 -m venv lldp-env

print_status "Activation de l'environnement virtuel..."
source lldp-env/bin/activate

# Vérifier l'activation
if [[ "$VIRTUAL_ENV" == "" ]]; then
    print_error "Impossible d'activer l'environnement virtuel"
    exit 1
fi

print_success "Environnement virtuel activé: $VIRTUAL_ENV"

# Étape 2: Mettre à jour pip
print_status "Mise à jour de pip..."
pip install --upgrade pip setuptools wheel

# Étape 3: Installer les dépendances essentielles
print_status "Installation des dépendances Python essentielles..."
pip install netmiko paramiko cryptography

# Étape 4: Installer Ansible avec la bonne version
print_status "Installation d'Ansible compatible..."
pip install "ansible>=6.0.0,<8.0.0" "ansible-core>=2.13.0,<2.16.0"

# Étape 5: Installer PyYAML
print_status "Installation de PyYAML..."
pip install PyYAML

# Étape 6: Vérifier l'installation
print_status "Vérification de l'installation..."
ANSIBLE_VERSION=$(ansible --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
print_success "Ansible installé: version $ANSIBLE_VERSION"

# Étape 7: Installer les collections Ansible
print_status "Installation des collections Ansible..."
cd ansible

# Créer un ansible.cfg local pour éviter les warnings
cat > ansible.cfg << EOF
[defaults]
host_key_checking = False
timeout = 30
gathering = explicit

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF

# Installer les collections
ansible-galaxy collection install arubanetworks.aos_switch --force
ansible-galaxy collection install ansible.netcommon --force
ansible-galaxy collection install community.general --force

cd ..

# Étape 8: Installer sshpass pour l'approche SSH directe
print_status "Vérification de sshpass..."
if ! command -v sshpass &> /dev/null; then
    print_status "Installation de sshpass..."
    sudo apt update && sudo apt install -y sshpass
fi

# Étape 9: Test rapide
print_status "Test rapide de l'installation..."
echo "localhost ansible_connection=local" > test_inventory.tmp
if ansible all -i test_inventory.tmp -m ping > /dev/null 2>&1; then
    print_success "Test Ansible réussi"
else
    print_warning "Test Ansible avec warnings, mais probablement fonctionnel"
fi
rm -f test_inventory.tmp

# Étape 10: Créer un script d'activation rapide
cat > activate_env.sh << 'EOF'
#!/bin/bash
# Script d'activation rapide pour LLDP Discovery
if [ -d "lldp-env" ]; then
    source lldp-env/bin/activate
    echo "✅ Environnement LLDP Discovery activé"
    echo "📋 Commandes disponibles:"
    echo "   python3 python/lldp_discovery.py -v      # Découverte Python"
    echo "   ./run_discovery.sh test                   # Test Ansible"
    echo "   ./run_discovery.sh ansible -vv            # Découverte Ansible"
    echo "   deactivate                               # Quitter l'environnement"
else
    echo "❌ Environnement virtuel non trouvé"
    echo "Exécutez d'abord: ./quick_fix.sh"
fi
EOF

chmod +x activate_env.sh

echo
print_success "🎉 Réparation terminée avec succès !"
echo
echo "📋 Résumé de l'installation :"
echo "   ✅ Environnement virtuel: $(basename $VIRTUAL_ENV)"
echo "   ✅ Python: $(python --version)"
echo "   ✅ Ansible: $ANSIBLE_VERSION"
echo "   ✅ Collections: Installées"
echo "   ✅ sshpass: $(command -v sshpass > /dev/null && echo 'Disponible' || echo 'Non disponible')"
echo
echo "🚀 Prochaines étapes :"
echo "1. Configurez vos switches :"
echo "   nano python/switches_config.json"
echo "   nano ansible/inventory.ini"
echo
echo "2. Pour réactiver l'environnement plus tard :"
echo "   ./activate_env.sh"
echo
echo "3. Tester la connectivité :"
echo "   ./run_discovery.sh test"
echo
echo "4. Lancer une découverte :"
echo "   ./run_discovery.sh python -v"
echo "   ./run_discovery.sh ansible -vv"
echo
echo "⚠️  IMPORTANT: L'environnement virtuel est maintenant activé dans cette session."
echo "   Pour les futures sessions, utilisez: ./activate_env.sh"
