#!/usr/bin/env python3
"""
Filtres personnalisés Ansible pour parser les données Aruba LLDP
"""

import re
import json
from typing import Dict, List, Any


class FilterModule:
    """Module de filtres pour Ansible"""
    
    def filters(self):
        return {
            'parse_lldp_neighbors': self.parse_lldp_neighbors,
            'parse_arp_table': self.parse_arp_table,
            'parse_system_info': self.parse_system_info,
            'enrich_with_arp': self.enrich_with_arp
        }
    
    def parse_lldp_neighbors(self, lldp_output: str) -> List[Dict[str, Any]]:
        """
        Parse la sortie LLDP neighbors detail
        
        Args:
            lldp_output: Sortie brute de 'show lldp neighbors detail'
            
        Returns:
            Liste des voisins parsés
        """
        neighbors = []
        
        # Split par blocs de voisins
        neighbor_blocks = re.split(r'Local Port\s*:\s*(\S+)', lldp_output)[1:]
        
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
    
    def parse_arp_table(self, arp_output: str) -> Dict[str, str]:
        """
        Parse la table ARP
        
        Args:
            arp_output: Sortie brute de 'show arp'
            
        Returns:
            Dict mapping IP -> MAC
        """
        arp_table = {}
        
        for line in arp_output.split('\n'):
            # Pattern pour ligne ARP: IP Address    MAC Address      Type   Port
            match = re.search(r'(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F:.-]+)\s+', line)
            if match:
                ip, mac = match.groups()
                arp_table[ip] = mac.lower()
        
        return arp_table
    
    def parse_system_info(self, system_output: str) -> Dict[str, str]:
        """
        Parse les informations système
        
        Args:
            system_output: Sortie brute de 'show system'
            
        Returns:
            Dict avec les informations système
        """
        system_info = {}
        
        # Patterns pour extraire les informations clés
        patterns = {
            'model': r'Product Model\s*:\s*(.+)',
            'serial': r'Serial Number\s*:\s*(.+)',
            'firmware': r'Firmware Version\s*:\s*(.+)',
            'hostname': r'System Name\s*:\s*(.+)'
        }
        
        for key, pattern in patterns.items():
            match = re.search(pattern, system_output, re.IGNORECASE)
            if match:
                system_info[key] = match.group(1).strip()
        
        return system_info
    
    def enrich_with_arp(self, neighbors: List[Dict], arp_table: Dict[str, str]) -> List[Dict[str, Any]]:
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
    
    def _extract_field(self, text: str, pattern: str) -> str:
        """Extrait un champ spécifique du texte"""
        match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
        return match.group(1).strip() if match else ""
    
    def _extract_mgmt_addresses(self, text: str) -> List[str]:
        """Extrait les adresses de management"""
        pattern = r'Management Address\s*:\s*(\d+\.\d+\.\d+\.\d+)'
        return re.findall(pattern, text, re.IGNORECASE)
