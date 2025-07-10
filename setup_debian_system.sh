#!/bin/bash

# Configuration système pour LLDP Discovery sur Debian 12
# Ce script configure les paramètres système optimaux

set -e

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

echo "🔧 Configuration système pour LLDP Discovery"
echo "============================================="

# Vérifier les privilèges sudo
if ! sudo -n true 2>/dev/null; then
    print_warning "Ce script nécessite des privilèges sudo"
    sudo -v
fi

# Configuration SSH pour une meilleure connectivité
print_status "Configuration du client SSH..."
SSH_CONFIG="$HOME/.ssh/config"
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if ! grep -q "# LLDP Discovery SSH Config" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << EOF

# LLDP Discovery SSH Config
Host aruba-*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 3
    LogLevel ERROR

Host 192.168.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 3
    LogLevel ERROR
EOF
    print_success "Configuration SSH ajoutée"
else
    print_status "Configuration SSH déjà présente"
fi

chmod 600 "$SSH_CONFIG"

# Configuration des timeouts réseau
print_status "Configuration des timeouts réseau..."
if ! grep -q "# LLDP Discovery sysctl" /etc/sysctl.conf; then
    sudo tee -a /etc/sysctl.conf > /dev/null << EOF

# LLDP Discovery sysctl optimizations
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
net.core.netdev_max_backlog = 5000
EOF
    sudo sysctl -p
    print_success "Optimisations réseau appliquées"
else
    print_status "Optimisations réseau déjà configurées"
fi

# Configuration des limites pour les connexions multiples
print_status "Configuration des limites système..."
if ! grep -q "# LLDP Discovery limits" /etc/security/limits.conf; then
    sudo tee -a /etc/security/limits.conf > /dev/null << EOF

# LLDP Discovery limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF
    print_success "Limites système configurées"
else
    print_status "Limites système déjà configurées"
fi

# Installer des outils de diagnostic réseau supplémentaires
print_status "Installation d'outils de diagnostic..."
sudo apt install -y \
    telnet \
    netcat-openbsd \
    tcpdump \
    wireshark-common \
    net-tools \
    iftop \
    iotop \
    htop \
    tree \
    rsync \
    screen \
    tmux

# Configuration de logrotate pour les logs LLDP
print_status "Configuration de la rotation des logs..."
sudo tee /etc/logrotate.d/lldp-discovery > /dev/null << EOF
$(pwd)/output/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 $(whoami) $(whoami)
}
EOF

# Créer un service systemd pour les tâches récurrentes (optionnel)
print_status "Création du service systemd..."
sudo tee /etc/systemd/system/lldp-discovery.service > /dev/null << EOF
[Unit]
Description=LLDP Discovery Service
After=network.target

[Service]
Type=oneshot
User=$(whoami)
Group=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/run_discovery.sh python -v
StandardOutput=append:$(pwd)/output/lldp_discovery.log
StandardError=append:$(pwd)/output/lldp_discovery.log

[Install]
WantedBy=multi-user.target
EOF

# Créer un timer systemd pour l'exécution périodique
sudo tee /etc/systemd/system/lldp-discovery.timer > /dev/null << EOF
[Unit]
Description=Run LLDP Discovery every hour
Requires=lldp-discovery.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
print_success "Service systemd créé (non activé par défaut)"

# Configuration du firewall (si ufw est installé)
if command -v ufw &> /dev/null; then
    print_status "Configuration du firewall UFW..."
    sudo ufw allow out 22/tcp comment "SSH sortant pour switches"
    sudo ufw allow out 443/tcp comment "HTTPS sortant"
    sudo ufw allow out 53 comment "DNS sortant"
    print_success "Règles firewall ajoutées"
fi

# Créer des alias bash utiles
print_status "Création d'alias bash..."
BASHRC="$HOME/.bashrc"
if ! grep -q "# LLDP Discovery aliases" "$BASHRC"; then
    cat >> "$BASHRC" << EOF

# LLDP Discovery aliases
alias lldp-activate='source $(pwd)/lldp-env/bin/activate'
alias lldp-python='$(pwd)/run_discovery.sh python'
alias lldp-ansible='$(pwd)/run_discovery.sh ansible'
alias lldp-logs='tail -f $(pwd)/output/lldp_discovery.log'
alias lldp-output='cat $(pwd)/output/lldp_discovery.json | jq .'
alias lldp-check='python3 $(pwd)/python/test_connectivity.py'
EOF
    print_success "Alias bash ajoutés"
else
    print_status "Alias bash déjà configurés"
fi

# Configuration de l'autocomplétion
print_status "Configuration de l'autocomplétion..."
if [ -d "/etc/bash_completion.d" ]; then
    sudo tee /etc/bash_completion.d/lldp-discovery > /dev/null << 'EOF'
# LLDP Discovery bash completion
_lldp_discovery() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="python ansible -v -vv -vvv -c -o -i --config --output --inventory --verbose --help"

    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    case "${prev}" in
        -c|--config)
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        -o|--output)
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        -i|--inventory)
            COMPREPLY=( $(compgen -f -- ${cur}) )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "python ansible" -- ${cur}) )
            return 0
            ;;
    esac
}
complete -F _lldp_discovery run_discovery.sh
EOF
    print_success "Autocomplétion configurée"
fi

# Créer un script de nettoyage
cat > cleanup_lldp.sh << EOF
#!/bin/bash
# Script de nettoyage pour LLDP Discovery

echo "🧹 Nettoyage des fichiers temporaires..."

# Nettoyer les logs anciens
find output/ -name "*.log" -mtime +30 -delete 2>/dev/null || true

# Nettoyer les fichiers JSON anciens (garde les 10 derniers)
ls -t output/*.json 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

# Nettoyer les fichiers temporaires Python
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✅ Nettoyage terminé"
EOF

chmod +x cleanup_lldp.sh

echo
print_success "🎉 Configuration système terminée !"
echo
echo "📋 Services et outils configurés :"
echo "   ✅ Configuration SSH optimisée"
echo "   ✅ Timeouts réseau ajustés"
echo "   ✅ Limites système augmentées"
echo "   ✅ Outils de diagnostic installés"
echo "   ✅ Rotation des logs configurée"
echo "   ✅ Service systemd créé"
echo "   ✅ Alias bash ajoutés"
echo "   ✅ Autocomplétion configurée"
echo "   ✅ Script de nettoyage créé"
echo
echo "🔧 Commandes utiles :"
echo "   source ~/.bashrc                    # Recharger les alias"
echo "   lldp-activate                       # Activer l'environnement"
echo "   lldp-python -v                      # Lancer découverte Python"
echo "   lldp-ansible -vv                    # Lancer découverte Ansible"
echo "   lldp-logs                          # Voir les logs en temps réel"
echo "   lldp-output                        # Afficher le JSON de sortie"
echo "   sudo systemctl enable lldp-discovery.timer  # Activer découverte automatique"
echo
echo "📁 Redémarrez votre session ou exécutez 'source ~/.bashrc' pour activer les alias"
