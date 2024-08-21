#!/bin/bash

# docker-cleanup.sh
# Ce script vérifie s'il y a des conteneurs Docker en cours d'exécution et des images Docker présentes,
# puis arrête et supprime les conteneurs en cours d'exécution, supprime tous les conteneurs arrêtés, 
# supprime toutes les images Docker, tous les réseaux Docker non utilisés, et tous les volumes Docker.

# Vérifie si Docker est installé
if ! command -v docker &> /dev/null; then
  echo "Docker n'est pas installé. Veuillez installer Docker avant d'exécuter ce script."
  exit 1
fi

# Vérifie s'il y a des conteneurs Docker en cours d'exécution
if [ "$(docker ps -q)" ]; then
  echo "Des conteneurs Docker en cours d'exécution détectés. Arrêt et suppression des conteneurs."
  
  # Arrête tous les conteneurs en cours d'exécution
  docker stop $(docker ps -q)
fi

# Vérifie s'il y a des conteneurs arrêtés
if [ "$(docker ps -a -q)" ]; then
  echo "Suppression de tous les conteneurs arrêtés."
  
  # Supprime tous les conteneurs arrêtés
  docker rm $(docker ps -a -q)
else
  echo "Aucun conteneur Docker arrêté trouvé."
fi

# Vérifie s'il y a des images Docker
if [ "$(docker images -q)" ]; then
  echo "Des images Docker trouvées. Suppression de toutes les images."
  
  # Supprime toutes les images Docker
  docker rmi -f $(docker images -q)
else
  echo "Aucune image Docker trouvée."
fi

# Vérifie s'il y a des réseaux Docker non utilisés
if [ "$(docker network ls -q)" ]; then
  echo "Des réseaux Docker trouvés. Suppression de tous les réseaux non utilisés."
  
  # Supprime tous les réseaux Docker non utilisés
  docker network prune -f
else
  echo "Aucun réseau Docker trouvé."
fi

# Vérifie s'il y a des volumes Docker non utilisés
if [ "$(docker volume ls -q)" ]; then
  echo "Des volumes Docker trouvés. Suppression de tous les volumes non utilisés."
  
  # Supprime tous les volumes Docker non utilisés
  docker volume prune -f
else
  echo "Aucun volume Docker trouvé."
fi

# Supprime le cache de build
echo "Nettoyage du cache de build Docker."
docker builder prune -f

echo "Nettoyage Docker terminé."
