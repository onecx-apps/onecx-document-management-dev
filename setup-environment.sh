#!/bin/bash

export DOCKER_COMPOSE="docker-compose"

if ! which ${DOCKER_COMPOSE} &> /dev/null
then
    echo "docker-compose could not be found - try new docker compose command"
    DOCKER_COMPOSE="docker compose"
fi
	
echo '# Restarting all micro services needed for document management';
${DOCKER_COMPOSE} stop
echo Y | ${DOCKER_COMPOSE} rm
${DOCKER_COMPOSE} up -d traefik postgresdb pgadmin keycloak-app tkit-portal-server minio apm
echo '# Waiting for pods to start before starting next...';

time ${DOCKER_COMPOSE} up -d createbuckets onecx-document-management-ui onecx-document-management-bff onecx-document-management-svc
echo '# Waiting for pods to start before starting next...';

#END