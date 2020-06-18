#!/bin/bash

MODULE_NAME=overleaf
RF=$BUILDDIR/${MODULE_NAME}

mkdir -p $RF

DOCKER_HOST=$DOCKERARGS
DOCKER_COMPOSE_FILE=$RF/docker-compose.yml

# README
# works only if serves on :8080 or any other port, but not through the nginx, since it doesn_t have a BASE_URL property?

OVERLEAF_LOG=$LOG_DIR/${MODULE_NAME}
OVERLEAF_DATA=$DATA_DIR/${MODULE_NAME}
OVERLEAF_DB_MONGO=$DATA_DIR/${MODULE_NAME}_db_mongo
OVERLEAF_DB_REDIS=$DATA_DIR/${MODULE_NAME}_db_redis

case $VERB in
  "build")
    echo "1. Configuring ${PREFIX}-${MODULE_NAME}..."

#    CODEDIR=$RF/githubcode
#    if [ ! -d $CODEDIR ] ; then
#        git clone https://github.com/overleaf/overleaf.git $CODEDIR
#    fi

    mkdir -p $OVERLEAF_DB_MONGO $OVERLEAF_DB_REDIS $OVERLEAF_DATA $OVERLEAF_LOG

    docker $DOCKERARGS volume create -o type=none -o device=$OVERLEAF_DATA -o o=bind ${PREFIX}-overleaf-data
    docker $DOCKERARGS volume create -o type=none -o device=$OVERLEAF_LOG -o o=bind ${PREFIX}-overleaf-log
    docker $DOCKERARGS volume create -o type=none -o device=$OVERLEAF_DB_REDIS -o o=bind ${PREFIX}-overleaf-redis_data
    docker $DOCKERARGS volume create -o type=none -o device=$OVERLEAF_DB_MONGO -o o=bind ${PREFIX}-overleaf-mongo_data

    sed -e "s/##REWRITEPROTO##/$REWRITEPROTO/" \
        -e "s/##PREFIX##/$PREFIX/" \
        -e "s/##OUTERHOST##/$OUTERHOST/" docker-compose.yml-template > $DOCKER_COMPOSE_FILE
    
    sed -e "s/##REWRITEPROTO##/$REWRITEPROTO/" \
        -e "s/##PREFIX##/$PREFIX/" \
        -e "s/##OUTERHOST##/$OUTERHOST/" Dockerfile_template  > $RF/Dockerfile


   echo "2. Building ${PREFIX}-overleaf..."
   docker-compose $DOCKER_HOST -f $DOCKER_COMPOSE_FILE build 
 ;;

  "install-hydra")
#    register_hydra $MODULE_NAME
  ;;
  "uninstall-hydra")
#    unregister_hydra $MODULE_NAME
  ;;
  "install-nginx")
    register_nginx $MODULE_NAME
  ;;
  "uninstall-nginx")
    unregister_nginx $MODULE_NAME
  ;;

  "start")
    echo "Starting container ${PREFIX}-${MODULE_NAME}"
    docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE up -d
  ;;

  "init")

# $ docker exec sharelatex /bin/bash -c "cd /var/www/sharelatex; grunt user:create-admin --email joe@example.com"
# After password reset the password can be found in one of the logs /var/log/sharelatex/*
# https://github.com/overleaf/web/issues/264
  ;;

  "admin")
     echo "Creating ${MODULE_NAME} admin user..."
	docker $DOCKERARGS exec -it ${PREFIX}-${MODULE_NAME} /opt/overleaf/overleaf-server-latest/reset-admin.sh
  ;;

  "stop")
      echo "Stopping container ${PREFIX}-${MODULE_NAME}"
      docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE down
  ;;
    
  "remove")
      echo "Removing $DOCKER_COMPOSE_FILE"
      docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE kill
      docker-compose $DOCKERARGS -f $DOCKER_COMPOSE_FILE rm    
  ;;

  "cleandata")
    echo "Cleaning data ${PREFIX}-${MODULE_NAME}"
    docker $DOCKERARGS volume rm ${PREFIX}-${MODULE_NAME}-data
    docker $DOCKERARGS volume rm ${PREFIX}-${MODULE_NAME}-redis_data
    docker $DOCKERARGS volume rm ${PREFIX}-${MODULE_NAME}-mongo_data
  ;;

  "purge")
###    echo "Removing $RF" 
###    rm -R -f $RF
###    docker $DOCKERARGS volume rm ${PREFIX}-overleaf-data
  ;;

esac
