#!/bin/bash
# Auto-Remediation Script - DevSecOps Platform
# Détecte et isole automatiquement les pods compromis

LOG_FILE="/tmp/incident-reports/incident-$(date +%Y%m%d-%H%M%S).log"
mkdir -p /tmp/incident-reports

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Fonction isolation pod compromis
isolate_pod() {
  local POD=$1
  local NAMESPACE=$2
  
  log "ALERTE: Pod suspect détecté - $POD dans $NAMESPACE"
  log "ACTION: Isolation du pod en cours..."
  
  # Ajouter label quarantine
  kubectl label pod "$POD" -n "$NAMESPACE" security=quarantine --overwrite
  
  # Appliquer Network Policy d'isolation
  cat << POLICY | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-$POD
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      security: quarantine
  policyTypes:
  - Ingress
  - Egress
POLICY

  log "OK: Pod $POD isolé - tout trafic réseau bloqué"
  log "RAPPORT: Incident enregistré dans $LOG_FILE"
}

# Fonction vérification pods suspects
check_suspicious_pods() {
  log "=== Scan des pods suspects ==="
  
  # Vérifier pods en CrashLoop
  CRASHLOOP_PODS=$(kubectl get pods -A \
    --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.namespace}{" "}{range .status.containerStatuses[*]}{.restartCount}{end}{"\n"}{end}' \
    | awk '$3 > 5 {print $1,$2}')
  
  if [ -n "$CRASHLOOP_PODS" ]; then
    log "ALERTE: Pods avec trop de restarts détectés:"
    echo "$CRASHLOOP_PODS" | while read POD NS; do
      log "  - $POD dans $NS"
      isolate_pod "$POD" "$NS"
    done
  else
    log "OK: Aucun pod suspect détecté"
  fi
}

# Fonction rapport d'incident
generate_incident_report() {
  local REPORT="/tmp/incident-reports/report-$(date +%Y%m%d-%H%M%S).txt"
  
  cat > "$REPORT" << REPORT
================================================
RAPPORT D'INCIDENT - DevSecOps Platform
Date: $(date)
Cluster: $(kubectl config current-context)
================================================

ÉTAT DU CLUSTER:
$(kubectl get nodes)

PODS EN QUARANTAINE:
$(kubectl get pods -A -l security=quarantine 2>/dev/null || echo "Aucun pod en quarantaine")

EVENTS RÉCENTS SUSPECTS:
$(kubectl get events -A --sort-by='.lastTimestamp' | grep -E "Warning|Error" | tail -20)

ALERTES FALCO RÉCENTES:
$(kubectl logs -n security -l app.kubernetes.io/name=falco --tail=20 2>/dev/null | grep -E "Warning|Error|Notice" | tail -10)

NAMESPACES ET PODS:
$(kubectl get pods -A -o wide)
================================================
REPORT

  log "Rapport généré: $REPORT"
  cat "$REPORT"
}

# Main
log "=== Démarrage Auto-Remediation ==="
check_suspicious_pods
generate_incident_report
log "=== Auto-Remediation terminé ==="
