#!/bin/bash

# Script de test pour vérifier la correction de l'erreur 'NoneType' object is not iterable

echo "=========================================="
echo "Test de la correction Ansible - LLDP Discovery"
echo "=========================================="

# Vérifier si l'environnement virtuel existe
if [ -d "venv" ]; then
    echo "✓ Environnement virtuel trouvé"
    source venv/bin/activate
else
    echo "❌ Environnement virtuel non trouvé"
    echo "Exécutez ./quick_fix.sh pour créer l'environnement"
    exit 1
fi

# Vérifier les dépendances Ansible
echo "Vérification des dépendances Ansible..."
if ansible-galaxy collection list | grep -q "arubanetworks.aos_switch"; then
    echo "✓ Collection Ansible Aruba installée"
else
    echo "⚠ Collection Ansible Aruba non installée"
    echo "Installation en cours..."
    ansible-galaxy collection install arubanetworks.aos_switch
fi

# Test de syntaxe des playbooks
echo ""
echo "Test de syntaxe des playbooks Ansible..."

echo "- test_connectivity.yml"
if ansible-playbook ansible/test_connectivity.yml --syntax-check > /dev/null 2>&1; then
    echo "  ✓ Syntaxe correcte"
else
    echo "  ❌ Erreur de syntaxe"
    ansible-playbook ansible/test_connectivity.yml --syntax-check
fi

echo "- lldp_discovery.yml"
if ansible-playbook ansible/lldp_discovery.yml --syntax-check > /dev/null 2>&1; then
    echo "  ✓ Syntaxe correcte"
else
    echo "  ❌ Erreur de syntaxe"
    ansible-playbook ansible/lldp_discovery.yml --syntax-check
fi

echo "- lldp_discovery_ssh.yml"
if ansible-playbook ansible/lldp_discovery_ssh.yml --syntax-check > /dev/null 2>&1; then
    echo "  ✓ Syntaxe correcte"
else
    echo "  ❌ Erreur de syntaxe"
    ansible-playbook ansible/lldp_discovery_ssh.yml --syntax-check
fi

echo ""
echo "=========================================="
echo "Test terminé !"
echo "=========================================="
echo ""
echo "Pour tester la connectivité vers vos switches :"
echo "ansible-playbook -i ansible/inventory.ini ansible/test_connectivity.yml -vv"
echo ""
echo "Ou utilisez le script automatisé :"
echo "./run_discovery.sh ansible"
