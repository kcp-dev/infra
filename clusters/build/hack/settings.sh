# Kubermatic cluster information
PROJECT_ID=l8zvpg6dph
CLUSTER_ID=avznsmznpt

# namespace in which Prow jobs will be running; this is
# important so we can provision secrets like S3 credentials
# in a namespace where a deploy job could then pick them
# up by spread them to all the other build clusters
# (in a kcp-managed job)
PROW_TESTPOD_NAMESPACE=default
