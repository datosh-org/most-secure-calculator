# Most Secure Calculator

This repository demonstrates how security best practices for a [Go](https://go.dev/)
CLI & backend service can be implemented on GitHub using GitHub Actions.

It features security best practices such as:
* Git commit signing ([gitsign](https://github.com/sigstore/gitsign)) and verification ([chaingurad/enforce](https://github.com/apps/chainguard-enforce)).
* SBOM generation ([anchore/syft](https://github.com/anchore/syft)) and vulnerability scanning ([anchore/grype](https://github.com/anchore/grype))
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

So why isn't everyone signing using GPG?

GPG based keys come with a set of trade-offs. They do provide a very high level of security,
if all users have secure processes in place to answer the following questions:

* How do I store my master-key and sub-keys?
* How do I make it available on all my machines?
* How do I renew my key when it expires?
* How do I revoke my key when it leaks?
* Which keys do I trust?

### Sigstore

We can improve the UX significantly by placing some trust in an identity provider, which we (probably) do already.

[Sigstore](https://www.sigstore.dev/) enables us to:
1. Generate a key and short lived certificate that is bound to an [OpenID Connect](https://openid.net/developers/how-connect-works/) identity.
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
gitsign verify --certificate-identity=datosh18@gmail.com --certificate-oidc-issuer=https://github.com/login/oauth
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
> [GitHub does not recognize gitsign signatures as verified at the moment](https://github.com/sigstore/gitsign#why-doesnt-github-show-commits-as-verified)

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

### gittuf

[gittuf/gittuf](https://github.com/gittuf/gittuf) provides a security layer for Git.

Among other features it allows you to set permissions for repository branches, tags, files, etc. This is much more powerful than git (signature) verification policies supported by the other projects we looked at.

At the same time, [gittuf v0.1.0 was release in October 2023](https://github.com/gittuf/gittuf/releases/tag/v0.1.0), is currently in alpha and therefore NOT intended for production use.

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

## Sigstore Policy Controller

```sh
helm repo add sigstore https://sigstore.github.io/helm-charts
helm repo update
kubectl create namespace cosign-system
helm install policy-controller -n cosign-system sigstore/policy-controller --devel
kubectl get all -n cosign-system
# Create namespace ...
kubectl create namespace secured
# ... and enforce signature policy
# https://docs.sigstore.dev/policy-controller/overview/#configure-policy-controller-admission-controller-for-namespaces
kubectl label namespace secured policy.sigstore.dev/include=true
kubectl apply -f k8s/policy.yml
# Appply deployment
kubectl apply -f k8s/secure-deployment.yml

curl localhost:80/secure-calculator/add/2/3
```
