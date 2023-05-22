# Kubermatic cluster information
PROJECT_ID=l8zvpg6dph
CLUSTER_ID=o2rntfnl62
# namespace in which Prow itself will be running
PROW_NAMESPACE=prow
# namespace in which Prow jobs will be running
PROW_TESTPOD_NAMESPACE=default
PROW_HOOK_DOMAIN=prow.kcp.k8c.io
PROW_DECK_DOMAIN=prow.kcp.k8c.io
PROW_DECK_PUBLIC_DOMAIN=public-prow.kcp.k8c.io
GCSWEB_DOMAIN=gcsweb.kcp.k8c.io
GCSWEB_PUBLIC_DOMAIN=public-gcsweb.kcp.k8c.io
# These are _Helm chart_ versions, not application versions!
CERT_MANAGER_VERSION=1.10.1
INGRESS_NGINX_VERSION=4.4.2
# Note that this is https://artifacthub.io/packages/helm/minio-official/minio,
# not to be confused with packages/helm/minio/minio, which is EOL.
MINIO_VERSION=5.0.9
