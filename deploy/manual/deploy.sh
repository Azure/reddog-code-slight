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

# Install Dapr control plane in the cluster (uses current config)
dapr init -k

# Install metrics-server (TODO: CHECK WITH STEVE ON APPROACH)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

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