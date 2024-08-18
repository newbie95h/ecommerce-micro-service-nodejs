#!/bin/bash

# setup-ecommerce-small.sh
# Ce script effectue l'installation initiale de Nodejs, yarn, Nginx, MongoDB, RabbitMQ, vérifie la présence des fichiers nécessaires,
# Il configure également Nginx, RabbitMQ, modifie les fichiers '.env.dev' du dépôt.
# ----------------------------------------------------------------------------------------------- #

# Fonction pour afficher des messages de titre
title() {
    echo -e "\n#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
    echo -e "$1"
}

# Fonction pour afficher des messages de log
log() {
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Pause de 2 secondes
pause() {
    sleep 2
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
sudo apt-get update && sudo apt-get upgrade -y || { log "Échec de la mise à jour des paquets"; exit 1; }
pause

# ----------------------------------------------------------------------------------------------- #
title "### PHASE 3: Installation de Node.js ###"
if ! command -v node &> /dev/null; then
    log "Node.js non installé. Installation de Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - | sudo -E bash - || { log "Échec de la configuration Node.js"; exit 1; }
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
if sudo rabbitmq-plugins list -e | grep -q "^rabbitmq_management$"; then
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

# Vérification et création de l'échange
CURRENT_EXCHANGE_TYPE=$(rabbitmqadmin list exchanges name type | grep "^${EXCHANGE_NAME} " | awk '{print $2}')

if [ -z "$CURRENT_EXCHANGE_TYPE" ]; then
    log "Création de l'échange $EXCHANGE_NAME"
    rabbitmqadmin declare exchange name=${EXCHANGE_NAME} type=${EXCHANGE_TYPE} || { log "Échec de la création de l'échange $EXCHANGE_NAME"; exit 1; }
elif [ "$CURRENT_EXCHANGE_TYPE" != "$EXCHANGE_TYPE" ]; then
    log "L'échange $EXCHANGE_NAME existe déjà mais avec un type différent ($CURRENT_EXCHANGE_TYPE). Suppression et recréation..."
    rabbitmqadmin delete exchange name=${EXCHANGE_NAME} || { log "Échec de la suppression de l'échange $EXCHANGE_NAME"; exit 1; }
    rabbitmqadmin declare exchange name=${EXCHANGE_NAME} type=${EXCHANGE_TYPE} || { log "Échec de la recréation de l'échange $EXCHANGE_NAME"; exit 1; }
else
    log "L'échange $EXCHANGE_NAME existe déjà avec le bon type ($EXCHANGE_TYPE)."
fi

# Vérification et création des queues
for QUEUE in ${CUSTOMER_QUEUE} ${PRODUCT_QUEUE} ${SHOPPING_QUEUE}; do
    if ! rabbitmqadmin list queues name | grep -q "^${QUEUE}$"; then
        log "Création de la queue $QUEUE"
        rabbitmqadmin declare queue name=${QUEUE} durable=true || { log "Échec de la création de la queue $QUEUE"; exit 1; }
    else
        log "La queue $QUEUE existe déjà."
    fi
done

# Vérification et création des liaisons (bindings)
declare -A bindings=(
    ["${CUSTOMER_QUEUE}"]=${CUSTOMER_ROUTING_KEY}
    ["${PRODUCT_QUEUE}"]=${PRODUCT_ROUTING_KEY}
    ["${SHOPPING_QUEUE}"]=${SHOPPING_ROUTING_KEY}
)

for QUEUE in "${!bindings[@]}"; do
    ROUTING_KEY=${bindings[$QUEUE]}
    if ! rabbitmqadmin list bindings | grep -q "${EXCHANGE_NAME}.*${QUEUE}.*${ROUTING_KEY}"; then
        log "Liaison de la queue $QUEUE avec l'échange $EXCHANGE_NAME"
        rabbitmqadmin declare binding source=${EXCHANGE_NAME} destination=${QUEUE} destination_type=queue routing_key=${ROUTING_KEY} || { log "Échec de la liaison de la queue $QUEUE"; exit 1; }
    else
        log "La liaison de la queue $QUEUE avec l'échange $EXCHANGE_NAME existe déjà."
    fi
done

# Test de connexion avec l'utilisateur
if ! sudo rabbitmqctl authenticate_user ${RABBIT_USER} ${RABBIT_PASSWORD} &> /dev/null; then
    log "Utilisateur $RABBIT_USER ne peut pas se connecter avec le mot de passe fourni. Recréation de l'utilisateur."
    sudo rabbitmqctl delete_user ${RABBIT_USER} 2>/dev/null || true
    log "Création de l'utilisateur $RABBIT_USER"
    sudo rabbitmqctl add_user ${RABBIT_USER} ${RABBIT_PASSWORD} || { log "Échec de la création de l'utilisateur $RABBIT_USER"; exit 1; }
else
    log "Utilisateur $RABBIT_USER peut se connecter avec le mot de passe fourni."
fi

# Attribution des permissions et des tags
log "Attribution des permissions et des tags à l'utilisateur $RABBIT_USER"
sudo rabbitmqctl set_user_tags ${RABBIT_USER} administrator || { log "Échec de l'attribution des tags à l'utilisateur $RABBIT_USER"; exit 1; }
sudo rabbitmqctl set_permissions -p ${RABBIT_VHOST} ${RABBIT_USER} ".*" ".*" ".*" || { log "Échec de l'attribution des permissions à l'utilisateur $RABBIT_USER"; exit 1; }

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
title "### PHASE 8.4.1 : Installation de Certbot ###"

# Vérifier si Certbot est déjà installé
if ! command -v certbot &> /dev/null; then
    log "Certbot n'est pas installé. Installation de Certbot..."
    sudo apt-get install python3-certbot-nginx -y || { log "Échec de l'installation de Certbot"; exit 1; }
else
    log "Certbot est déjà installé."
fi
pause

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
title "Le script ecommerce-init.sh est terminé."
echo -e ""
