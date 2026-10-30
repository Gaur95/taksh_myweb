# Prometheus + Grafana Installation (Helm)

Install **kube-prometheus-stack** with Helm. This chart includes Prometheus,
Grafana, Alertmanager, node-exporter, and kube-state-metrics.

Namespace used: `monitoring`

---

## Prerequisites

- `kubectl` talking to the cluster
- Helm 3 (`helm version`)

```bash
kubectl get nodes
helm version
```

---

## 1. Add Helm repos

Prometheus stack (Prometheus + Grafana + Alertmanager):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

Grafana charts (optional, if you install Grafana separately):

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

Update local repo cache (always run this before install):

```bash
helm repo update
```

List added repos:

```bash
helm repo list
```

Search charts in the repo:

```bash
helm search repo prometheus-community
helm search repo prometheus-community/kube-prometheus-stack
helm search repo grafana
```

Show chart versions:

```bash
helm search repo prometheus-community/kube-prometheus-stack --versions
```

---

## 2. Create the namespace

```bash
kubectl create namespace monitoring
```

Skip this if `monitoring` already exists. `--create-namespace` in the next step
also creates it.

---

## 3. Install kube-prometheus-stack

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.resources.requests.memory=400Mi \
  --set grafana.resources.requests.memory=128Mi
```

Pin a chart version:

```bash
helm search repo prometheus-community/kube-prometheus-stack --versions | head
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --version <CHART_VERSION>
```

---

## 4. Verify

```bash
helm list -n monitoring
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Wait until pods are Ready:

```bash
kubectl get pods -n monitoring -w
```

Expected components:

| Component | What it is |
|---|---|
| `kube-prometheus-stack-prometheus` | Prometheus server |
| `kube-prometheus-stack-grafana` | Grafana UI |
| `kube-prometheus-stack-alertmanager` | Alertmanager |
| `prometheus-node-exporter` | Node metrics |
| `kube-state-metrics` | Kubernetes object metrics |
| `kube-prometheus-stack-operator` | Prometheus Operator |

---

## 5. Access Grafana

`ClusterIP` service — use port-forward:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Open: [http://localhost:3000](http://localhost:3000)

- Username: `admin`
- Password: `admin` (set during install)

If you did not set `--set grafana.adminPassword=...`:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

---

## 6. Access Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Open: [http://localhost:9090](http://localhost:9090)

Alertmanager:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```

Open: [http://localhost:9093](http://localhost:9093)

---

## Useful Helm commands

```bash
# What is installed
helm list -n monitoring

# Values used by this release
helm get values kube-prometheus-stack -n monitoring

# Upgrade after changing values
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --set grafana.adminPassword=admin

# History / rollback
helm history kube-prometheus-stack -n monitoring
helm rollback kube-prometheus-stack 1 -n monitoring
```

---

## Uninstall

```bash
helm uninstall kube-prometheus-stack -n monitoring
```

Helm does **not** delete CRDs. Remove them if you want a clean wipe:

```bash
kubectl delete crd \
  alertmanagerconfigs.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  podmonitors.monitoring.coreos.com \
  probes.monitoring.coreos.com \
  prometheusagents.monitoring.coreos.com \
  prometheuses.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com \
  scrapeconfigs.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  thanosrulers.monitoring.coreos.com
```

Optional:

```bash
kubectl delete namespace monitoring
helm repo remove prometheus-community
```

---

## Repo reference

| Repo name | URL | Chart |
|---|---|---|
| `prometheus-community` | https://prometheus-community.github.io/helm-charts | `kube-prometheus-stack` |
| `grafana` | https://grafana.github.io/helm-charts | `grafana` (standalone, not needed with the stack) |

Chart docs: [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
