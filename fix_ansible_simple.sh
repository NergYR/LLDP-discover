#!/bin/bash

# Script de correction rapide pour Ansible avec équipements réseau
# Auteur: Assistant IA pour découverte LLDP Aruba
# Usage: ./fix_ansible_simple.sh

set -e

echo "🔧 Correction simple des problèmes Ansible..."

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction de log
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [[ ! -f "ansible/lldp_discovery.yml" ]]; then
    error "Fichier ansible/lldp_discovery.yml non trouvé!"
    error "Exécutez ce script depuis le répertoire racine du projet LLDP-discover"
    exit 1
fi

log "Création de playbooks Ansible simples et fonctionnels..."

# Créer un playbook simplifié pour les tests
log "Création d'un playbook de test simple..."

cat > ansible/test_simple.yml << 'EOF'
---
- name: Test simple de connexion Aruba
  hosts: aruba_switches
  gather_facts: no
  tasks:
    - name: Test de connexion basique
      arubanetworks.aos_switch.arubaoss_command:
        commands:
          - show version
      register: version_output
      
    - name: Afficher le résultat
      debug:
        msg: "Connexion réussie vers {{ inventory_hostname }}"
      when: version_output is succeeded

    - name: Test LLDP
      arubanetworks.aos_switch.arubaoss_command:
        commands:
          - show lldp neighbors
      register: lldp_output
      
    - name: Afficher neighbors LLDP
      debug:
        var: lldp_output.stdout_lines
      when: lldp_output is succeeded
EOF

# Créer un playbook SSH simplifié
log "Création d'un playbook SSH de test..."

cat > ansible/test_ssh_simple.yml << 'EOF'
---
- name: Test SSH direct vers Aruba
  hosts: aruba_switches
  gather_facts: no
  tasks:
    - name: Test version via SSH
      ansible.builtin.shell: |
        sshpass -p "{{ ansible_password }}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {{ ansible_user }}@{{ ansible_host }} "show version"
      delegate_to: localhost
      register: version_result
      
    - name: Afficher version
      debug:
        var: version_result.stdout_lines
      when: version_result is succeeded

    - name: Test LLDP via SSH
      ansible.builtin.shell: |
        sshpass -p "{{ ansible_password }}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {{ ansible_user }}@{{ ansible_host }} "show lldp neighbors"
      delegate_to: localhost
      register: lldp_result
      
    - name: Afficher LLDP neighbors
      debug:
        var: lldp_result.stdout_lines
      when: lldp_result is succeeded
EOF

# Corriger les playbooks principaux
log "Correction des playbooks principaux..."

# Fonction pour supprimer les tâches timestamp problématiques
fix_playbook_simple() {
    local playbook="$1"
    local description="$2"
    
    if [[ ! -f "$playbook" ]]; then
        warn "Playbook $playbook non trouvé, ignoré"
        return
    fi
    
    log "Simplification de $description..."
    
    # Supprimer les tâches timestamp problématiques
    sed -i '/name: Obtenir le timestamp/,/run_once: true/d' "$playbook"
    
    # Utiliser lookup pipe pour le timestamp (plus fiable)
    sed -i 's/"{{ hostvars\[.*current_timestamp.*\] }}"/"{{ lookup('\''pipe'\'', '\''date -Iseconds'\'') }}"/g' "$playbook"
    sed -i 's/"{{ current_timestamp }}"/"{{ lookup('\''pipe'\'', '\''date -Iseconds'\'') }}"/g' "$playbook"
    sed -i 's/"{{ ansible_date_time\.iso8601 }}"/"{{ lookup('\''pipe'\'', '\''date -Iseconds'\'') }}"/g' "$playbook"
    
    log "✅ $description simplifié"
}

# Corriger les playbooks
fix_playbook_simple "ansible/lldp_discovery.yml" "Playbook principal"
fix_playbook_simple "ansible/lldp_discovery_ssh.yml" "Playbook SSH"

# Test de syntaxe
log "Test de syntaxe des playbooks..."

if command -v ansible-playbook >/dev/null 2>&1; then
    # Activer l'environnement virtuel si nécessaire
    if [[ -f "lldp-env/bin/activate" ]] && [[ -z "$VIRTUAL_ENV" ]]; then
        log "Activation de l'environnement virtuel..."
        source lldp-env/bin/activate
    fi
    
    # Tester les playbooks simplifiés
    for playbook in "test_simple.yml" "test_ssh_simple.yml"; do
        if ansible-playbook "ansible/$playbook" --syntax-check >/dev/null 2>&1; then
            log "✅ Syntaxe de $playbook OK"
        else
            warn "⚠️ Problème de syntaxe dans $playbook"
        fi
    done
else
    warn "Ansible non disponible, impossible de tester la syntaxe"
fi

log "🎉 Correction terminée!"
echo
echo "Tests disponibles :"
echo "  # Test de connexion simple avec modules Aruba :"
echo "  cd ansible && ansible-playbook -i inventory.ini test_simple.yml -vv"
echo
echo "  # Test de connexion SSH directe :"
echo "  cd ansible && ansible-playbook -i inventory_ssh.ini test_ssh_simple.yml -vv"
echo
echo "Playbooks principaux :"
echo "  # Approche modules Aruba :"
echo "  cd ansible && ansible-playbook -i inventory.ini lldp_discovery.yml -vv"
echo
echo "  # Approche SSH directe :"
echo "  cd ansible && ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv"
