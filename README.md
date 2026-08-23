# Kubernetes DevSecOps & PKI Observability Platform (AWS)

Plateforme personnelle de démonstration DevSecOps sur AWS EKS, intégrant l'infrastructure as code, une application conteneurisée, une sécurité Kubernetes multicouche, l'observabilité et l'auto-remédiation en cas de compromission.

## 🎯 Objectif du projet

Concevoir et déployer une plateforme Kubernetes de bout en bout illustrant les bonnes pratiques DevSecOps : provisionner l'infrastructure cloud via Terraform, sécuriser le cluster dès la conception (RBAC, Network Policies, OPA, Falco), superviser en continu (alerting) et réagir automatiquement aux incidents de sécurité.

## 🏗️ Architecture du dépôt

```
.
├── app/                        # Application conteneurisée
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── k8s/                        # Manifests Kubernetes
│   ├── app/
│   │   ├── deployment.yaml
│   │   ├── namespace.yaml
│   │   └── service.yaml
│   ├── monitoring/
│   │   ├── alertmanager-config.yaml
│   │   └── security-alerts.yaml
│   └── security/
│       ├── auto-remediation-cronjob.yaml
│       ├── network-policies.yaml
│       ├── opa-constraints.yaml
│       ├── opa-policies.yaml
│       ├── rbac.yaml
│       └── falco/
│           └── custom-rules.yaml
├── scripts/
│   └── auto-remediation.sh
└── terraform/                  # Infrastructure as Code
    ├── backend.tf
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    └── modules/
        ├── vpc/
        ├── eks/
        └── ecr/
```

## ⚙️ Composants

### Infrastructure (Terraform)
- **`modules/vpc`** : réseau AWS (VPC, subnets).
- **`modules/eks`** : cluster Kubernetes managé (EKS).
- **`modules/ecr`** : registre d'images Docker (ECR).
- Backend Terraform distant configuré (`backend.tf`) pour la gestion d'état.

### Application (`app/`)
- Application Python conteneurisée (`app.py`, `Dockerfile`, `requirements.txt`), déployée sur le cluster via les manifests dans `k8s/app/`.

### Sécurité Kubernetes (`k8s/security/`)
- **RBAC** (`rbac.yaml`) : contrôle d'accès basé sur les rôles.
- **Network Policies** (`network-policies.yaml`) : cloisonnement réseau entre workloads.
- **OPA / Gatekeeper** (`opa-policies.yaml`, `opa-constraints.yaml`) : application de politiques de conformité (policy as code).
- **Falco** (`falco/custom-rules.yaml`) : règles personnalisées de détection d'anomalies runtime.
- **Auto-remédiation** (`auto-remediation-cronjob.yaml` + `scripts/auto-remediation.sh`) : CronJob Kubernetes exécutant un script d'isolation automatique des ressources compromises.

### Observabilité (`k8s/monitoring/`)
- **AlertManager** (`alertmanager-config.yaml`) : configuration du routage des alertes.
- **Security alerts** (`security-alerts.yaml`) : règles d'alerte dédiées aux événements de sécurité.

## 🚀 Installation

### 1. Provisionner l'infrastructure AWS

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Configurer l'accès au cluster

```bash
aws eks update-kubeconfig --name <nom-du-cluster> --region <région>
```

### 3. Déployer la sécurité Kubernetes

```bash
kubectl apply -f k8s/security/rbac.yaml
kubectl apply -f k8s/security/network-policies.yaml
kubectl apply -f k8s/security/opa-policies.yaml
kubectl apply -f k8s/security/opa-constraints.yaml
kubectl apply -f k8s/security/falco/custom-rules.yaml
kubectl apply -f k8s/security/auto-remediation-cronjob.yaml
```

### 4. Déployer l'application

```bash
kubectl apply -f k8s/app/namespace.yaml
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
```

### 5. Déployer la supervision

```bash
kubectl apply -f k8s/monitoring/alertmanager-config.yaml
kubectl apply -f k8s/monitoring/security-alerts.yaml
```

## 📋 Prérequis

- Compte AWS avec les droits nécessaires (VPC, EKS, ECR, IAM)
- Terraform
- kubectl
- AWS CLI configuré
- Docker (pour builder l'image de `app/`)

## 🔐 Fonctionnement de l'auto-remédiation

Le CronJob `auto-remediation-cronjob.yaml` déclenche périodiquement `scripts/auto-remediation.sh`, qui :
1. Détecte les pods signalés comme compromis (via les alertes Falco/AlertManager).
2. Isole automatiquement ces pods (ex. application d'une Network Policy restrictive ou suppression du pod).
3. Génère un rapport d'incident.

## 📈 Roadmap

- [ ] Ajouter des tests d'intégration automatisés (CI)
- [ ] Étendre la couverture Falco avec des règles personnalisées supplémentaires
- [ ] Documenter les runbooks d'incident

## 👩‍💻 Auteure

**Noura Douvawissa** — Étudiante en Master 1 Cybersécurité & Cloud Computing (IPSSI Lille)
[GitHub](https://github.com/Dna-0324)
