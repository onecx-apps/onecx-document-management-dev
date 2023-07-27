# OneCX apps - document-management-dev


## Prerequisite
- install quarkus cli

```
https://quarkus.io/get-started/
```

## Docker compose

The docker compose in this repo currently contains:




Core infra elements:

- `traefik` reverse proxy
- `postgresdb` generic postgresql db
- `keycloak-app` Access and Identity Management Tool (credentials are: admin/admin)
- `minio` Filestorage 



Core app elements (optional):

- `tkit-portal-server` Main MS for tkit portal applications, managing and storing informations about Portals and Users
- `apm` MS which manages access and permissions for Portal users
- `pgadmin` UI admin for Postgres, login as onecx@onecx.org/password

Main document-management elements:


- `onecx-document-management-ui` UI application to perist data into configured databases from xls files
- `onecx-document-management-bff` Backend For Frontend implementing logic accessing ui specific backend service 
- `onecx-document-management-svc` Backend service implementing logic of persisting data into postgres dbs



## Hosts file

In order to expose multiple services on the same port, we use traefik reverse proxy. It will be available via your hosts 80 port, and will route traffik to containers based on hostnames.
Therefore, for each service you want to access, do add an entry to your hosts files Windows: `c:\Windows\System32\drivers\etc\hosts` and Linux / WSL: `/etc/hosts`(wsl hosts file will be autogenerated from windows file when you restart wsl, unless you disabled that behaviour). Sample file (hosts.sample) is in this repo.

## Usage

### How to use it - with real app services started variant (A)

To initilize the app services execute first:

- `./setup-environment.sh`

In this mode the IDE is serving real authentication mechanism and real portal and apm server preloaded with test data



### How to use it - mocked variant (B)

To run the essential services only and app services mocked execute:

- `./start-essential.sh`

In this mode the IDE is serving real authentication mechanism and hard-coded (see: ./wiremock-init) portal-server responses


## Initial Data

Postgres server is automatically created with the necessary databases.

PGAdmin
- **URL** - http://pgadmin/
- **User** - onecx@onecx.org
- **Password** - password

Keycloak db is populated with the following configuration:

- **URL** - http://keycloak-app/
- **Realm** - OneCx
- **Clients** - onecx-document-management-ui
- **User** - admin
- **Password** - admin
- **Roles assigned to the user** - [onecx-portal-admin, onecx-portal-user, onecx-admin, tkit-portal-admin]

Automatic import of basic portal data into tkit-portal-server is enabled.

Minio Server is started and a bucket 'onecx-document-management' is created.
- **URL** - http://minio:9001/
- **User** - minioadmin
- **Password** - minioadmin


APM with document management specific permissions is started.


Traefik - Dashboard
- **URL** - http://traefik:8082/


Onecx document management ui
- **URL** - http://onecx-document-management-ui/
- **User** - document_admin, document_responsible, document_user
- **Password** - onecx


## Remote debugging

- comment in the env variable in docker-compose.yaml in container section 'onecx-document-management-svc'

```
      JAVA_ENABLE_DEBUG: true
      JAVA_DEBUG_PORT: '*:5005'
    ports:
      - "5005:5005"
```

- restart environment
`./setup-environment.sh`

- connect your debugger using localhost port 5005


## Remote development with live update

- build onecx-document-management-svc by after uncommenting the following block in onecx-document-management-svc/src/resources/application.properties:

```
#REMOTE DEVELOPMENT ONLY
%dev.quarkus.package.type=mutable-jar
%dev.quarkus.live-reload.password=changeit
%dev.quarkus.live-reload.url=http://onecx-document-management-svc:80
```

- afterwards build image

`quarkus build -Dquarkus.profile=dev`

- use the created image 'localhost/onecx-document-management-svc:999-SNAPSHOT' by changing image in onecx-document-management-dev/.env

```
#DOCUMENT_MANAGEMENT_SVC=ghcr.io/onecx-apps/onecx-document-management-svc:0.1.0-rc.11
DOCUMENT_MANAGEMENT_SVC=localhost/onecx-document-management-svc:999-SNAPSHOT
```

- comment in the env variable in docker-compose.yaml in container section 'onecx-document-management-svc'

```
      QUARKUS_LAUNCH_DEVMODE: 'true'
```

- restart environment
`./setup-environment.sh`

- in the logs of the onecx-document-management-svc docker image you should see 

```
2023-07-27 07:36:55,620 INFO  [io.quarkus] (Quarkus Main Thread) onecx-document-management-svc 999-SNAPSHOT on JVM (powered by Quarkus 2.16.7.Final) started in 5.741s. Listening on: http://0.0.0.0:8080
2023-07-27 07:36:55,621 INFO  [io.quarkus] (Quarkus Main Thread) Profile dev activated. Live Coding activated.
```


- run in you onecx-document-management-svc 

`mvn quarkus:remote-dev -Dquarkus.profile=dev -Ddebug=false`

- now you should see something like:

```
2023-07-27 09:46:25,227 INFO  [io.qua.ver.htt.dep.dev.HttpRemoteDevClient] (Remote dev client thread) Sending app/onecx-document-management-svc-999-SNAPSHOT.jar
2023-07-27 09:46:25,235 INFO  [io.qua.ver.htt.dep.dev.HttpRemoteDevClient] (Remote dev client thread) Sending quarkus-run.jar
2023-07-27 09:46:25,239 INFO  [io.qua.ver.htt.dep.dev.HttpRemoteDevClient] (Remote dev client thread) Connected to remote server
```


- any changes made in onecx-document-management-svc are instantly synced to the running docker application.


## App configurations

To configure your local applications to work together with services or mock from this compose, change the corresponding addresses of the dependent services in your local app, using only hostnames of the docker services.

**proxy-conf.json** example:

```json
  "/portal-api": {
    "target": "http://tkit-portal-server",
    "secure": false,
    "pathRewrite": {
      "^/portal-api": ""
    },
    "changeOrigin": true,
    "logLevel": "debug"
  },

```

OR :

```json
  "/portal-api": {
    "target": "http://wiremock/portal-api/",
    "secure": false,
    "pathRewrite": {
      "^/portal-api": ""
    },
    "changeOrigin": true,
    "logLevel": "debug"
  },

```

**env.json** example:

```json
  "KEYCLOAK_REALM": "OneCX",
  "KEYCLOAK_URL": "http://keycloak-app/",
  "KEYCLOAK_CLIENT_ID": "onecx-document-management-ui",
  "TKIT_PORTAL_ID": "ADMIN",
```


## Reset environment

**shutdown env**
- `docker compose down`
- `docker rm -f $(docker ps -a -q)`
- `docker volume rm $(docker volume ls -q)`

**optional**
- `docker system prune -a`

**restart system**
- `./setup-environment.sh`


