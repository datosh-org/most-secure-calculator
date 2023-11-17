# Most Secure Calculator

This repository demonstrates how security best practices for a Go CLI & backend service
can be implemented using GitHub Actions.

It features:
* Git commit signing using [gitsign](https://github.com/sigstore/gitsign).
* Git commit verification using [chaingurad/enforce](https://github.com/apps/chainguard-enforce).
* SLSA level 3+ provenance generation using [slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator).
* SLSA provenance verification using [slsa-framework/slsa-verifier](https://github.com/slsa-framework/slsa-verifier).

* Unit test execution and test report generation using [jstemmer/go-junit-report](github.com/jstemmer/go-junit-report) and [dorny/test-reporter](https://github.com/dorny/test-reporter)

* The CLI is build using a [Makefile](Makefile) and signed with [sigstore/cosign](https://github.com/sigstore/cosign)
* The service is build using [ko](https://github.com/ko-build/ko) and signed with [sigstore/cosign](https://github.com/sigstore/cosign)

## Gitsign

Download and install [sigstore/gitsign](https://github.com/sigstore/gitsign).

<details>
  <summary>Installation script</summary>

  ```sh
  VERSION=0.8.0
  cd $(mktemp -d)
  curl -LO https://github.com/sigstore/gitsign/releases/download/v${VERSION}/gitsign_${VERSION}_linux_amd64
  curl -LO https://github.com/sigstore/gitsign/releases/download/v${VERSION}/gitsign-credential-cache_${VERSION}_linux_amd64
  sudo install gitsign_${VERSION}_linux_amd64 /usr/local/bin/gitsign
  sudo install gitsign-credential-cache_${VERSION}_linux_amd64 /usr/local/bin/gitsign-credential-cache
  cd -
  ```
</details>

Configure git to sign using `gitsign`.

```sh
git config commit.gpgsign true  # Sign all commits
git config tag.gpgsign true  # Sign all tags
git config gpg.x509.program gitsign  # Use gitsign for signing
git config gpg.format x509  # gitsign expects x509 args
```

Optionally:
```sh
# Static port for OIDC callback. This is helpful when you need to whitelist
# or proxy the callback, e.g., when working with remote dev environments.
git config gitsign.redirecturl http://localhost:39807/auth/callback
# Pre-select GitHub as default OIDC provider.
git config gitsign.connectorid https://github.com/login/oauth
# Force unsigned and empty commit
git commit --allow-empty --no-gpg-sign -m "nothing, unsigned"
```

> [!NOTE]
> Add `--global` to previous `git config` commands, so they apply for all repositories.

Verify & inspect:

```sh
# Using git,
git verify-commit HEAD
# Using gitsign
gitsign verify --certificate-identity=datosh18@gmail.com --certificate-oidc-issuer=https://github.com/login/oauth

git log --pretty=raw
```

<details>
  <summary>Helpful debug commands</summary>

  ```sh
  # Check your git config
  git config --list --show-origin --show-scope
  # Remove a config paramter
  git config --unset gitsign.connectorid
  # Parse git signature
  git cat-file commit HEAD | sed -n '/-BEGIN/, /-END/p' | sed 's/^ //g' | sed 's/gpgsig //g' | sed 's/SIGNED MESSAGE/PKCS7/g' | openssl pkcs7 -print -print_certs -text
  ```
</details>

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
