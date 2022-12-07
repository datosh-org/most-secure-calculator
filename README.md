# Most Secure Calculator

This repository demonstrates how security best practices for a Go repository
can be implemented using GitHub Actions.

It features:
* Git commit signing using [gitsign](https://github.com/sigstore/gitsign).
* Git commit verification using [chaingurad/enforce](https://github.com/apps/chainguard-enforce).
* SLSA provenance generation using [slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator).
* SLSA provenance verification using [slsa-framework/slsa-verifier](https://github.com/slsa-framework/slsa-verifier).

* Unit test execution and test report generation using [jstemmer/go-junit-report](github.com/jstemmer/go-junit-report) and [dorny/test-reporter](https://github.com/dorny/test-reporter)

* The CLI is build using a [Makefile](Makefile) and signed with [sigstore/cosign](https://github.com/sigstore/cosign)
* The service is build using [ko](https://github.com/ko-build/ko) and signed with [sigstore/cosign](https://github.com/sigstore/cosign)

## Gitsign

Scan:

```sh
IMG=$(make build-svc)
cosign download sbom $IMG | grype --add-cpes-if-none --fail-on high
```

Inspect git signing

```sh
git log --pretty=raw
```
