#!/usr/bin/env python3
"""
Script de test de connectivité pour switches Aruba
Utile pour valider la configuration avant la découverte LLDP
"""

import json
import sys
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException, NetmikoAuthenticationException


def test_switch_connection(host, username, password, device_type='aruba_os'):
    """
    Test la connexion à un switch Aruba
    
    Args:
        host: Adresse IP du switch
        username: Nom d'utilisateur
        password: Mot de passe
        device_type: Type de device Netmiko
        
    Returns:
        bool: True si connexion réussie, False sinon
    """
    print(f"Test de connexion à {host}...")
    
    try:
        device = {
            'device_type': device_type,
            'host': host,
            'username': username,
            'password': password,
            'timeout': 30,
        }
        
        connection = ConnectHandler(**device)
        
        # Test de commandes basiques
        print(f"  ✓ Connexion SSH réussie")
        
        # Test LLDP
        lldp_status = connection.send_command("show lldp configuration")
        if "LLDP Status" in lldp_status and "Enabled" in lldp_status:
            print(f"  ✓ LLDP activé")
        else:
            print(f"  ⚠ LLDP pourrait ne pas être activé")
        
        # Test des voisins LLDP
        neighbors = connection.send_command("show lldp neighbors")
        neighbor_count = len([line for line in neighbors.split('\n') if 'Port' in line and 'Neighbor' in line]) - 1
        print(f"  ✓ {neighbor_count} voisins LLDP détectés")
        
        # Test ARP
        arp = connection.send_command("show arp")
        arp_entries = len([line for line in arp.split('\n') if '.' in line and ':' in line])
        print(f"  ✓ {arp_entries} entrées ARP")
        
        connection.disconnect()
        print(f"  ✓ Test réussi pour {host}")
        return True
        
    except NetmikoTimeoutException:
        print(f"  ✗ Timeout de connexion pour {host}")
        return False
    except NetmikoAuthenticationException:
        print(f"  ✗ Erreur d'authentification pour {host}")
        return False
    except Exception as e:
        print(f"  ✗ Erreur pour {host}: {str(e)}")
        return False


def main():
    """Fonction principale de test"""
    config_file = 'python/switches_config.json'
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"Fichier de configuration non trouvé: {config_file}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Erreur de format JSON: {config_file}")
        sys.exit(1)
    
    switches = config.get('switches', [])
    if not switches:
        print("Aucun switch configuré")
        sys.exit(1)
    
    print(f"Test de connectivité pour {len(switches)} switches...\n")
    
    success_count = 0
    for switch in switches:
        host = switch.get('host')
        username = switch.get('username')
        password = switch.get('password')
        device_type = switch.get('device_type', 'aruba_os')
        
        if not all([host, username, password]):
            print(f"Configuration incomplète pour: {switch}")
            continue
        
        if test_switch_connection(host, username, password, device_type):
            success_count += 1
        print()
    
    print(f"Résumé: {success_count}/{len(switches)} switches accessibles")
    
    if success_count == len(switches):
        print("✓ Tous les switches sont accessibles. Vous pouvez lancer la découverte LLDP.")
    else:
        print("⚠ Certains switches ne sont pas accessibles. Vérifiez la configuration.")


if __name__ == "__main__":
    main()
