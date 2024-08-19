#!/bin/bash

# setup-ecommerce-v1.sh
# Ce script effectue l'installation et la configuration initiale des composants nécessaires à l'application.
# ----------------------------------------------------------------------------------------------- #

# Fonction pour afficher des messages de titre
title() {
    echo -e "\n#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
    echo -e "$1"
}

# Fonction pour afficher des messages de log
log() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - $1\n"
}

# Pause de 0 secondes
pause() {
    sleep 0
}

# ----------------------------------------------------------------------------------------------- #
title "### eCommerce - Début du processus d'installation ###"
# ----------------------------------------------------------------------------------------------- #
title "### PHASE 1: Clonage du dépôt GitHub ###"
git clone https://github.com/fallewi/ecommerce-micro-service-nodejs.git || { log "Échec du clonage du dépôt GitHub"; exit 1; }
cd ecommerce-micro-service-nodejs || { log "Échec de l'accès au répertoire du dépôt"; exit 1; }
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 2: Mise à jour des paquets ###"
sudo apt-get update && sudo apt-get upgrade -y -o Dpkg::Options::="--force-confnew" || { log "Échec de la mise à jour des paquets"; exit 1; }
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 3: Installation de Node.js ###"
if ! command -v node &> /dev/null; then
    log "Node.js non installé. Installation de Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - || { log "Échec de la configuration Node.js"; exit 1; }
    sudo apt-get install -y nodejs || { log "Échec de l'installation de Node.js"; exit 1; }
else
    log "Node.js est déjà installé."
fi
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 4: Installation de npm ###"
if ! command -v npm &> /dev/null; then
    log "npm non installé. Installation de npm..."
    sudo apt-get install -y npm || { log "Échec de l'installation de npm"; exit 1; }
else
    log "npm est déjà installé."
fi
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 5: Installation de yarn ###"
if ! command -v yarn &> /dev/null; then
    log "yarn non installé. Installation de yarn..."
    sudo npm install --global yarn || { log "Échec de l'installation de yarn"; exit 1; }
else
    log "yarn est déjà installé."
fi
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 6: Installation de MongoDB ###"
if ! command -v mongod &> /dev/null; then
    log "MongoDB non installé. Installation de MongoDB..."
    sudo apt-get install -y mongodb || { log "Échec de l'installation de MongoDB"; exit 1; }
else
    log "MongoDB est déjà installé."
fi

log "Démarrage de MongoDB"
sudo systemctl start mongodb || { log "Échec du démarrage de MongoDB"; exit 1; }
sudo systemctl enable mongodb || { log "Échec de l'activation de MongoDB au démarrage"; exit 1; }
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 7.1 : Installation de RabbitMQ ###"
if ! command -v rabbitmqctl &> /dev/null; then
    log "RabbitMQ non installé. Installation de RabbitMQ..."
    sudo apt-get install -y erlang || { log "Échec de l'installation d'Erlang"; exit 1; }
    sudo apt-get install -y rabbitmq-server || { log "Échec de l'installation de RabbitMQ"; exit 1; }

    log "Démarrage de RabbitMQ"
    sudo systemctl start rabbitmq-server || { log "Échec du démarrage de RabbitMQ"; exit 1; }
    sudo systemctl enable rabbitmq-server || { log "Échec de l'activation de RabbitMQ au démarrage"; exit 1; }

else
    log "RabbitMQ est déjà installé."

    if systemctl is-active --quiet rabbitmq-server; then
        log "RabbitMQ est déjà en cours d'exécution."
    else
        log "RabbitMQ n'est pas en cours d'exécution. Démarrage de RabbitMQ..."
        sudo systemctl start rabbitmq-server || { log "Échec du démarrage de RabbitMQ"; exit 1; }
        sudo systemctl enable rabbitmq-server || { log "Échec de l'activation de RabbitMQ au démarrage"; exit 1; }
    fi
fi
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 7.2 : Installation de RabbitMQadmin ###"
if ! command -v rabbitmqadmin &> /dev/null; then
    log "RabbitMQadmin non installé. Installation de RabbitMQadmin..."
    sudo wget -O /usr/local/bin/rabbitmqadmin https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/v3.8.9/bin/rabbitmqadmin || { log "Échec du téléchargement de rabbitmqadmin"; exit 1; }
    sudo chmod +x /usr/local/bin/rabbitmqadmin || { log "Échec du changement des permissions pour rabbitmqadmin"; exit 1; }
else
    log "RabbitMQadmin est déjà installé."
fi

log "Vérification du statut du plugin de gestion RabbitMQ"
if sudo rabbitmq-plugins list -e | grep "^\\[E\\*\\] rabbitmq_management"; then
    log "Le plugin de gestion RabbitMQ est déjà activé."
else
    log "Activation du plugin de gestion RabbitMQ"
    sudo rabbitmq-plugins enable rabbitmq_management || { log "Échec de l'activation du plugin de gestion RabbitMQ"; exit 1; }
fi
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 7.3 : Configuration des Listeners de RabbitMQ ###"

CONFIG_FILE="/etc/rabbitmq/rabbitmq.conf"
log "Vérification de la configuration existante dans $CONFIG_FILE..."

# Vérifier si le fichier existe et contient les mêmes valeurs
if grep -q "listeners.tcp.default = 5672" "$CONFIG_FILE" && \
   grep -q "management.listener.port = 15672" "$CONFIG_FILE" && \
   grep -q "management.listener.ip = 0.0.0.0" "$CONFIG_FILE"; then
    log "La configuration RabbitMQ est déjà à jour."
else
    log "Mise à jour de la configuration RabbitMQ à $CONFIG_FILE..."
    sudo tee "$CONFIG_FILE" > /dev/null <<EOL
listeners.tcp.default = 5672
management.listener.port = 15672
management.listener.ip = 0.0.0.0
EOL

    # Redémarrer RabbitMQ pour appliquer les modifications
    log "Redémarrage de RabbitMQ pour appliquer les modifications..."
    sudo systemctl restart rabbitmq-server || { log "Échec du redémarrage de RabbitMQ après la configuration"; exit 1; }
fi
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 7.4 : Configuration de RabbitMQ ###"

# Configuration des variables
EXCHANGE_NAME="ONLINE_STORE"
EXCHANGE_TYPE="direct"
RABBIT_USER="roger"
RABBIT_PASSWORD="QiVeLaPo2RR?"
RABBIT_VHOST="/"

# Noms des queues
CUSTOMER_QUEUE="customer_queue"
PRODUCT_QUEUE="product_queue"
SHOPPING_QUEUE="shopping_queue"

# Routing keys
CUSTOMER_ROUTING_KEY="customer"
PRODUCT_ROUTING_KEY="product"
SHOPPING_ROUTING_KEY="shopping"

log "Vérification et création de l'échange"
CURRENT_EXCHANGE=$(rabbitmqadmin list exchanges name | awk '{print $2}' | grep -w "${EXCHANGE_NAME}")
CURRENT_EXCHANGE_TYPE=$(rabbitmqadmin list exchanges name type | grep -w "${EXCHANGE_NAME}" | awk '{print $4}')

if [ -z "$CURRENT_EXCHANGE_TYPE" ]; then
    log "Création de l'échange $EXCHANGE_NAME"
    output=$(rabbitmqadmin declare exchange name=${EXCHANGE_NAME} type=${EXCHANGE_TYPE} 2>&1)
    if echo "$output" | grep -q "exchange declared"; then
        log "Échange $EXCHANGE_NAME créé avec succès."
    else
        log "Échec de la création de l'échange $EXCHANGE_NAME : $output"
        exit 1
    fi
elif [ "$CURRENT_EXCHANGE_TYPE" != "$EXCHANGE_TYPE" ]; then
    log "L'échange $EXCHANGE_NAME existe déjà mais avec un type différent ($CURRENT_EXCHANGE_TYPE). Suppression et recréation..."
    rabbitmqadmin delete exchange name=${EXCHANGE_NAME} || { log "Échec de la suppression de l'échange $EXCHANGE_NAME"; exit 1; }
    rabbitmqadmin declare exchange name=${EXCHANGE_NAME} type=${EXCHANGE_TYPE} || { log "Échec de la recréation de l'échange $EXCHANGE_NAME"; exit 1; }
else
    log "L'échange $EXCHANGE_NAME existe déjà avec le bon type ($EXCHANGE_TYPE)."
fi

log "Vérification et création des queues"
for QUEUE in ${CUSTOMER_QUEUE} ${PRODUCT_QUEUE} ${SHOPPING_QUEUE}; do
    if rabbitmqadmin list queues name | awk '{print $2}' | grep -w "${QUEUE}"; then
        log "La queue $QUEUE existe déjà."
    else
        log "Création de la queue $QUEUE"
        output=$(rabbitmqadmin declare queue name=${QUEUE} durable=true 2>&1)
        if echo "$output" | grep -q "queue declared"; then
            log "Queue $QUEUE créée avec succès."
        else
            log "Échec de la création de la queue $QUEUE : $output"
            exit 1
        fi
    fi
done

log "Vérification et création des liaisons (bindings)"
declare -A bindings=(
    ["${CUSTOMER_QUEUE}"]=${CUSTOMER_ROUTING_KEY}
    ["${PRODUCT_QUEUE}"]=${PRODUCT_ROUTING_KEY}
    ["${SHOPPING_QUEUE}"]=${SHOPPING_ROUTING_KEY}
)

for QUEUE in "${!bindings[@]}"; do
    ROUTING_KEY=${bindings[$QUEUE]}
    if rabbitmqadmin list bindings | grep -q "${EXCHANGE_NAME}.*${QUEUE}.*${ROUTING_KEY}"; then
        log "La liaison de la queue $QUEUE avec l'échange $EXCHANGE_NAME existe déjà."
    else
        log "Liaison de la queue $QUEUE avec l'échange $EXCHANGE_NAME"
        output=$(rabbitmqadmin declare binding source=${EXCHANGE_NAME} destination=${QUEUE} destination_type=queue routing_key=${ROUTING_KEY} 2>&1)
        if echo "$output" | grep -q "binding declared"; then
            log "Liaison de la queue $QUEUE avec l'échange $EXCHANGE_NAME créée avec succès."
        else
            log "Échec de la liaison de la queue $QUEUE avec l'échange $EXCHANGE_NAME : $output"
            exit 1
        fi
    fi
done

log "Test de connexion avec l'utilisateur"
if ! sudo rabbitmqctl authenticate_user ${RABBIT_USER} ${RABBIT_PASSWORD} &> /dev/null; then
    log "Utilisateur $RABBIT_USER ne peut pas se connecter avec le mot de passe fourni. Recréation de l'utilisateur."
    sudo rabbitmqctl delete_user ${RABBIT_USER} 2>/dev/null || true
    log "Création de l'utilisateur $RABBIT_USER"
    sudo rabbitmqctl add_user ${RABBIT_USER} ${RABBIT_PASSWORD} || { log "Échec de la création de l'utilisateur $RABBIT_USER"; exit 1; }
else
    log "Utilisateur $RABBIT_USER peut se connecter avec le mot de passe fourni."
fi

log "Attribution des tags de l'utilisateur"
USER_TAGS=$(sudo rabbitmqctl list_users | awk -v user="$RABBIT_USER" '$1 == user {print $2}')
if [[ "$USER_TAGS" != *"administrator"* ]]; then
    sudo rabbitmqctl set_user_tags ${RABBIT_USER} administrator || { log "Échec de l'attribution des tags à l'utilisateur $RABBIT_USER"; exit 1; }
else
    log "Les tags de l'utilisateur ${RABBIT_USER} sont déjà corrects."
fi

log "Attribution des permissions de l'utilisateur"
USER_PERMISSIONS=$(sudo rabbitmqctl list_permissions -p $RABBIT_VHOST | awk -v user="$RABBIT_USER" '$1 == user {print $2, $3, $4}')
if [[ "$USER_PERMISSIONS" != ".* .* .*" ]]; then
    sudo rabbitmqctl set_permissions -p ${RABBIT_VHOST} ${RABBIT_USER} ".*" ".*" ".*" || { log "Échec de l'attribution des permissions à l'utilisateur $RABBIT_USER"; exit 1; }
else
    echo "Les permissions de l'utilisateur ${RABBIT_USER} sont déjà correctes."
fi

log "Test de publication et de consommation des messages sur les queues"

declare -A routing_keys=(
    ["${CUSTOMER_QUEUE}"]=${CUSTOMER_ROUTING_KEY}
    ["${PRODUCT_QUEUE}"]=${PRODUCT_ROUTING_KEY}
    ["${SHOPPING_QUEUE}"]=${SHOPPING_ROUTING_KEY}
)

for QUEUE in "${!routing_keys[@]}"; do
    ROUTING_KEY=${routing_keys[$QUEUE]}
    log "Test de publication d'un message dans la queue $QUEUE avec la routing key $ROUTING_KEY"
    rabbitmqadmin publish exchange="${EXCHANGE_NAME}" routing_key="${ROUTING_KEY}" payload="Test message in ${QUEUE}" || { log "Échec de la publication du message dans la queue $QUEUE"; exit 1; }
done

log "Vérification que les messages sont bien présents"
rabbitmqadmin list queues name messages
pause

log "Configuration RabbitMQ réussie."
pause


# ----------------------------------------------------------------------------------------------- #
title "### PHASE 8.1 : Installation de Nginx ###"

# Vérification et installation de Nginx
if ! command -v nginx &> /dev/null; then
    log "Nginx non installé. Installation de Nginx..."
    sudo apt-get install -y nginx || { log "Échec de l'installation de Nginx"; exit 1; }
    
    log "Activation et démarrage de Nginx"
    sudo systemctl enable nginx || { log "Échec de l'activation de Nginx au démarrage"; exit 1; }
    sudo systemctl start nginx || { log "Échec du démarrage de Nginx"; exit 1; }
else
    log "Nginx est déjà installé."
fi

log "Nginx est maintenant opérationnel."
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 8.2 : Installation de Certbot ###"

# Vérifier si Certbot est déjà installé
if ! command -v certbot &> /dev/null; then
    log "Certbot n'est pas installé. Installation de Certbot..."
    sudo apt-get install python3-certbot-nginx -y || { log "Échec de l'installation de Certbot"; exit 1; }
else
    log "Certbot est déjà installé."
fi
pause

# ----------------------------------------------------------------------------------------------- #
# A TESTER ET OPTIMISER
title "### PHASE 8.3 : Configuration de Certbot pour le site 'ecommerce'"

DOMAIN="ecommerce.newbie.cloudns.be"
EMAIL="james_95h@outlook.com"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
BASE_DIR="$(pwd)"
BACKUP_DIR="$BASE_DIR/.deploy/backup"  # Chemin vers le dossier de sauvegarde
BACKUP_FILE="$BACKUP_DIR/letsencrypt-backup.tar.gz"  # Fichier de sauvegarde compressé

# Vérifier si les certificats sont déjà présents
if sudo [ -d "$CERT_DIR" ]; then
    log "Certificat SSL déjà présent pour le domaine $DOMAIN."
else
    log "Certificat SSL non trouvé pour le domaine $DOMAIN."
    
    # Restaurer les certificats sauvegardés si disponibles
    if [ -f "$BACKUP_FILE" ]; then
        log "Restauration des certificats depuis la sauvegarde..."
        sudo tar -xvzf "$BACKUP_FILE" -C /etc/letsencrypt/  # Extraire dans le dossier cible
        
        # Recharger Nginx avec la configuration restaurée
        sudo systemctl reload nginx
    else
        log "Aucune sauvegarde trouvée. Obtention du nouveau certificat SSL..."
        sudo certbot certonly --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL || { log "Échec de la demande du certificat SSL"; exit 1; }
        
        # Sauvegarder les certificats obtenus
        log "Sauvegarde des certificats obtenus..."
        sudo tar -cvzf "$BACKUP_FILE" -C /etc/letsencrypt/ .
        sudo chmod 644 "$BACKUP_FILE"
        
        # Redémarrer Nginx pour appliquer les changements
        sudo systemctl restart nginx
    fi
fi

# Vérifier la présence du fichier cron pour Certbot
if [ -f "/etc/cron.d/certbot" ]; then
    log "Le cron job pour Certbot est déjà configuré dans /etc/cron.d/certbot."
else
    log "Le cron job pour Certbot n'est pas configuré. Ajout manuel du cron job pour le renouvellement automatique des certificats."
    echo "0 3 * * * /usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload nginx'" | sudo tee -a /etc/crontab > /dev/null
fi

log "Configuration terminée."
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 8.4 : Configuration de Nginx ###"

# Création du fichier de configuration NGINX
CONFIG_FILE="/etc/nginx/sites-available/ecommerce"
log "Création du fichier de configuration NGINX à $CONFIG_FILE..."

sudo tee $CONFIG_FILE > /dev/null <<EOL
server {
    listen 80;
    server_name ecommerce.newbie.cloudns.be;

    # Redirection de HTTP vers HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl; # managed by Certbot
    server_name ecommerce.newbie.cloudns.be;
    ssl_certificate /etc/letsencrypt/live/ecommerce.newbie.cloudns.be/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/ecommerce.newbie.cloudns.be/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    # Redirection pour l'application front
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Redirection pour les microservices
    location /customer/ {
        proxy_pass http://localhost:8001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /product/ {
        proxy_pass http://localhost:8002/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /shopping/ {
        proxy_pass http://localhost:8003/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

EOL

log "Configuration du site ecommerce de Nginx terminée."
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 8.5 : Activation du site eCommerce ###"

# Vérifier si le lien symbolique existe déjà
if [ ! -L /etc/nginx/sites-enabled/ecommerce ]; then
    log "Activation du site 'ecommerce' en créant un lien symbolique..."
    sudo ln -s /etc/nginx/sites-available/ecommerce /etc/nginx/sites-enabled/ || { log "Échec de la création du lien symbolique pour le site 'ecommerce'"; exit 1; }
else
    log "Le lien symbolique pour le site 'ecommerce' existe déjà."
fi

# Tester la configuration NGINX
log "Test de la configuration NGINX..."
sudo nginx -t || { log "Échec du test de configuration NGINX"; exit 1; }

# Redémarrer Nginx pour appliquer les modifications
log "Redémarrage de Nginx..."
sudo systemctl restart nginx || { log "Échec du redémarrage de Nginx"; exit 1; }

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 9.1 : Application : modification des variables d'environnement ###"

# Définition des nouvelles valeurs pour les variables d'environnement
MONGODB_URI="mongodb://localhost:27017"
MSG_QUEUE_URL="amqp://localhost:5672"
EXCHANGE_NAME="ONLINE_STORE"
PORT_CUSTOMER=8001
PORT_PRODUCT=8002
PORT_SHOPPING=8003

# Chemins vers les fichiers .env.dev pour chaque microservice
CUSTOMER_ENV="./customer/.env.dev"
PRODUCT_ENV="./products/.env.dev"
SHOPPING_ENV="./shopping/.env.dev"

log "Mise à jour du fichier $CUSTOMER_ENV"
cat > $CUSTOMER_ENV << EOL
NODE_ENV=dev
APP_SECRET=a_great_secret
MONGODB_URI=${MONGODB_URI}/msytt_customer
MSG_QUEUE_URL=${MSG_QUEUE_URL}
EXCHANGE_NAME=${EXCHANGE_NAME}
PORT=${PORT_CUSTOMER}
BASE_URL=http://localhost:${PORT_CUSTOMER}/
EOL

log "Mise à jour du fichier $PRODUCT_ENV"
cat > $PRODUCT_ENV << EOL
NODE_ENV=dev
APP_SECRET=a_great_secret
MONGODB_URI=${MONGODB_URI}/msytt_product
MSG_QUEUE_URL=${MSG_QUEUE_URL}
EXCHANGE_NAME=${EXCHANGE_NAME}
PORT=${PORT_PRODUCT}
BASE_URL=http://localhost:${PORT_PRODUCT}/
EOL

log "Mise à jour du fichier $SHOPPING_ENV"
cat > $SHOPPING_ENV << EOL
NODE_ENV=dev
APP_SECRET=a_great_secret
MONGODB_URI=${MONGODB_URI}/msytt_shopping
MSG_QUEUE_URL=${MSG_QUEUE_URL}
EXCHANGE_NAME=${EXCHANGE_NAME}
PORT=${PORT_SHOPPING}
BASE_URL=http://localhost:${PORT_SHOPPING}/
EOL

log "Mise à jour des fichiers .env.dev terminée."
pause

# ----------------------------------------------------------------------------------------------- #
title "Le script s'est déroulé avec succès."
echo -e ""
