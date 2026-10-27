# Argo CD Installation Guide (minikube)

This cluster has Argo CD **v3.5.6** installed in the `argocd` namespace.
All core pods are Running and `/healthz` returns HTTP 200.

Use the **cluster-scoped** manifest (`install.yaml`) on this minikube cluster.
That lets Argo CD deploy apps to the same cluster (`https://kubernetes.default.svc`).

Do **not** use `namespace-install.yaml` here. That file does not create the namespace,
does not include CRDs, and does not grant cluster roles. Same-cluster deploys will be limited.

---

## Prerequisites

- `kubectl` installed and talking to the cluster
- Cluster admin access (needed for CRDs and ClusterRoles)

```bash
kubectl get nodes
kubectl get ns
```

---

## 1. Create the namespace

```bash
kubectl create namespace argocd
```

Skip this if `argocd` already exists.

---

## 2. Install Argo CD

Official recommended install (same-cluster deploy):

```bash
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

`--server-side` is required because some Argo CD CRDs are larger than the
client-side apply annotation limit (262KB).

To pin a version instead of `stable`:

```bash
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.6/manifests/install.yaml
```

This creates:

| Component | Kind |
|---|---|
| `argocd-server` | Deployment (API + UI) |
| `argocd-repo-server` | Deployment (Git clone / manifest render) |
| `argocd-application-controller` | StatefulSet (sync / health) |
| `argocd-applicationset-controller` | Deployment |
| `argocd-redis` | Deployment (cache) |
| `argocd-dex-server` | Deployment (SSO) |
| `argocd-notifications-controller` | Deployment |
| CRDs | `Application`, `ApplicationSet`, `AppProject` |

---

## 3. Verify the install

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
kubectl get crd | grep argo
kubectl get appprojects -n argocd
```

Expected: **7/7 pods** `Running` and `1/1` Ready.

```text
NAME                                                READY   STATUS    RESTARTS
argocd-application-controller-0                     1/1     Running   0
argocd-applicationset-controller-...                1/1     Running   0
argocd-dex-server-...                               1/1     Running   0
argocd-notifications-controller-...                 1/1     Running   0
argocd-redis-...                                    1/1     Running   0
argocd-repo-server-...                              1/1     Running   0
argocd-server-...                                   1/1     Running   0
```

Health check from inside the cluster:

```bash
kubectl run curl-argo --rm -i --restart=Never --image=curlimages/curl:8.5.0 --command -- \
  curl -sk -o /dev/null -w "%{http_code}\n" https://argocd-server.argocd.svc.cluster.local/healthz
```

Expected output: `200`

Startup Redis timeouts in controller/server logs are normal. Redis starts a few
seconds later; they recover on their own.

---

## 4. Access the UI

`argocd-server` is `ClusterIP` (not exposed outside the cluster).

Port-forward:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open: [https://localhost:8080](https://localhost:8080)

The cert is self-signed. Browser warning is expected.

---

## 5. Login

Username: `admin`

Initial password (auto-generated):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
```

Or with the CLI:

```bash
argocd admin initial-password -n argocd
```

Change the password after first login, then delete the bootstrap secret:

```bash
kubectl -n argocd delete secret argocd-initial-admin-secret
```

---

## 6. Optional: Argo CD CLI login

```bash
argocd login localhost:8080 --insecure
```

If you only use kubeconfig (no UI login):

```bash
argocd login --core
kubectl config set-context --current --namespace=argocd
```

---

## 7. Create a sample app

```bash
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

argocd app sync guestbook
argocd app get guestbook
```

Same thing as a YAML `Application`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

```bash
kubectl apply -f guestbook-app.yaml
kubectl -n argocd patch application guestbook --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

---

## Manifest comparison

| File | What it installs | Use when |
|---|---|---|
| `manifests/install.yaml` | Full Argo CD + CRDs + ClusterRoles | Same cluster deploy (this minikube) |
| `manifests/namespace-install.yaml` | Namespace-scoped Roles only, **no CRDs** | External clusters only, no cluster-admin |
| `manifests/ha/install.yaml` | HA version of `install.yaml` | Production |

If you must use `namespace-install.yaml`, install CRDs first:

```bash
kubectl create namespace argocd
kubectl apply --server-side --force-conflicts \
  -k https://github.com/argoproj/argo-cd/manifests/crds?ref=stable
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/namespace-install.yaml
```

---

## Uninstall

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io
```

---

## Current cluster snapshot

Checked on this minikube cluster after install:

- Namespace: `argocd`
- Version: `v3.5.6`
- Pods: 7/7 Running
- Services: `argocd-server` ClusterIP `80/443`
- CRDs: `applications.argoproj.io`, `applicationsets.argoproj.io`, `appprojects.argoproj.io`
- Default project: `AppProject/default` in `argocd`
- Health: `https://argocd-server.argocd.svc.cluster.local/healthz` → `200`

Official docs: [Argo CD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
