Work in progresss - this tutorial is being updated

# Tutorial - CDC with Debezium running on AKS and sending events to Azure Event Hub
## Demo presented at TDC Connections 2021, MVPConf2021 and TDC Future 2021 about Event Driven Architectures and CDC and how to deploy Debezium on AKS and connect it to Azure Event Hub

1. Pre-reqs => For running this demo you will need to:
 	* An Azure Subscription where you have administrative permissions
 	* A Cloud Shell configured to use Bash on that subscription

2. Start creating the infrastructure you will need:
	* Use the Bash environment on [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart).
[![Opens Azure Cloud Shell in new window](https://docs.microsoft.com/en-us/azure/includes/media/cloud-shell-try-it/hdi-launch-cloud-shell.png)](https://shell.azure.com/)
	* Select your Subscription, if you have more than one: `az account set --subscription '<your-subscription-name-or-id>'`
	* Create the resource group: `az group create --location eastus --resource-group demodebezium-rg`
	* Create the AKS (Azure Kubernetes Service) cluster: `az aks create --resource-group demodebezium-rg --name demodbzakscluster --node-count 2 --enable-addons monitoring --generate-ssh-keys`
	* Create the Azure Database for MySQL: `az mysql server create --resource-group demodebezium-rg --name demodbzmysql --location eastus --admin-user debezium --admin-password P@ssw0rd2021 --sku-name B_Gen5_1 --storage-size 5120 --version 8.0`
	* Create the ACR (Azure Container Registry): `az acr create --resource-group demodebezium-rg --name demodbzacr --sku Basic`
	* Create the Azure Event Hub namespace: `az eventhubs namespace create --name demodebezium-ns --resource-group demodebezium-rg -l eastus`

3. Configure some basic things on your infrastructure:
	* Connect to your recently created MySQL (using [MySQL Workbench](https://dev.mysql.com/downloads/workbench/) or any other client tool of your preference), and:
		- 
	* On your newly created MySQL, called **demodbzmysql, go to "Server Properties", and:
		- set `binlog_row_image` to `FULL`
		- set `binlog_expire_logs_seconds` to `7200`
		* One Azure Database for MySQL (some specific configurations and privileges for running CDC are needed - look at https://debezium.io/documentation/reference/connectors/mysql.html#setting-up-mysql)
	   		* after deploy the server, you can use the provided SQL script (`tdc-connections-2021-db.sql`) to create the simple schema used on this demo 
		* One Azure Event Hub
	* clone/download this repo on your machine

2. Download and unzip the `strimzi-0.23.0.zip` file from GitHub (https://github.com/strimzi/strimzi-kafka-operator/releases)

3. Connect AZ CLI to AKS
	```pwsh
	az account set --subscription '<your-azure-subscription-name-or-id>'
	az aks get-credentials --resource-group <your-aks-resource-group-name> --name <your-aks-cluster-name>
	```
	* test the AZ CLI connection: `kubectl get svc`

4. Create Strimzi namespace: `kubectl create ns strimzi`

5. Create Kafka/Debezium namespace: `kubectl create ns debezium`

6. Change Strimzi installation files to use your created namespaces:
	* change all files named as `strimzi-0.23.0/install/cluster-operator/\*RoleBinding\*.yaml` replacing `"namespace: "` with `"namespace: strimzi"`
	* edit `strimzi-0.23.0/install/cluster-operator/060-Deployment-strimzi-cluster-operator.yaml`:
	```yaml
	# ...
	env:
	- name: STRIMZI_NAMESPACE
	  value: debezium
	# ...
	```
7. Deploy Strimzi
	```pwsh
	kubectl create -f install/cluster-operator/ -n strimzi
	``` 
8. Give permission to Strimzi on Kafka/Debezium namespace
	```pwsh
	kubectl create -f install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n debezium
	kubectl create -f install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml -n debezium
	kubectl create -f install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n debezium
	```
9. Install Kafka Cluster
	* edit `strimzi-0.23.0/examples/kafka/kafka-persistent.yaml` to define a better name for your kafka cluster:
	```yaml
	# ...
	metadata:
	  name: kafka-cdc-cluster
	# ...
	```
	* then apply it to your AKS cluster:
	```pwsh
	kubectl apply -f strimzi-0.23.0/examples/kafka/kafka-persistent.yaml - n debezium
	```
	* wait for cluster to be ready... it will take a while... check with `kubectl get pods -n debezium`
	
10. Check if your Kafka Cluster is running well
	```pwsh
	kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-producer.sh --broker-list kafka-cdc-cluster-kafka-bootstrap:9092 --topic my-test-topic
	kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server kafka-cdc-cluster-kafka-bootstrap:9092 --topic my-test-topic --from-beginning
	```
11. Prepare to create a Kafka Connect docker image with Debezium and MySQL plugins:
	* download debezium-mysql plugin:
	```pwsh
	curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/1.5.2.Final/debezium-connector-mysql-1.5.2.Final-plugin.tar.gz -o debezium-connector-mysql-1.5.2.Final-plugin.tar.gz
	tar -xvzf .\debezium-connector-mysql-1.5.2.Final-plugin.tar.gz
	del *.tar.gz
	```
	* create a `Dockerfile` with the following lines (or use the provided one):
	```dockerfile
	FROM quay.io/strimzi/kafka:latest-kafka-2.8.0
	USER root:root
	RUN mkdir -p /opt/kafka/plugins/debezium
	COPY ./debezium-connector-mysql/ /opt/kafka/plugins/debezium/
	USER 1001
	```
13. Build the image and push it to Azure Container Registry:
	```pwsh
	docker build --image debezium/mysql-plugin .
	docker login <your-acr-name>.azurecr.io
	docker tag debezium/mysql-plugin <your-acr-name>.azurecr.io/debezium/mysql-plugin
	docker push <your-acr-name>.azurecr.io/debezium/mysql-plugin
	```
12. Attach ACR to AKS:
	```pwsh
	az aks update -n <your-aks-cluster-name> -g <your-aks-resource-group> --attach-acr <your-acr-name>
	```
13. Edit the provided `mysql-secret.properties` to include your MySQL credentials and create a Secret from it on AKS:
	```pwsh
	kubectl -n debezium create secret generic mysql-credentials --from-file=mysql-secret.properties
	```
14. Deploy the Kafka Connect cluster with your custom image including Debezium and MySQL plugins:
	* edit the provided `kafka-connect.yaml` replacing `<your-acr-name>` with the name you gave to your Azure Container Registry
	* then apply it to AKS:
	```pwsh
	kubectl apply -f kafka-connect.yaml -n debezium
	```
15. Configure the Debezium/MySQL connector to start capturing data changes on MySQL database
	* edit the provided `debezium-mysql-connector.yaml` replacing `<your-mysql-server-name>` with the name you gave to your Azure Database for MySQL server
	* then apply it to AKS:
	```pwsh
	kubectl apply -f debezium-mysql-connector.yaml -n debezium
	```
16. Edit the provided `eventhubs-secret.yaml` to include your Azure Event Hub connection string and create a Secret from it on AKS:
	* replace `<your-azure-eventhub-connection-string>` with your Azure Event Hub connection string
	* then apply it to AKS:
	```pwsh
	kubectl apply -f eventhubs-secret.yaml -n debezium
	```
17. Deploy Kafka Mirrormaker2
	* edit the provided `mirrormaker2-to-aeh.yaml` replacing `<your-azure-eventhub-name>` with the name you gave to your Azure Event Hub
	* edit the provided `mirrormaker2-to-aeh.yaml` replacing `<your-mysql-server-name>` with the name you gave to your Azure Database for MySQL server
	* then apply it to AKS:
	```pwsh
	kubectl apply -f mirrormaker2-to-aeh.yaml -n debezium
	```
	
####
#### And voilà... all changes happening on your MySQL database are being monitored by Debezium, CDC events are being generated and those are being forwarded to Azure Event Hub... 
####



---
# Some useful commands:

### scale up and down the KafkaConnector cluster
```pwsh
kubectl scale deployment debezium-cdc-cluster-connect --replicas=0 -n debezium
kubectl scale deployment debezium-cdc-cluster-connect --replicas=1 -n debezium
```

### restart the KafkaMirrorMaker2 cluster
```pwsh
kubectl annotate KafkaMirrorMaker2 kafka2eventhub-mirror-cluster "strimzi.io/restart-connector-task=local-kafka-cluster->azure-eventhub.MirrorSourceConnector:0" -n debezium
```

### send/consume messages to/from Kafka cluster
```pwsh
kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-producer.sh --broker-list kafka-cdc-cluster-kafka-bootstrap:9092 --topic strimzi-test-topic
kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server kafka-cdc-cluster-kafka-bootstrap:9092 --topic strimzi-test-topic --from-beginning
```

### view all topics on Kafka cluster
```pwsh
kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-topics.sh --list --bootstrap-server kafka-cdc-cluster-kafka-bootstrap:9092
```

### KafkaConnector deployment status check
```pwsh
kubectl get kctr pedidos-cdc-connector -o yaml -n debezium
```

### view all connectors
```pwsh
kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- curl -X GET http://debezium-cdc-cluster-connect-api:8083/connectors
```

### consume cdc events for tables pedido & item_pedido
```pwsh
kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server kafka-cdc-cluster-kafka-bootstrap:9092 --topic tdc-connections-2021-db.tdc_connections_2021_cdc.pedido --from-beginning
kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server kafka-cdc-cluster-kafka-bootstrap:9092 --topic tdc-connections-2021-db.tdc_connections_2021_cdc.item_pedido --from-beginning
```
