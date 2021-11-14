# Tutorial - CDC with Debezium running on AKS and sending events to Azure Event Hub
## This was created as a demo to present at TDC Connections 2021, MVPConf2021 and TDC Future 2021 conferences, on sessions which I spoke about Event Driven Architectures and CDC and showed how to deploy Debezium on AKS, configure it to capture changes from a MySQL database and send those events to Azure Event Hub

1. Pre-reqs => For running this demo you will need to:
 	* An Azure Subscription where you have administrative permissions
 	* A Cloud Shell configured to use Bash on that subscription

2. Start creating the infrastructure you will need:
	* Use the Bash environment on [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart). 
		- [![Opens Azure Cloud Shell in new window](https://docs.microsoft.com/en-us/azure/includes/media/cloud-shell-try-it/hdi-launch-cloud-shell.png)](https://shell.azure.com/)
	* Select your Subscription, if you have more than one, and create the resource group:
		```bash
		az account set --subscription '<your-subscription-name-or-id>'
		az group create --location eastus --resource-group demodebezium-rg
		```
	* Create:
	 	- An AKS (Azure Kubernetes Service) cluster; 
	 	- An Azure Database for MySQL server;
	 	- An ACR (Azure Container Registry) repository, and;
	 	- An Azure Event Hub namespace
		```bash
		az aks create --resource-group demodebezium-rg --name demodbzakscluster --node-count 2 --enable-addons monitoring --generate-ssh-keys
		az mysql server create --resource-group demodebezium-rg --name demodbzmysql --location eastus --admin-user debezium --admin-password P@ssw0rd2021 --sku-name B_Gen5_1 --storage-size 5120 --version 8.0
		az acr create --resource-group demodebezium-rg --name demodbzacr --sku Basic
		az eventhubs namespace create --name demodebezium-ns --resource-group demodebezium-rg -l eastus
		```
		
		- **_You will probably need to change the names used here for the MySQL server, the ACR repository and the Event Hub namespace because those names need to be unique. If you do that, you will need to remember to change those names on subsequent commands and, also, inside the provided files. Following is a list of files and the references they have inside:_** 

			| Provided File | References inside |
			|---|---|
			| [debezium-mysql-connector.yaml](./debezium-mysql-connector.yaml) | MySQL server |
			| [kafka-connect.yaml](./kafka-connect.yaml) | ACR repository |
			| [mirrormaker2-to-aeh.yaml](./mirrormaker2-to-aeh.yaml) | Azure Event Hub namespace, MySQL server |
			| [mysql-secret.properties](./mysql-secret.properties) | MySQL server |

3. Configure some basic things on your MySQL database:
	* Connect to your recently created MySQL (using [MySQL Workbench](https://dev.mysql.com/downloads/workbench/) or any other client tool of your preference), and:
		```sql
		SET SQL_SAFE_UPDATES=0;
		CALL mysql.az_load_timezone();
		GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium';
		FLUSH PRIVILEGES;
		```
	* On [Azure Portal](https://portal.azure.com/), go to your newly created MySQL server, called `demodbzmysql`, select "Server Properties" on left menu, and:
		- set `binlog_row_image` to `FULL`
		- set `binlog_expire_logs_seconds` to `7200`
		- set `time_zone` to ***<your-time-zone>***
			- mine is `America/Sao_Paulo`, you can find the available time zones by querying the database:
			```sql
			SELECT name FROM mysql.time_zone_name;
			```
	* You can find more information about MySQL required configurations, [here, on Debezium documentation](https://debezium.io/documentation/reference/connectors/mysql.html#setting-up-mysql).

	* After deploying and configuring the MySQL server, you can use the provided SQL script [demo_debezium_cdc_db.sql](./demo_debezium_cdc_db.sql) to create the simple schema used on this demo. Just open this script on MySQL Workbench and run it.

4. Download from GitHub and unzip the latest version of Strimzi:
	```bash
	curl -L https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.26.0/strimzi-0.26.0.tar.gz --output strimzi-0.26.0.tar.gz
	tar -xvzf strimzi-0.26.0.tar.gz
	rm strimzi-0.26.0.tar.gz
	```

5. Download from Maven and unzip the latest version of Debezium Kafka Connector for MySQL:
	```bash
	curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/1.7.1.Final/debezium-connector-mysql-1.7.1.Final-plugin.tar.gz --output debezium-connector-mysql-1.7.1.Final-plugin.tar.gz
	tar -xvzf debezium-connector-mysql-1.7.1.Final-plugin.tar.gz
	rm debezium-connector-mysql-1.7.1.Final-plugin.tar.gz
	```

6. Connect to AKS and prepare to install Strimzi:
	```bash
	az aks get-credentials --resource-group demodebezium-rg --name demodbzakscluster
	kubectl create ns strimzi
	kubectl create ns debezium
	```

7. Change Strimzi installation files to use your created namespaces:
	* change all files named as `strimzi-0.26.0/install/cluster-operator/\*RoleBinding\*.yaml` replacing `namespace: myProject` with `namespace: strimzi`
	* edit `strimzi-0.26.0/install/cluster-operator/060-Deployment-strimzi-cluster-operator.yaml` file to change the `STRIMZI_NAMESPACE` environment variable setting:
	```yaml
	# ...
	env:
	- name: STRIMZI_NAMESPACE
	  value: debezium
	# ...
	```

8. Deploy Strimzi to your AKS cluster and, then, give it permissions to operate on debezium namespace
	```bash
	kubectl create -f install/cluster-operator/ -n strimzi
	kubectl create -f install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n debezium
	kubectl create -f install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml -n debezium
	kubectl create -f install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n debezium
	```

9. Use Strimzi to install the Kafka Cluster on your AKS
	* edit `strimzi-0.26.0/examples/kafka/kafka-persistent.yaml`, just to define a more significant name for your kafka cluster:
	```yaml
	# ...
	metadata:
	  name: cdc-cluster
	# ...
	```
	* then apply it to your AKS cluster:
	```bash
	kubectl apply -f strimzi-0.26.0/examples/kafka/kafka-persistent.yaml -n debezium
	```
	* wait for cluster to be ready... it will take a while... you can check with:
	```bash
	kubectl get pods -n debezium
	```
	
10. Use Kafka shell utilities to produce and consume messages to check if your Kafka cluster is running well:
	```bash
	kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-producer.sh --broker-list kafka-cdc-cluster-kafka-bootstrap:9092 --topic my-test-topic
	kubectl exec -n debezium -i kafka-cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server kafka-cdc-cluster-kafka-bootstrap:9092 --topic my-test-topic --from-beginning
	```

11. Prepare to create a Kafka Connect docker image with Debezium and MySQL plugins:
	* create a `Dockerfile` with the following lines (or use the [provided one](./Dockerfile)):
	```dockerfile
	FROM quay.io/strimzi/kafka:latest-kafka-3.0.0
	USER root:root
	RUN mkdir -p /opt/kafka/plugins/debezium
	COPY ./debezium-connector-mysql/ /opt/kafka/plugins/debezium/
	USER 1001
	```

13. Build the image, push it to Azure Container Registry and attach ACR to your AKS cluster:
	```bash
	az acr build --image debezium/mysql-plugin:v1 --image debezium/mysql-plugin:latest --registry demodbzacr --file Dockerfile .
	az aks update -n demodbzakscluster -g demodebezium-rg --attach-acr demodbzacr
	```

14. If you have changed the MySQL credentials, edit the provided [mysql-secret.properties](./mysql-secret.properties) to include your MySQL credentials, then create a Secret from it on AKS:
	```bash
	kubectl -n debezium create secret generic mysql-credentials --from-file=mysql-secret.properties
	```

15. Deploy the Kafka Connect to your AKS cluster using your custom image that includes Debezium and MySQL plugins. Use the provided [kafka-connect.yaml](./kafka-connect.yaml).
	```bash
	kubectl apply -f kafka-connect.yaml -n debezium
	```

16. Configure the Debezium/MySQL connector to start capturing data changes on MySQL database. Use the provided [debezium-mysql-connector.yaml](./debezium-mysql-connector.yaml). 
	```bash
	kubectl apply -f debezium-mysql-connector.yaml -n debezium
	```

17. Edit the provided [eventhubs-secret.yaml](./eventhubs-secret.yaml) to include your Azure Event Hub connection string, then create a Secret from it on AKS:
	* replace `<your-azure-eventhub-connection-string>` with your Azure Event Hub connection string
	* then apply it to AKS:
	```bash
	kubectl apply -f eventhubs-secret.yaml -n debezium
	```
18. Deploy the Kafka Mirrormaker2 to your AKS cluster. Use the provided [mirrormaker2-to-aeh.yaml](./mirrormaker2-to-aeh.yaml).
	```bash
	kubectl apply -f mirrormaker2-to-aeh.yaml -n debezium
	```
	
####
#### And voilà... Now all changes happening on your MySQL database are being monitored by Debezium, and all CDC events are being posted on Kafka topics and being forwarded to Azure Event Hub... 
####



---
# Some useful commands:

### scale up and down the KafkaConnector cluster - a way to restart it
```bash
kubectl scale deployment cdc-cluster-connect --replicas=0 -n debezium
kubectl scale deployment cdc-cluster-connect --replicas=1 -n debezium
```

### restart the KafkaMirrorMaker2 cluster
```bash
kubectl annotate KafkaMirrorMaker2 kafka2eventhub-mirror-cluster "strimzi.io/restart-connector-task=local-kafka-cluster->azure-eventhub.MirrorSourceConnector:0" -n debezium
```

### send/consume messages to/from Kafka cluster
```bash
kubectl exec -n debezium -i cdc-cluster-kafka-0 -- bin/kafka-console-producer.sh --broker-list cdc-cluster-kafka-bootstrap:9092 --topic strimzi-test-topic
kubectl exec -n debezium -i cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server cdc-cluster-kafka-bootstrap:9092 --topic strimzi-test-topic --from-beginning
```

### view all topics on Kafka cluster
```bash
kubectl exec -n debezium -i cdc-cluster-kafka-0 -- bin/kafka-topics.sh --list --bootstrap-server cdc-cluster-kafka-bootstrap:9092
```

### KafkaConnector deployment status check
```bash
kubectl get kctr orders-cdc-connector -o yaml -n debezium
```

### view all connectors
```bash
kubectl exec -n debezium -i cdc-cluster-kafka-0 -- curl -X GET http://debezium-cdc-cluster-connect-api:8083/connectors
```

### consume cdc events for tables ORDER & ORDER_ITEM
```bash
kubectl exec -n debezium -i cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server cdc-cluster-kafka-bootstrap:9092 --topic demodbzmysql.demo_debezium_cdc_db.order --from-beginning
kubectl exec -n debezium -i cdc-cluster-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server cdc-cluster-kafka-bootstrap:9092 --topic demodbzmysql.demo_debezium_cdc_db.order_item --from-beginning
```
