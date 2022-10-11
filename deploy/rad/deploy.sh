# Make sure you have a cluster & active config
# If something like AKS...
rad env init kubernetes -i

# If going with Codespaces / k3s... (note 8083 must be free on local, but it can be whatever)
# k3d cluster create k3s-reddog -p '8083:80@loadbalancer' --k3s-arg '--disable=traefik@server:0'
# rad env init kubernetes --public-endpoint-override 'localhost:8083' -i

rad deploy app.bicep