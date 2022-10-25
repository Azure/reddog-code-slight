###############################################################################
# Infrastructure dependencies (not including cluster)
###############################################################################

RG="rg-reddog"
LOC="southcentralus"

# If RG does not exist...
# az group create -g $RG -l $LOC

# If SP with Owner permissions for the RG does not exist...
# az ad sp create-for-rbac \
#     --role Owner \
#     --scope /subscriptions/6d1cc86a-ad12-4f88-8923-5e0c418b4acf/resourceGroups/$RG
# Output includes data required for:
# * userDefinedServicePrincipalAppId parameter for ./bicep/main.bicep deployment
# * azureClientId/azureClientSecret/azureTenantId for ./cluster/components/reddog.secretstore.yaml

# Provision dependencies...
az deployment group create -n reddog -g $RG -f ./bicep/main.bicep -p userDefinedServicePrincipalAppId=$APP_ID

# STOP: MANUAL STEP!!!
# Update ./cluster/components/reddog.secretstore.yaml with valid values. It needs:
# 1. 'vaultName': The name of the Key Vault provisioned
# 2. 'azureTenantId': The tenant ID for the SP created
# 3. 'azureClientId': The 'appId' for the SP created
# 4. 'azureClientSecret': The 'password' for the SP created

###############################################################################
# Cluster bits
###############################################################################

# K3d
# Create cluster if it does not exist...
# k3d cluster create k3d-reddog -p '8083:80@loadbalancer' --k3s-arg '--disable=traefik@server:0'
k3d cluster create wasm-cluster --image ghcr.io/deislabs/containerd-wasm-shims/examples/k3d:latest -p "8080:80@loadbalancer" --agents 2
kubectl apply -f https://github.com/deislabs/containerd-wasm-shims/releases/download/v0.3.0/slight_runtime.yaml

# Install Dapr control plane in the cluster (uses current config)
dapr init -k

# Create the reddog namespace
kubectl create -f ./cluster/namespace.yaml

# Deploy components
kubectl apply -f ./cluster/components/reddog.binding.receipt.yaml
kubectl apply -f ./cluster/components/reddog.pubsub.yaml
kubectl apply -f ./cluster/components/reddog.secretstore.yaml
kubectl apply -f ./cluster/components/reddog.state.makeline.yaml

# Deploy services
kubectl apply -f ./cluster/deployments/order-service.yaml
kubectl apply -f ./cluster/deployments/receipt-generation-service.yaml
kubectl apply -f ./cluster/deployments/virtual-customers.yaml

# Check all is well
kubectl get pods -n reddog
# kubectl logs receipt-generation-service-podname -n reddog

###############################################################################
# Build OCI artifact
###############################################################################

# Login to supported container registry (docker, aks acr login)
az acr login -n awkwardindustries

# Build and push (from project root where Dockerfile is located)
cd ../../
docker build -t awkwardindustries.azurecr.io/reddog/receipt-generation-service:slight
docker push awkwardindustries.azurecr.io/reddog/receipt-generation-service:slight
cd ./deploy/manual

###############################################################################
# Add regcred for ACR
###############################################################################

ACRNAME=awkwardindustries
ACR_FQDN=$(az acr show -n $ACRNAME --query "{acrLoginServer:loginServer}" -o tsv)
ACR_USER=$(az acr credential show -n $ACRNAME --query "username" -o tsv)
ACR_PASSWD=$(az acr credential show -n $ACRNAME --query "passwords[0].value" -o tsv)
kubectl create -n reddog secret docker-registry regcred \
  --docker-server=$ACR_FQDN \
  --docker-username=$ACR_USER \
  --docker-password=$ACR_PASSWD

###############################################################################
# Redeploy Receipt Service -- on slight
###############################################################################

kubectl delete deployment receipt-generation-service -n reddog
kubectl apply -f ./cluster/deployments/receipt-generation-service-slight.yaml
