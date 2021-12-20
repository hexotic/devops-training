# Create namespace
kubectl apply -f namespace.yml 

# Create pods
kubectl apply -f pod-red.yml -f pod-blue.yml

# Associate pods to namespace
kubectl apply -f service-nodeport-web.yml 

# Check pods are associated
kubectl -n production describe po
