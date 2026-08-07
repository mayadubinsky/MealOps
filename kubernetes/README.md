# MealOps Kubernetes

Kubernetes manifests for deploying MealOps to AKS.

## Files

- `deployment.yaml` - Deploys the MealOps application.
- `service.yaml` - Exposes MealOps using a LoadBalancer service.
- `kustomization.yaml` - Groups the Kubernetes manifests together.

## Apply

kubectl apply -k .

## Check resources

kubectl get all

Check pods:
kubectl get pods

Check service:
kubectl get service mealops

Check service endpoints:
kubectl get endpoints mealops

## Troubleshooting

Describe a pod:
kubectl describe pod <pod-name>

View application logs:
kubectl logs <pod-name>

## Delete
kubectl delete -k .

## Health checks

The Deployment uses:

- `/health/ready` for the readiness probe.
- `/health/live` for the liveness probe.

## AI API key

Create the Kubernetes Secret before deploying:

```bash
kubectl create secret generic mealops-ai-secret \
  --from-literal=GEMINI_API_KEY="<your-key>"