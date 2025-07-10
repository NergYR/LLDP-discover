#!/usr/bin/env python3
"""
Script de découverte LLDP pour switches Aruba 2530 et 6100
Récupère les adresses MAC, IP et hostname des équipements connectés
"""

import json
import logging
import argparse
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException, NetmikoAuthenticationException
import re

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('output/lldp_discovery.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class ArubaLLDPDiscovery:
    """Classe pour la découverte LLDP sur switches Aruba"""
    
    def __init__(self, host: str, username: str, password: str, device_type: str = 'aruba_os'):
        """
        Initialise la connexion au switch Aruba
        
        Args:
            host: Adresse IP du switch
            username: Nom d'utilisateur
            password: Mot de passe
            device_type: Type de device Netmiko (aruba_os par défaut)
        """
        self.host = host
        self.username = username
        self.password = password
        self.device_type = device_type
        self.connection = None
        
    def connect(self) -> bool:
        """
        Établit la connexion SSH au switch
        
        Returns:
            bool: True si connexion réussie, False sinon
        """
        try:
            device = {
                'device_type': self.device_type,
                'host': self.host,
                'username': self.username,
                'password': self.password,
                'timeout': 60,
                'global_delay_factor': 2,
            }
            self.connection = ConnectHandler(**device)
            logger.info(f"Connexion réussie au switch {self.host}")
            return True
            
        except NetmikoTimeoutException:
            logger.error(f"Timeout lors de la connexion à {self.host}")
            return False
        except NetmikoAuthenticationException:
            logger.error(f"Erreur d'authentification pour {self.host}")
            return False
        except Exception as e:
            logger.error(f"Erreur de connexion à {self.host}: {str(e)}")
            return False
    
    def disconnect(self):
        """Ferme la connexion SSH"""
        if self.connection:
            self.connection.disconnect()
            logger.info(f"Connexion fermée pour {self.host}")
    
    def get_lldp_neighbors(self) -> Dict[str, Any]:
        """
        Récupère les informations LLDP des voisins
        
        Returns:
            Dict contenant les informations des voisins LLDP
        """
        if not self.connection:
            logger.error("Aucune connexion active")
            return {}
        
        try:
            # Commande pour récupérer les voisins LLDP
            lldp_output = self.connection.send_command("show lldp neighbors detail")
            
            # Parse des informations LLDP
            neighbors = self._parse_lldp_output(lldp_output)
            
            # Enrichissement avec les informations ARP
            arp_table = self._get_arp_table()
            
            # Combinaison des données
            enriched_neighbors = self._enrich_neighbor_data(neighbors, arp_table)
            
            return {
                'switch_ip': self.host,
                'timestamp': datetime.now().isoformat(),
                'neighbors_count': len(enriched_neighbors),
                'neighbors': enriched_neighbors
            }
            
        except Exception as e:
            logger.error(f"Erreur lors de la récupération LLDP: {str(e)}")
            return {}
    
    def _parse_lldp_output(self, output: str) -> List[Dict[str, Any]]:
        """
        Parse la sortie de la commande LLDP
        
        Args:
            output: Sortie brute de la commande LLDP
            
        Returns:
            Liste des voisins parsés
        """
        neighbors = []
        
        # Pattern pour parser les informations LLDP
        # Adaptation selon le format de sortie Aruba
        neighbor_blocks = re.split(r'Local Port\s*:\s*(\S+)', output)[1:]
        
        for i in range(0, len(neighbor_blocks), 2):
            if i + 1 < len(neighbor_blocks):
                local_port = neighbor_blocks[i].strip()
                neighbor_info = neighbor_blocks[i + 1]
                
                neighbor = {
                    'local_port': local_port,
                    'remote_chassis_id': self._extract_field(neighbor_info, r'Chassis ID\s*:\s*(.+)'),
                    'remote_port_id': self._extract_field(neighbor_info, r'Port ID\s*:\s*(.+)'),
                    'remote_system_name': self._extract_field(neighbor_info, r'System Name\s*:\s*(.+)'),
                    'remote_system_description': self._extract_field(neighbor_info, r'System Description\s*:\s*(.+)'),
                    'remote_port_description': self._extract_field(neighbor_info, r'Port Description\s*:\s*(.+)'),
                    'management_addresses': self._extract_mgmt_addresses(neighbor_info)
                }
                
                neighbors.append(neighbor)
        
        return neighbors
    
    def _extract_field(self, text: str, pattern: str) -> Optional[str]:
        """Extrait un champ spécifique du texte"""
        match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
        return match.group(1).strip() if match else None
    
    def _extract_mgmt_addresses(self, text: str) -> List[str]:
        """Extrait les adresses de management"""
        addresses = []
        pattern = r'Management Address\s*:\s*(\d+\.\d+\.\d+\.\d+)'
        matches = re.findall(pattern, text, re.IGNORECASE)
        return matches
    
    def _get_arp_table(self) -> Dict[str, str]:
        """
        Récupère la table ARP du switch
        
        Returns:
            Dict mapping IP -> MAC
        """
        try:
            arp_output = self.connection.send_command("show arp")
            arp_table = {}
            
            # Parse de la table ARP
            for line in arp_output.split('\n'):
                # Pattern typique: IP Address    MAC Address      Type   Port
                match = re.search(r'(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F:.-]+)\s+', line)
                if match:
                    ip, mac = match.groups()
                    arp_table[ip] = mac.lower()
            
            logger.info(f"Table ARP récupérée: {len(arp_table)} entrées")
            return arp_table
            
        except Exception as e:
            logger.error(f"Erreur lors de la récupération ARP: {str(e)}")
            return {}
    
    def _enrich_neighbor_data(self, neighbors: List[Dict], arp_table: Dict[str, str]) -> List[Dict[str, Any]]:
        """
        Enrichit les données des voisins avec les informations ARP
        
        Args:
            neighbors: Liste des voisins LLDP
            arp_table: Table ARP IP -> MAC
            
        Returns:
            Liste enrichie des voisins
        """
        enriched = []
        
        for neighbor in neighbors:
            enriched_neighbor = neighbor.copy()
            
            # Recherche des correspondances MAC/IP
            chassis_id = neighbor.get('remote_chassis_id', '').lower()
            matching_ips = []
            
            # Recherche par MAC address dans l'ARP
            for ip, mac in arp_table.items():
                if chassis_id in mac or mac in chassis_id:
                    matching_ips.append(ip)
            
            # Ajout des adresses de management
            mgmt_addresses = neighbor.get('management_addresses', [])
            all_ips = list(set(matching_ips + mgmt_addresses))
            
            enriched_neighbor.update({
                'ip_addresses': all_ips,
                'mac_address': chassis_id,
                'hostname': neighbor.get('remote_system_name', 'Unknown')
            })
            
            enriched.append(enriched_neighbor)
        
        return enriched


def load_switch_config(config_file: str) -> List[Dict[str, str]]:
    """
    Charge la configuration des switches depuis un fichier JSON
    
    Args:
        config_file: Chemin vers le fichier de configuration
        
    Returns:
        Liste des configurations de switches
    """
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        return config.get('switches', [])
    except FileNotFoundError:
        logger.error(f"Fichier de configuration non trouvé: {config_file}")
        return []
    except json.JSONDecodeError:
        logger.error(f"Erreur de format JSON dans: {config_file}")
        return []


def discover_all_switches(switches_config: List[Dict[str, str]]) -> Dict[str, Any]:
    """
    Lance la découverte LLDP sur tous les switches
    
    Args:
        switches_config: Liste des configurations de switches
        
    Returns:
        Données de découverte consolidées
    """
    all_results = {
        'discovery_timestamp': datetime.now().isoformat(),
        'switches': {},
        'summary': {
            'total_switches': len(switches_config),
            'successful_connections': 0,
            'total_neighbors': 0
        }
    }
    
    for switch_config in switches_config:
        host = switch_config.get('host')
        username = switch_config.get('username')
        password = switch_config.get('password')
        device_type = switch_config.get('device_type', 'aruba_os')
        
        if not all([host, username, password]):
            logger.error(f"Configuration incomplète pour le switch: {switch_config}")
            continue
        
        logger.info(f"Début de la découverte pour {host}")
        
        discovery = ArubaLLDPDiscovery(host, username, password, device_type)
        
        if discovery.connect():
            switch_data = discovery.get_lldp_neighbors()
            discovery.disconnect()
            
            if switch_data:
                all_results['switches'][host] = switch_data
                all_results['summary']['successful_connections'] += 1
                all_results['summary']['total_neighbors'] += switch_data.get('neighbors_count', 0)
                logger.info(f"Découverte terminée pour {host}: {switch_data.get('neighbors_count', 0)} voisins")
            else:
                logger.error(f"Aucune donnée récupérée pour {host}")
        else:
            logger.error(f"Impossible de se connecter à {host}")
    
    return all_results


def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description='Découverte LLDP pour switches Aruba')
    parser.add_argument('-c', '--config', default='python/switches_config.json',
                       help='Fichier de configuration des switches')
    parser.add_argument('-o', '--output', default='output/lldp_discovery.json',
                       help='Fichier de sortie JSON')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Mode verbose')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    logger.info("Début de la découverte LLDP")
    
    # Chargement de la configuration
    switches_config = load_switch_config(args.config)
    if not switches_config:
        logger.error("Aucune configuration de switch trouvée")
        sys.exit(1)
    
    # Découverte LLDP
    results = discover_all_switches(switches_config)
    
    # Sauvegarde des résultats
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        logger.info(f"Résultats sauvegardés dans: {args.output}")
    except Exception as e:
        logger.error(f"Erreur lors de la sauvegarde: {str(e)}")
        sys.exit(1)
    
    # Affichage du résumé
    summary = results['summary']
    logger.info(f"Découverte terminée:")
    logger.info(f"  - Switches traités: {summary['successful_connections']}/{summary['total_switches']}")
    logger.info(f"  - Total voisins découverts: {summary['total_neighbors']}")


if __name__ == "__main__":
    main()
