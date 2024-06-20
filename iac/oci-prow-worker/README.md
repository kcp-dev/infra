# oci-prow-cluster

This directory deploys the `oci-prow-cluster` OKE cluster in OCI (Oracle Cloud) via [OpenTofu](https://opentofu.org). A shared state is stored in a OCI storage bucket, please make sure to use that. Usually, this code shouldn't be executed directly but run by Prow.

## Required Environment Variables

The following environment variables are required before running any `make` targets:

- `AWS_ACCESS_KEY_ID`: Needs to be the key ID for a [Customer Secret Key](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2) to access OCI's S3-compatible storage buckets.
- `AWS_SECRET_ACCESS_KEY`: Needs to be the secret for a [Customer Secret Key](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcredentials.htm#Working2) to access OCI's S3-compatible storage buckets.
- `AWS_ENDPOINT_URL_S3`: Needs to be `https://<object namespace>.compat.objectstorage.us-sanjose-1.oraclecloud.com`. Replace `<object namespace>` with the namespace displayed on the bucket (see OCI Console for this information).

## Running terraform

Easiest way to run terraform locally is to create a `.env` file with the required environment variables and then run `make` commands. For example:

```bash
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxx
export AWS_ENDPOINT_URL_S3=https://xxxxxxxxxxxx.compat.objectstorage.us-sanjose-1.oraclecloud.com
export TF_LOG=DEBUG
```

Create `terraform.tfvars` file with the following content:

```hcl
oci_tenant_ocid          = "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxx"
oci_compartment_ocid     = "ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxx"
oci_region               = "us-sanjose-1"
node_pool_ssh_public_key = "ssh-rsa "
oci_auth_type            = "SecurityToken"
oci_config_file_profile  = "KCP"
```

Install `oci` cli and run `oci session authenticate` to get the `oci_config_file` and `oci_profile` values.

Then run `make init` and `make plan` to see the changes that will be applied. If everything looks good, run `make apply`.
