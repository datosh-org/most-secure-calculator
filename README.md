# Most Secure Calculator

This repository demonstrates how security best practices for a [Go](https://go.dev/)
CLI application & backend service can be implemented on GitHub using GitHub Actions.

It features security best practices such as:
* Git commit signing ([gitsign](https://github.com/sigstore/gitsign)) and verification ([chaingurad/enforce](https://github.com/apps/chainguard-enforce)).
* Integrity protected SBOM generation ([anchore/syft](https://github.com/anchore/syft)) and vulnerability scanning ([anchore/grype](https://github.com/anchore/grype)) with a verified SBOM.
* SLSA provenance generation ([slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)) and verification ([slsa-framework/slsa-verifier](https://github.com/slsa-framework/slsa-verifier)).

This will protect us from different [threats in our software supply chain](https://slsa.dev/spec/v1.0/threats-overview).

![](https://slsa.dev/spec/v1.0/images/supply-chain-threats.svg)

## Git commit signing & verification

[GitHub uses your commit email address to associate commits with your account on GitHub.com](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address), but it does not validate that you own the email address when you push changes. Therefore it is trivial to impersonate another user on GitHub. We simply commit using their email address.

### Find the commit author's email

As with any cyber security attack, the first stage is [reconnaissance](https://en.wikipedia.org/wiki/Reconnaissance), i.e., information gathering.

1. Find GitHub user ([@kelseyhightower](https://github.com/kelseyhightower))
1. Open [recent activity](https://github.com/kelseyhightower/run/commits?author=kelseyhightower&since=2022-11-30&until=2022-12-31)
1. Open a [commit](https://github.com/kelseyhightower/run/commit/84c18c9e94db53f29ea2ec5379558d7e719193bd)
1. Add [.patch to URL](https://github.com/kelseyhightower/run/commit/84c18c9e94db53f29ea2ec5379558d7e719193bd.patch)

The second line will read: `From: username <email>`.

> [!NOTE]
> GitHub allows you to protect your privacy using [a `noreply` address from GitHub](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address) and automatically [block pushing with your personal email address](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/blocking-command-line-pushes-that-expose-your-personal-email-address).

### Commit in some else's name

> [!WARNING]
> All excercises are intended for educational purposes only. Users are strictly advised not to employ the acquired knowledge for any malicious activities or unauthorized access.

```sh
# Set username and email
git config user.name "Kelsey Hightower"
git config user.email "kelsey.hightower@gmail.com"
# Commit as Kelsey
git commit --allow-empty --no-gpg-sign -m "awesome change"
git push origin HEAD
```

<details>
  <summary>Revert config & push.</summary>

  ```sh
  # Use global config values
  git config --unset user.name
  git config --unset user.email
  # Revert commit locally and remote
  git reset --hard HEAD~1
  git push origin HEAD --force-with-lease
  ```

</details>

### Signing to the rescure

To mitigate the risk that someone impersonates other users on GitHub, we should sign and verify commits to our repositories, i.e., cryptographically bind the content of the commit to the signer's identity.

git commit signing is supported, since [git v1.7.9 (January 2012)](https://github.com/git/git/blob/master/Documentation/RelNotes/1.7.9.txt#L56-L57), and is based on GPG keys.

<details>
  <summary>GPG based commit signing (example).</summary>
  GitHub provides great documentation on how to sign your commits with GPG.

  1. [Generate your key](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key)
      ```sh
      gpg --full-generate-key
      ```
  2. [Add public key to your profile](https://docs.github.com/en/authentication/managing-commit-signature-verification/adding-a-gpg-key-to-your-github-account)
      ```sh
      # List keys
      gpg --list-secret-keys --keyid-format=long
      # Export public key
      gpg --armor --export 3AA5C34371567BD2
      ```
  3. [Configure git](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key)
      ```sh
      # Enable commit signing
      git config --global commit.gpgsign true
      # Configure key
      git config --global user.signingkey 3AA5C34371567BD2
      ```
  4. Sign and push
      ```sh
      # Our settings will automatically sign, otherwise use -S
      git commit -m "awesome change"
      git push
      ```
  5. Verification
      ```sh
      git verify-commit HEAD
      ```

  Read more about [git commit signature verification support on GitHub](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification).
</details>

### Key management and revocation

So why isn't everyone signing their git commits using GPG?

GPG based keys come with a set of trade-offs. They do provide a very high level
of security (given that no other service providers need to be trusted),
if all users have secure processes in place to answer the following questions:

* How do I securely store my master-key and sub-keys?
* How do I make the right keys available on all my machines?
* How do I renew my keys when they expire?
* How do I revoke my key when it leaks?
* Which keys do I trust?

### Sigstore

We can improve the UX significantly by placing some trust in an identity provider, which we (probably) do already.

[Sigstore](https://www.sigstore.dev/) enables us to:
1. Generate a key and short-lived certificate that is bound to an [OpenID Connect](https://openid.net/developers/how-connect-works/) identity.
1. Generate proof that we own this key at a specific point in time.
1. Store the proof in an immutable transparency log for later verification.

![](https://www.sigstore.dev/img/alt_landscapelayout_overview.svg)

For a deep dive watch [Life of a Sigstore Signature - Jed Salazar & Zack Newman, Chainguard](https://www.youtube.com/watch?v=DrHrkSsozB0), from [SigstoreCon 2022](https://events.linuxfoundation.org/sigstorecon-north-america/).

### gitsign

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

Optional:
```sh
# Static port for OIDC callback. This is helpful when you need to whitelist
# or proxy the callback, e.g., when working with remote dev environments.
git config gitsign.redirecturl http://localhost:39807/auth/callback
# Pre-select GitHub as default OIDC provider.
git config gitsign.connectorid https://github.com/login/oauth
```

> [!NOTE]
> Add `--global` to previous `git config` commands, so they apply for all repositories.

Verify & inspect:

```sh
# Using git (partial verification)
git verify-commit HEAD
# Using gitsign
gitsign verify \
  --certificate-identity=datosh18@gmail.com \
  --certificate-oidc-issuer=https://github.com/login/oauth
# Show actual signature value
git log --pretty=raw
# Show (partial) signature validation
git log --show-signature
```

<details>
  <summary>Helpful debug commands</summary>

  ```sh
  # Check your git config
  git config --list --show-origin --show-scope
  # Remove a config paramter
  git config --unset gitsign.connectorid
  # Create unsigned, empty commit
  git commit --allow-empty --no-gpg-sign -m "nothing, unsigned"
  # Parse git signature
  git cat-file commit HEAD | sed -n '/-BEGIN/, /-END/p' | sed 's/^ //g' | sed 's/gpgsig //g' | sed 's/SIGNED MESSAGE/PKCS7/g' | openssl pkcs7 -print -print_certs -text
  ```
</details>

> [!NOTE]
> [GitHub does not recognize gitsign signatures as verified at the moment](https://github.com/sigstore/gitsign#why-doesnt-github-show-commits-as-verified).

<details>
  <summary>Configure gitsign credential cache</summary>

  When doing multiple git commits in a short period of time, it might become
  annoying to do the OIDC dance for every commit.

  The gitsign credential cache binary enables users to re-use the key during
  its 10 minutes lifetime.

  Check the [official documentation](https://github.com/sigstore/gitsign/blob/main/cmd/gitsign-credential-cache/README.md)
  as the configuration is highly platform dependent.

  ```sh
  gitsign-credential-cache &
  export GITSIGN_CREDENTIAL_CACHE="$HOME/.cache/sigstore/gitsign/cache.sock"
  ```

  > [!WARNING]
  > Users should consider that caching the key [introduces a security risk](https://github.com/sigstore/gitsign/blob/main/cmd/gitsign-credential-cache/README.md), as
  > the key is exposed via unix sockets.

</details>

### chainguard-enforce

[chainguard-enforce](https://github.com/marketplace/chainguard-enforce) allows us to set policies for which identities can/must sign your code.

```yaml
spec:
  authorities:
    - keyless:
        identities:
          - issuer: https://github.com/login/oauth
            subject: datosh18@gmail.com
    - key:
        kms: https://github.com/web-flow.gpg
    - key:
        kms: https://github.com/renovate-bot.gpg

```

Additional we can [configure](https://github.com/datosh-org/most-secure-calculator/settings/branch_protection_rules/31734554) a merge-blocking check to prevent any unsigned commits making it to `main`.

### Outlook: gittuf

[gittuf/gittuf](https://github.com/gittuf/gittuf) provides a security layer for Git.

Among other features it allows you to set permissions for repository branches, tags, files, etc. This is much more powerful than git (signature) verification policies supported by the other projects we looked at.

At the same time, [gittuf v0.1.0 was release in October 2023](https://github.com/gittuf/gittuf/releases/tag/v0.1.0), is currently in alpha and therefore NOT intended for production use.

## Build the service

The [Dockerfile](cmd/calculator-svc/Dockerfile) for the backend service uses a multi-stage build to:
1. containerize the build stage
2. keep the final production image as small as possible

```sh
make build-svc-oci
```

Alternatively, we can also build the service using a local Go toolchain:

```sh
make build-svc
```

### Sign container image

To protect the container image from malicious tampering, we want to sign it:

```sh
# Note that this process stored public information in the transparency log.
cosign sign calculator-svc
# Verify locally signed image
cosign verify \
  --certificate-identity datosh18@gmail.com \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  calculator-svc

# Verify images signed by the pipeline
cosign verify \
  --certificate-identity-regexp https://github.com/datosh-org/most-secure-calculator/.github/workflows/calculator-svc.yml.* \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/datosh-org/most-secure-calculator/calculator-svc@sha256:b2d2de552850cc7f99ebf0d0071357306159242ccf720b5b001ab694220f9547
```

> [!WARNING]
> Depending on how the image was build and pushed, there are still risks to
> consider, as you might only know the digest of the image, **after** it was
> pushed to the registry. [sigstore/cosign#2516](https://github.com/sigstore/cosign/issues/2516)

### Sigstore Kubernetes Policy Controller

K8s deployments will regularly require to pull images from the registry and
make them available on the node. As this is an automatic process, the
verification should also happen automatically. For this, we can use projects
such as [Sigstore Kubernetes Policy Controller](https://docs.sigstore.dev/policy-controller/overview/).

<details>
  <summary>Local Kubernetes in Docker (kind) cluster</summary>

  The Sigstore Kubernetes policy controller works with any K8s derivate.
  To test it on a local developer machine projects such as
  [minikube](https://minikube.sigs.k8s.io/docs/start/),
  [microk8s](https://microk8s.io/) or
  [kind](https://github.com/kubernetes-sigs/kind)
  work great. Here we show how to stand up a local K8s cluster with kind:

  ```sh
  KIND_VERSION=0.20.0
  cd $(mktemp -d)
  curl -LO https://github.com/kubernetes-sigs/kind/releases/download/v{KIND_VERSION}/kind-linux-amd64
  sudo install kind-linux-amd64 /usr/local/bin/kind
  rm kind-linux-amd64
  cd -
  ```

  We use a simple single-node [kind configuration](kind/kind-config.yml) and
  additionally deploy [nginx as a loadblancer](kind/nginx.yml).

  ```sh
  make kind-up
  ```
</details>

Install calculator service with no verification:

```sh
kubectl apply -f k8s/deployment.yml
curl localhost:80/calculator/add/2/3
```
Install the Sigstore Kubernetes Policy Controller:

```sh
helm repo add sigstore https://sigstore.github.io/helm-charts
helm repo update
kubectl create namespace cosign-system
helm install policy-controller -n cosign-system sigstore/policy-controller --devel
kubectl get all -n cosign-system
```

Create a namespace, enforce the policy and deploy:

```sh
kubectl create namespace secured
# https://docs.sigstore.dev/policy-controller/overview/#configure-policy-controller-admission-controller-for-namespaces
kubectl label namespace secured policy.sigstore.dev/include=true
kubectl apply -f k8s/policy.yml
kubectl apply -f k8s/secure-deployment.yml
curl localhost:80/secure-calculator/add/2/3
```

### Vulnerability Management

Software Bill of Materials (SBOMs) are becoming the standard tool
to keep track of all ingredients in your artifacts.

### Generate an SBOM

[Syft](https://github.com/anchore/syft) is an open source tool to generate
a Software Bill of Materials (SBOM) from container images and filesystems.

<details>
  <summary>Installation script</summary>

  ```sh
  # https://github.com/anchore/syft/releases
  SYFT_VERSION=0.98.0
  cd $(mktemp -d)
  curl -LO https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz
  tar -xzf syft_${SYFT_VERSION}_linux_amd64.tar.gz
  sudo install syft /usr/local/bin
  rm syft_${SYFT_VERSION}_linux_amd64.tar.gz
  cd -
  syft version
  ```
</details>

We can easily generate an SBOM for any container images:

```sh
# table to stdout
syft httpd:2.4.58
# spdx format: https://spdx.dev/
syft httpd:2.4.58 -o spdx-json=spdx.json
# cyclonedx format: https://cyclonedx.org/
syft httpd:2.4.58 -o cyclonedx-json=cyclone.json
```

Generating a list of these ingredients as a distinct build artifact allows us
to keep the responsibilities of vulnerability management and application
deployment seperate.

### Grype

[Grype](https://github.com/anchore/grype) is an open source vulnerability
scanner that can directly work on SBOMs.

<details>
  <summary>Installation script</summary>

  ```sh
  # https://github.com/anchore/grype/releases
  GRYPE_VERSION=0.73.3
  cd $(mktemp -d)
  curl -LO https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz
  tar -xzf grype_${GRYPE_VERSION}_linux_amd64.tar.gz
  sudo install grype /usr/local/bin
  rm grype_${GRYPE_VERSION}_linux_amd64.tar.gz
  cd -
  grype version
  ```
</details>

We use the SBOM generated in the previous step to scan for known vulnerabilities:

```sh
grype spdx.json
# exit code is 0, even though we have findings.
echo $?
# fail, if there are findings >= threshold.
grype spdx.json --fail-on critical
echo $?
# ignore things without a fix.
grype spdx.json --fail-on critical --only-fixed
```

Grype also offers the option to persist a configuration directly in the repository:

```yaml
external-sources:
  enable: true
  maven:
    search-upstream-by-sha1: true
    base-url: https://search.maven.org/solrsearch/select
```

This can also help you to track the state of vulnerabilities directly with your source code:

```yaml
ignore:
  # This is the full set of supported rule fields:
  - vulnerability: CVE-2008-4318
    fix-state: unknown
    # VEX fields apply when Grype reads vex data:
    vex-status: not_affected
    vex-justification: vulnerable_code_not_present
    package:
      name: libcurl
      version: 1.5.1
      type: npm
      location: "/usr/local/lib/node_modules/**"

  # We can make rules to match just by vulnerability ID:
  - vulnerability: CVE-2014-54321
```

### Integrity & Discoverability

As with our applications, we also want to protect our SBOMs from manipulations.

Attackers could:
* remove entries, to prevent us from patching vulnerabilities
* add entries, to harm the reputation of a project

Therefore, we use the same concepts to also sign our SBOM:

> [!WARNING]
> Make sure to install syft>=v0.98.0, as `syft attest`
> [was broken before](https://github.com/anchore/syft/issues/2333).

```sh
syft attest --output spdx-json \
  ghcr.io/datosh-org/most-secure-calculator/calculator-svc:please-sign-me
```

This attestation statement and SBOM is stored in the same OCI registry as our
container image, and makes discoverability straight forward:

```sh
cosign verify-attestation \
  ghcr.io/datosh-org/most-secure-calculator/calculator-svc:please-sign-me \
  --certificate-identity=datosh18@gmail.com \
  --certificate-oidc-issuer=https://github.com/login/oauth \
  --type=spdxjson > spdx.json

# make sure there is only a single attestation associated.
wc -l spdx.json

# Extract SBOM from attestation
cat spdx.json | jq -r '.payload | @base64d | fromjson | .predicate' | grype
```

### Outlook: Vulnerability Exploitability eXchange (VEX)

TODO: Write a few lines about the problems VEX is solving.

[VEX](https://cyclonedx.org/capabilities/vex/)

## Build CLI

OCI compatibel artifacts can be distributed via a breadth of registries.
On the other hand, CLI binaries are usually distributed via GitHub release
pages.

### Provenance

Provenance is [the verifiable information about software artifacts describing where, when and how something was produced](https://slsa.dev/spec/v1.0/provenance). It records information such as:
* a reference to the input source code
* information about the build environment
* output of the build, which can include files distinct from the actual binary

![](https://slsa.dev/spec/v1.0/images/provenance-model.svg)

In contrast, classical software signatures only prove that the distributed
artifact and the cryptographic private key have been at the same place at the
same time.

### SLSA-GitHub-Generator

[SLSA-GitHub-Generator](https://github.com/slsa-framework/slsa-github-generator) is a project that [contains free tools to generate and verify SLSA Build Level 3 provenance for native GitHub projects using GitHub Actions](https://github.com/slsa-framework/slsa-github-generator#overview).

Furthermore, [it can help you achieve SLSA Build level 3, use of the provided GitHub Actions reusable workflows alone is not sufficient to meet all of the requirements at SLSA Build level 3. Specifically, these workflows do not address provenance distribution or verification.](https://github.com/slsa-framework/slsa-github-generator#what-is-slsa-github-generator)

For the pipeline implementation refer to [workflows/calculator-svc.yml](.github/workflows/calculator-svc.yml).

### SLSA-Verifier

Once a release was generated we can use [SLSA-Verifier](https://github.com/slsa-framework/slsa-verifier) to verify both the cryptographic signature, as well as contents of the provenance document, before consuming the binary.

```sh
curl -LO https://github.com/datosh-org/most-secure-calculator/releases/download/v0.1.0/calculator
curl -LO https://github.com/datosh-org/most-secure-calculator/releases/download/v0.1.0/calculator.sbom
curl -LO https://github.com/datosh-org/most-secure-calculator/releases/download/v0.1.0/calculator.intoto.jsonl

slsa-verifier verify-artifact calculator \
  --provenance-path calculator.intoto.jsonl \
  --source-uri github.com/datosh-org/most-secure-calculator \
  --source-tag v0.1.0
slsa-verifier verify-artifact calculator.sbom \
  --provenance-path calculator.intoto.jsonl \
  --source-uri github.com/datosh-org/most-secure-calculator \
  --source-tag v0.1.0

grype calculator.sbom
./calculator 2 3
```

## Related Projects

### FRSCA

[Factory for Repeatable Secure Creation of Artifacts](https://buildsec.github.io/frsca/).

### Trusty & Minder

[Announcing Minder and Trusty: Free-to-use tools to help developers and open source communities build safer software](https://stacklok.com/blog/announcing-trusty-and-minder-free-to-use-tools-to-help-developers-and-open-source-communities-build-safer-software)
