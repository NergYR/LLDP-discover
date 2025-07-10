#!/bin/bash

# Script de correction pour le problème ansible_date_time undefined
# Auteur: Assistant IA pour découverte LLDP Aruba
# Usage: ./fix_ansible_facts.sh

set -e

echo "🔧 Correction du problème ansible_date_time..."

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

log "Vérification des playbooks Ansible..."

# Fonction pour corriger un playbook
fix_playbook() {
    local playbook="$1"
    local description="$2"
    
    if [[ ! -f "$playbook" ]]; then
        warn "Playbook $playbook non trouvé, ignoré"
        return
    fi
    
    log "Correction de $description..."
    
    # Vérifier si gather_facts est déjà à yes
    if grep -q "gather_facts: yes" "$playbook"; then
        log "✅ $description déjà corrigé"
        return
    fi
    
    # Corriger gather_facts
    sed -i 's/gather_facts: no/gather_facts: yes/g' "$playbook"
    
    # Supprimer la ligne timestamp: si elle existe dans vars
    sed -i '/^[[:space:]]*timestamp: "{{ ansible_date_time/d' "$playbook"
    
    log "✅ $description corrigé"
}

# Corriger les playbooks
fix_playbook "ansible/lldp_discovery.yml" "Playbook principal"
fix_playbook "ansible/lldp_discovery_ssh.yml" "Playbook SSH"

# Tester la syntaxe des playbooks
log "Test de la syntaxe des playbooks..."

if command -v ansible-playbook >/dev/null 2>&1; then
    # Activer l'environnement virtuel si nécessaire
    if [[ -f "lldp-env/bin/activate" ]] && [[ -z "$VIRTUAL_ENV" ]]; then
        log "Activation de l'environnement virtuel..."
        source lldp-env/bin/activate
    fi
    
    # Tester la syntaxe du playbook principal
    if ansible-playbook ansible/lldp_discovery.yml --syntax-check >/dev/null 2>&1; then
        log "✅ Syntaxe du playbook principal OK"
    else
        warn "⚠️ Problème de syntaxe détecté dans le playbook principal"
    fi
    
    # Tester la syntaxe du playbook SSH
    if ansible-playbook ansible/lldp_discovery_ssh.yml --syntax-check >/dev/null 2>&1; then
        log "✅ Syntaxe du playbook SSH OK"
    else
        warn "⚠️ Problème de syntaxe détecté dans le playbook SSH"
    fi
else
    warn "Ansible non disponible, impossible de tester la syntaxe"
fi

# Créer un playbook de test simple pour vérifier ansible_date_time
log "Création d'un test pour ansible_date_time..."

cat > /tmp/test_date_time.yml << 'EOF'
---
- name: Test ansible_date_time
  hosts: localhost
  gather_facts: yes
  tasks:
    - name: Afficher ansible_date_time
      debug:
        msg: "Timestamp: {{ ansible_date_time.iso8601 }}"
EOF

if command -v ansible-playbook >/dev/null 2>&1; then
    log "Test d'ansible_date_time..."
    if ansible-playbook /tmp/test_date_time.yml >/dev/null 2>&1; then
        log "✅ ansible_date_time fonctionne correctement"
    else
        error "❌ Problème avec ansible_date_time"
    fi
    rm -f /tmp/test_date_time.yml
fi

log "🎉 Correction terminée!"
echo
echo "Pour tester la correction :"
echo "  cd ansible"
echo "  ansible-playbook -i inventory.ini lldp_discovery.yml --check"
echo
echo "Si ça ne marche toujours pas, utilisez l'approche SSH :"
echo "  ansible-playbook -i inventory_ssh.ini lldp_discovery_ssh.yml -vv"
