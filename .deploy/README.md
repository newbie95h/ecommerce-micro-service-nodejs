# eCommerce micro-service app - Deployment

## Deploy_v1 => setup-ecommerce-v1.sh
 
 Ceci est une version de découverte de l'application.
 Le but est d'installer l'application durectement sur la VM Amazon sans passer par Docker ou autre.

 L'installation est automatique et est lancée par un bash.

 Les épates de ce bash sont : 

 - PHASE 1: Clonage du dépôt GitHub
 - PHASE 2: Mise à jour des paquets
 - PHASE 3: Installation de Node.js
 - PHASE 4: Installation de npm
 - PHASE 5: Installation de yarn
 - PHASE 6: Installation de MongoDB
 - PHASE 7 : Installation et configuration de RabbitMQ
    - PHASE 7.1 : Installation de RabbitMQ
    - PHASE 7.2 : Installation de RabbitMQadmin
    - PHASE 7.3 : Configuration des Listeners de RabbitMQ
    - PHASE 7.4 : Configuration de RabbitMQ
 - PHASE 8 : Nginx
   - PHASE 8.1 : Installation de Nginx
   - PHASE 8.2 : Configuration de Nginx
   - PHASE 8.3 : Activation du site eCommerce
   - PHASE 8.4.1 : Installation de Certbot
   - PHASE 8.4.2 : Configuration de Certbot pour le site 'ecommerce'
 - PHASE 9 : Configuration de l'application eCommerce
   - PHASE 9.1 : Application : modification des variables d'environnement ###
   - PHASE 9.2 : Application : installation des services ecommerce-micro-service-nodejs

## Deploy_v2 => setup-ecommerce-v2.sh

 Cette version va déployer l'application telle qu'elle est fournie. Le déploiement utilisera Docker.
 