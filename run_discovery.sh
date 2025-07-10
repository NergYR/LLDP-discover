#!/bin/bash

# Script de démarrage rapide pour LLDP Discovery
# Utilisation: ./run_discovery.sh [python|ansible] [options]

set -e

# Couleurs pour l'affichage
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

# Fonction d'aide
show_help() {
    echo "Usage: $0 [python|ansible|test] [options]"
    echo ""
    echo "Modes disponibles:"
    echo "  python    - Utilise le script Python pour la découverte LLDP"
    echo "  ansible   - Utilise le playbook Ansible pour la découverte LLDP"
    echo "  test      - Test de connectivité Ansible (rapide)"
    echo ""
    echo "Options Python:"
    echo "  -c CONFIG_FILE    - Fichier de configuration (défaut: python/switches_config.json)"
    echo "  -o OUTPUT_FILE    - Fichier de sortie (défaut: output/lldp_discovery.json)"
    echo "  -v                - Mode verbose"
    echo ""
    echo "Options Ansible:"
    echo "  -i INVENTORY      - Fichier d'inventaire (défaut: ansible/inventory.ini)"
    echo "  -v, -vv, -vvv     - Niveaux de verbosité"
    echo ""
    echo "Exemples:"
    echo "  $0 test                                    # Test rapide de connectivité"
    echo "  $0 python -v"
    echo "  $0 ansible -vv"
    echo "  $0 python -c custom_config.json -o custom_output.json"
}

# Vérifier les prérequis
check_prerequisites() {
    # Vérifier si l'environnement virtuel existe
    if [ ! -d "lldp-env" ]; then
        print_error "Environnement virtuel non trouvé. Exécutez d'abord install_debian.sh"
        exit 1
    fi
    
    # Activer l'environnement virtuel
    source lldp-env/bin/activate
    print_status "Environnement virtuel activé"
    
    # Créer le répertoire de sortie s'il n'existe pas
    mkdir -p output
}

# Fonction pour exécuter le script Python
run_python() {
    print_status "Démarrage de la découverte LLDP avec Python..."
    
    # Vérifier que le fichier principal existe
    if [ ! -f "python/lldp_discovery.py" ]; then
        print_error "Script python/lldp_discovery.py non trouvé"
        exit 1
    fi
    
    # Construire la commande
    cmd="python3 python/lldp_discovery.py"
    
    # Traiter les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                cmd="$cmd -c $2"
                shift 2
                ;;
            -o|--output)
                cmd="$cmd -o $2"
                shift 2
                ;;
            -v|--verbose)
                cmd="$cmd -v"
                shift
                ;;
            *)
                print_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_status "Exécution: $cmd"
    eval $cmd
}

# Fonction pour tester Ansible
test_ansible() {
    print_status "Test de connectivité Ansible vers les switches Aruba..."
    
    # Vérifier que les fichiers Ansible existent
    if [ ! -f "ansible/test_connectivity.yml" ]; then
        print_error "Playbook de test ansible/test_connectivity.yml non trouvé"
        exit 1
    fi
    
    if [ ! -f "ansible/inventory.ini" ]; then
        print_error "Inventaire ansible/inventory.ini non trouvé"
        exit 1
    fi
    
    # Aller dans le répertoire ansible
    cd ansible
    
    # Construire la commande
    cmd="ansible-playbook test_connectivity.yml"
    inventory="inventory.ini"
    
    # Traiter les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--inventory)
                inventory="$2"
                shift 2
                ;;
            -v)
                cmd="$cmd -v"
                shift
                ;;
            -vv)
                cmd="$cmd -vv"
                shift
                ;;
            -vvv)
                cmd="$cmd -vvv"
                shift
                ;;
            *)
                print_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    cmd="$cmd -i $inventory"
    
    print_status "Exécution: $cmd"
    eval $cmd
    
    # Retourner au répertoire racine
    cd ..
}
run_ansible() {
    print_status "Démarrage de la découverte LLDP avec Ansible..."
    
    # Vérifier que les fichiers Ansible existent
    if [ ! -f "ansible/lldp_discovery.yml" ]; then
        print_error "Playbook ansible/lldp_discovery.yml non trouvé"
        exit 1
    fi
    
    if [ ! -f "ansible/inventory.ini" ]; then
        print_error "Inventaire ansible/inventory.ini non trouvé"
        exit 1
    fi
    
    # Aller dans le répertoire ansible
    cd ansible
    
    # Construire la commande
    cmd="ansible-playbook lldp_discovery.yml"
    inventory="inventory.ini"
    
    # Traiter les arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--inventory)
                inventory="$2"
                shift 2
                ;;
            -v)
                cmd="$cmd -v"
                shift
                ;;
            -vv)
                cmd="$cmd -vv"
                shift
                ;;
            -vvv)
                cmd="$cmd -vvv"
                shift
                ;;
            *)
                print_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    cmd="$cmd -i $inventory"
    
    print_status "Exécution: $cmd"
    eval $cmd
    
    # Retourner au répertoire racine
    cd ..
}

# Script principal
main() {
    print_status "🔍 LLDP Discovery - Script de démarrage rapide"
    echo "================================================"
    
    # Vérifier les prérequis
    check_prerequisites
    
    # Vérifier les arguments
    if [ $# -eq 0 ]; then
        print_error "Mode requis: python ou ansible"
        show_help
        exit 1
    fi
    
    mode=$1
    shift
    
    case $mode in
        python)
            run_python "$@"
            ;;
        ansible)
            run_ansible "$@"
            ;;
        test)
            test_ansible "$@"
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            print_error "Mode inconnu: $mode"
            show_help
            exit 1
            ;;
    esac
    
    print_success "✅ Découverte LLDP terminée !"
    print_status "📁 Vérifiez les résultats dans le répertoire 'output/'"
}

# Exécuter le script principal
main "$@"
