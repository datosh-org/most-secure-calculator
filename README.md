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

Download and install [sigstore/gitsign](https://github.com/sigstore/gitsign).

Configure git to sign using `gitsign`.

```sh
git config --global commit.gpgsign true  # Sign all commits
git config --global tag.gpgsign true  # Sign all tags
git config --global gpg.x509.program gitsign  # Use gitsign for signing
git config --global gpg.format x509  # gitsign expects x509 args
```

Optionally:
```sh
# Static port for OIDC callback
git config --global gitsign.redirecturl=http://localhost:39807/auth/callback
# Pre-select GitHub as OIDC provider
git config --global gitsign.connectorid=https://github.com/login/oauth
```

Verify & inspect:

```sh
git verify-commit HEAD
git log --pretty=raw
```

## Ko & KinD

We use [ko](https://ko.build/install/) and [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/) for a local development environment. Follow their quick start and installation guides for your system.

Afterwards use the [Makefile](Makefile) to spin up a KinD cluster, build and deploy our service, and consume its API:

```sh
make kind-up
make deploy
curl localhost/calculator/add/2/33
```

## Grype

Download and install [sigstore/cosign](https://github.com/sigstore/cosign) and [anchore/grype](https://github.com/anchore/grype).

When we build our Go service with `ko` multiple things happen:
* A container image is produced and uploaded to `ghcr.io`
* An SBOM is produced and uploaded to `ghcr.io`
* The SHA reference to our container image is returned

We can then use cosign to download the SBOM and check it for vulnerabilities:

```sh
IMG=$(make build-svc)
cosign download sbom $IMG | grype --add-cpes-if-none --fail-on high
```
