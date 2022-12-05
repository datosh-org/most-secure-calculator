# Most Secure Calculator

Scan:

```sh
IMG=$(make build-svc)
cosign download sbom $IMG | grype --add-cpes-if-none --fail-on high
```
