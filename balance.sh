RG=$(az group list | grep name | awk -F\: '{print $2}' | awk -F\" '{print $2}')


az network public-ip create \
    --resource-group $RG \
    --name myPublicIP


az network lb create \
    --resource-group $RG \
    --name myLoadBalancer \
    --frontend-ip-name myFrontEndPool \
    --backend-pool-name myBackEndPool \
    --public-ip-address myPublicIP

az network lb probe create \
    --resource-group $RG \
    --lb-name myLoadBalancer \
    --name myHealthProbe \
    --protocol tcp \
    --port 80

az network lb rule create \
    --resource-group $RG \
    --lb-name myLoadBalancer \
    --name myLoadBalancerRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name myFrontEndPool \
    --backend-pool-name myBackEndPool \
    --probe-name myHealthProbe

az network vnet create \
    --resource-group $RG \
    --name myVnet \
    --subnet-name mySubnet

az network nsg create \
    --resource-group $RG \
    --name myNetworkSecurityGroup

az network nsg rule create \
    --resource-group $RG \
    --nsg-name myNetworkSecurityGroup \
    --name myNetworkSecurityGroupRule \
    --priority 1001 \
    --protocol tcp \
    --destination-port-range 80


for i in `seq 1 3`; do
    az network nic create \
        --resource-group $RG \
        --name myNic$i \
        --vnet-name myVnet \
        --subnet mySubnet \
        --network-security-group myNetworkSecurityGroup \
        --lb-name myLoadBalancer \
        --lb-address-pools myBackEndPool
done


az vm availability-set create \
    --resource-group $RG \
    --name myAvailabilitySet


for i in `seq 1 3`; do
    az vm create \
        --resource-group $RG \
        --name myVM$i \
        --availability-set myAvailabilitySet \
        --nics myNic$i \
        --image UbuntuLTS \
        --admin-username azureuser \
        --generate-ssh-keys \
        --custom-data cloud-init.txt \
        --no-wait
done

echo "======== ESPERA ========="
sleep 300
echo "========================="

az network public-ip show \
    --resource-group $RG \
    --name myPublicIP \
    --query [ipAddress] \
    --output tsv
