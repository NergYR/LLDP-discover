#!/bin/bash

# Script de transfert automatique vers un serveur Debian
# Usage: ./transfer_to_debian.sh user@server:/path/to/destination

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [user@]hostname[:path]"
    echo ""
    echo "Transfert le projet LLDP Discovery vers un serveur Debian via SCP/rsync"
    echo ""
    echo "Exemples:"
    echo "  $0 root@192.168.1.100"
    echo "  $0 user@debian-server:/home/user/projects"
    echo "  $0 192.168.1.100:/opt/lldp-discovery"
    echo ""
    echo "Options:"
    echo "  -h, --help     Afficher cette aide"
    echo "  -v, --verbose  Mode verbeux"
    echo "  -n, --dry-run  Simulation sans transfert réel"
}

# Variables par défaut
VERBOSE=false
DRY_RUN=false
DESTINATION=""

# Traitement des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            print_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$DESTINATION" ]; then
                DESTINATION="$1"
            else
                print_error "Trop d'arguments"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Vérifier que la destination est fournie
if [ -z "$DESTINATION" ]; then
    print_error "Destination requise"
    show_help
    exit 1
fi

echo "📦 Transfert LLDP Discovery vers Debian"
echo "======================================"

# Vérifier que rsync est installé
if ! command -v rsync &> /dev/null; then
    print_error "rsync n'est pas installé. Installation..."
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        print_error "Veuillez installer rsync pour Windows ou utilisez WSL"
        exit 1
    else
        sudo apt update && sudo apt install -y rsync
    fi
fi

# Extraire les informations de destination
if [[ "$DESTINATION" == *:* ]]; then
    HOST=$(echo "$DESTINATION" | cut -d: -f1)
    PATH_DEST=$(echo "$DESTINATION" | cut -d: -f2)
else
    HOST="$DESTINATION"
    PATH_DEST="~/lldp-discovery"
fi

print_status "Destination: $HOST"
print_status "Chemin distant: $PATH_DEST"

# Tester la connectivité SSH
print_status "Test de connectivité SSH..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$HOST" exit 2>/dev/null; then
    print_warning "Impossible de se connecter en mode batch, tentative interactive..."
    if ! ssh -o ConnectTimeout=10 "$HOST" exit; then
        print_error "Impossible de se connecter à $HOST"
        exit 1
    fi
fi

print_success "Connectivité SSH confirmée"

# Préparer les fichiers à exclure
EXCLUDE_FILE=$(mktemp)
cat > "$EXCLUDE_FILE" << EOF
.git/
.gitignore
__pycache__/
*.pyc
*.pyo
.pytest_cache/
.coverage
.env
lldp-env/
output/*.log
output/*.json
.vscode/
.idea/
*.tmp
*.bak
node_modules/
.DS_Store
Thumbs.db
EOF

# Options rsync
RSYNC_OPTS="-avz --delete --exclude-from=$EXCLUDE_FILE"

if [ "$VERBOSE" = true ]; then
    RSYNC_OPTS="$RSYNC_OPTS --progress"
fi

if [ "$DRY_RUN" = true ]; then
    RSYNC_OPTS="$RSYNC_OPTS --dry-run"
    print_warning "Mode simulation activé - aucun fichier ne sera transféré"
fi

# Créer le répertoire de destination si nécessaire
print_status "Création du répertoire de destination..."
ssh "$HOST" "mkdir -p '$PATH_DEST'"

# Effectuer le transfert
print_status "Transfert des fichiers..."
if rsync $RSYNC_OPTS ./ "$HOST:$PATH_DEST/"; then
    print_success "Transfert terminé avec succès"
else
    print_error "Erreur lors du transfert"
    rm -f "$EXCLUDE_FILE"
    exit 1
fi

# Nettoyer le fichier temporaire
rm -f "$EXCLUDE_FILE"

# Rendre les scripts exécutables sur le serveur distant
if [ "$DRY_RUN" = false ]; then
    print_status "Configuration des permissions..."
    ssh "$HOST" "cd '$PATH_DEST' && chmod +x *.sh"
    print_success "Permissions configurées"
fi

echo
print_success "🎉 Transfert terminé !"
echo
echo "📋 Étapes suivantes sur le serveur Debian :"
echo "1. Se connecter au serveur :"
echo "   ssh $HOST"
echo
echo "2. Aller dans le répertoire du projet :"
echo "   cd $PATH_DEST"
echo
echo "3. Lancer l'installation :"
echo "   ./install_debian.sh"
echo
echo "4. (Optionnel) Configurer le système :"
echo "   ./setup_debian_system.sh"
echo
echo "5. Configurer vos switches :"
echo "   nano python/switches_config.json"
echo "   nano ansible/inventory.ini"
echo
echo "6. Tester la découverte :"
echo "   ./run_discovery.sh python -v"

# Optionnel : se connecter automatiquement pour continuer l'installation
echo
read -p "Voulez-vous vous connecter automatiquement au serveur pour continuer l'installation ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Connexion au serveur..."
    ssh -t "$HOST" "cd '$PATH_DEST' && exec bash"
fi
