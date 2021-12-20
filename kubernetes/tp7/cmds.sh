#/bin/sh
kubectl apply -f .
kubectl port-forward webapp 8080:8080 --address 0.0.0.0
