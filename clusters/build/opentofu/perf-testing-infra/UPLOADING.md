# Uploading perf-test results

You've been given an upload URL that looks like:

```
https://axtwf1hkrwcy.objectstorage.us-sanjose-1.oci.customer-oci.com/p/<token>/n/axtwf1hkrwcy/b/kcp-perf-results/o/
```

That URL is write-only to the `kcp-perf-results` bucket. **Treat it like a password** — anyone who has it can upload. Don't paste it in public Slack channels, PRs, or issue trackers. Share via 1Password / Bitwarden / equivalent. The URL expires on **2027-06-03**; ask the kcp infra team for a fresh one before then.

## Uploading a file

Save the URL once:

```bash
export PERF_UPLOAD_URL='https://axtwf1hkrwcy.objectstorage.us-sanjose-1.oci.customer-oci.com/p/<token>/n/axtwf1hkrwcy/b/kcp-perf-results/o/'
```

Upload with plain `curl`. Whatever path you append after `/o/` becomes the object key:

```bash
# uploads to: runs/2026-06-03/my-test/result.json
curl -X PUT -T result.json \
  "${PERF_UPLOAD_URL}runs/2026-06-03/my-test/result.json"
```

A sensible convention is `runs/<date>/<scenario>/<file>`:

```bash
RUN="runs/$(date +%F)/$(hostname)"
curl -X PUT -T summary.csv  "${PERF_UPLOAD_URL}${RUN}/summary.csv"
curl -X PUT -T metrics.json "${PERF_UPLOAD_URL}${RUN}/metrics.json"
curl -X PUT -T logs.tgz     "${PERF_UPLOAD_URL}${RUN}/logs.tgz"
```

No `mkdir` step — slashes in the key are enough; OCI shows the result as nested folders. Use only `[a-zA-Z0-9/_.-]` in paths to avoid URL-encoding pain.

## Verifying / sharing uploaded files

The bucket is **public-read**. Once uploaded, the file is at:

```
https://axtwf1hkrwcy.objectstorage.us-sanjose-1.oci.customer-oci.com/n/axtwf1hkrwcy/b/kcp-perf-results/o/<your/path/to/file>
```

(note: no `/p/<token>` segment — that part is only for writes)

Example:

```bash
RUN="runs/$(date +%F)/$(hostname)"
echo "https://axtwf1hkrwcy.objectstorage.us-sanjose-1.oci.customer-oci.com/n/axtwf1hkrwcy/b/kcp-perf-results/o/${RUN}/summary.csv"
```

You can hand that read URL out in PRs, dashboards, etc.

## What you cannot do with the upload URL

- Read or list existing objects (use the public-read URL above instead).
- Delete or overwrite objects with a different key (a `PUT` to the same key *will* overwrite — pick unique keys, e.g. include a timestamp).
- Touch any bucket other than `kcp-perf-results`.

## Don't upload anything sensitive

Anything you upload is world-readable. No credentials, no customer data, no internal-only logs.
