# perf-testing-infra

Public-read OCI Object Storage bucket for perf-test results. State lives in the same `kcp-opentofu-state` OCI bucket as the build cluster, under key `perf-testing-infra/tf.tfstate`.

This module only manages the bucket. Uploaders authenticate with the same Customer Secret Keys used for the OpenTofu state backend (see [../cluster/.env.example](../cluster/.env.example)) — those keys already grant write access to any bucket in the `oci_compartment_ocid` compartment.

## Setup

Auth env vars and OCI session setup are identical to [../cluster](../cluster). Either reuse the parent-level `.env` (`source ../.env`) or copy [../cluster/.env.example](../cluster/.env.example) here.

Create `terraform.tfvars`:

```hcl
oci_tenant_ocid              = "ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxx"
oci_compartment_ocid         = "ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxx"
oci_region                   = "us-sanjose-1"
oci_object_storage_namespace = "xxxxxxxxxxxx"
oci_auth_type                = "SecurityToken"
oci_config_file_profile      = "KCP"
```

Then:

```bash
make init
make plan
make apply
```

## Uploading results

Use the existing state-backend credentials from `.env` directly:

```bash
source ../.env   # or wherever AWS_ACCESS_KEY_ID / SECRET / ENDPOINT_URL_S3 live
aws s3 cp result.json s3://kcp-perf-results/runs/$(date +%s)/result.json
```

`make endpoint` prints the bucket name, namespace, region, and S3 endpoint.

The bucket is configured with `ObjectRead` access, meaning anyone with the object URL can `GET` and list bucket contents. **Do not upload anything sensitive.**

## Sharing access with other uploaders

For sharing with people outside the build-cluster admin circle, do **not** hand out the `.env` credentials — those also grant write access to `kcp-opentofu-state` and could corrupt the build cluster's TF state.

Instead, share the bucket-scoped **Pre-Authenticated Request (PAR)** URL that this module mints. It is write-only, scoped to this one bucket, has no list/read permission on the bucket or any other bucket, and expires on the date in `perf_results_par_expires` (currently 2027-06-03).

Get the URL:

```bash
make share
```

Uploaders use it with plain `curl` — no AWS CLI, no env vars:

```bash
URL='<paste-from-make-share>'
curl -X PUT -T result.json "$URL/runs/$(date +%s)/result.json"
```

The trailing path after `/o/` becomes the object key in the bucket. The bucket's `ObjectRead` access then makes uploaded objects publicly readable at the usual Object Storage URL.

**Rotating the URL** (in case of leak or annual rotation): bump `perf_results_par_expires` in `terraform.tfvars` and re-apply, or just:

```bash
make rotate-share
```

This destroys the existing PAR and mints a new one with the same scope and the configured expiry. Everyone using the old URL will start failing immediately; reissue the new URL via your team's secret-sharing channel.
