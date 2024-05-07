# oci-prow-cluster

This directory deploys the `oci-prow-cluster` OKE cluster in OCI (Oracle Cloud) via [OpenTofu](https://opentofu.org). A shared state is stored in a OCI storage bucket, please make sure to use that. Usually, this code shouldn't be executed directly but run by Prow.

## Required Environment Variables

The following environment variables are required before running any `make` targets:

- `AWS_ACCESS_KEY_ID`: Needs to be the key ID for a [Customer Secret Key](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2) to access OCI's S3-compatible storage buckets.
- `AWS_SECRET_ACCESS_KEY`: Needs to be the secret for a [Customer Secret Key](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2) to access OCI's S3-compatible storage buckets.
- `AWS_ENDPOINT_URL_S3`: Needs to be `https://<object namespace>.compat.objectstorage.us-sanjose-1.oraclecloud.com`. Replace `<object namespace>` with the namespace displayed on the bucket (see OCI Console for this information).
