#!/bin/bash

# Script de vérification et correction de l'installation Ansible
# Usage: ./fix_ansible.sh

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

echo "🔧 Vérification et correction de l'installation Ansible"
echo "======================================================"

# Activer l'environnement virtuel si disponible
if [ -d "lldp-env" ]; then
    source lldp-env/bin/activate
    print_status "Environnement virtuel activé"
fi

# Vérifier la version d'Ansible
print_status "Vérification de la version d'Ansible..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    print_status "Version Ansible détectée: $ANSIBLE_VERSION"
    
    # Vérifier si la version est compatible
    MAJOR=$(echo $ANSIBLE_VERSION | cut -d. -f1)
    MINOR=$(echo $ANSIBLE_VERSION | cut -d. -f2)
    
    if [ "$MAJOR" -lt 6 ] || ([ "$MAJOR" -eq 2 ] && [ "$MINOR" -lt 13 ]); then
        print_warning "Version Ansible incompatible détectée: $ANSIBLE_VERSION"
        print_status "Mise à jour d'Ansible vers une version compatible..."
        
        # Désinstaller l'ancienne version
        pip uninstall -y ansible ansible-core || true
        
        # Installer la bonne version
        pip install "ansible>=6.0.0,<8.0.0"
        
        ANSIBLE_VERSION=$(ansible --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        print_success "Ansible mis à jour vers la version: $ANSIBLE_VERSION"
    else
        print_success "Version Ansible compatible: $ANSIBLE_VERSION"
    fi
else
    print_warning "Ansible non installé, installation en cours..."
    pip install "ansible>=6.0.0,<8.0.0"
    print_success "Ansible installé"
fi

# Vérifier les collections
print_status "Vérification des collections Ansible..."
cd ansible

# Installer les collections requises
if [ -f "requirements.yml" ]; then
    print_status "Installation des collections depuis requirements.yml..."
    ansible-galaxy collection install -r requirements.yml --force
else
    print_status "Installation manuelle des collections..."
    ansible-galaxy collection install arubanetworks.aos_switch --force
    ansible-galaxy collection install ansible.netcommon --force
    ansible-galaxy collection install community.general --force
fi

print_success "Collections installées"

# Vérifier sshpass
print_status "Vérification de sshpass..."
if ! command -v sshpass &> /dev/null; then
    print_warning "sshpass non installé, installation..."
    sudo apt update && sudo apt install -y sshpass
    print_success "sshpass installé"
else
    print_success "sshpass disponible"
fi

# Test de base d'Ansible
print_status "Test de base d'Ansible..."
echo "localhost ansible_connection=local" > test_inventory.ini
if ansible all -i test_inventory.ini -m ping > /dev/null 2>&1; then
    print_success "Test Ansible réussi"
else
    print_error "Test Ansible échoué"
fi
rm -f test_inventory.ini

cd ..

# Afficher les informations finales
echo
print_success "🎉 Vérification terminée !"
echo
echo "📋 Informations d'installation :"
echo "   Ansible version: $(ansible --version | head -n1)"
echo "   Collections installées: $(ansible-galaxy collection list | grep -E '(arubanetworks|ansible)' | wc -l)"
echo "   sshpass: $(command -v sshpass > /dev/null && echo 'Installé' || echo 'Non installé')"
echo
echo "🚀 Commandes de test disponibles :"
echo "   # Test connectivité Ansible standard"
echo "   ./run_discovery.sh test"
echo
echo "   # Test avec approche SSH directe"
echo "   cd ansible && ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml --check"
echo
echo "   # Lancer découverte complète"
echo "   ./run_discovery.sh ansible -vv"
