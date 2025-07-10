# Copilot Instructions

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Contexte du projet

Ce projet est conçu pour découvrir les équipements connectés aux switches Aruba 2530 et 6100 via le protocole LLDP (Link Layer Discovery Protocol).

## Objectifs

- Récupérer les informations des équipements connectés : adresses MAC, IP et hostname
- Supporter les switches Aruba 2530 et 6100
- Fournir des solutions en Python et Ansible
- Générer des rapports au format JSON

## Technologies utilisées

- **Python** avec netmiko pour la connexion SSH aux switches
- **Ansible** avec les modules aruba pour l'automatisation
- **LLDP** pour la découverte des équipements
- **JSON** pour le format de sortie

## Structure recommandée

- Utiliser des fonctions séparées pour chaque type de switch
- Implémenter une gestion d'erreur robuste
- Créer des fichiers de configuration pour les credentials
- Structurer la sortie JSON de manière cohérente

## Bonnes pratiques

- Ne jamais hardcoder les credentials dans le code
- Utiliser des logs appropriés
- Valider les données récupérées
- Supporter les timeouts et reconnexions
