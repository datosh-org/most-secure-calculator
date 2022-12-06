# GitHub Action Documentation

## Release

GitHub does **not** maintain an action to interact with releases. Both related
actions are archived:
+ [actions/upload-release-asset](https://github.com/actions/upload-release-asset)
+ [actions/create-release](https://github.com/actions/create-release)

GitHub links to
[softprops/action-gh-release](https://github.com/softprops/action-gh-release)
for a maintained action to interact with releases.

## Sigstore

Multiple ways of creating signatures & storing artifacts are possible.

[Installation](https://docs.sigstore.dev/cosign/installation)

### Fulcio

Enables using OIDC identities, instead of long-lived key pair with explicit trust.

Currenly not used in this PoC.

### Verification \w public key, signature & artifact

```sh
COSIGN_PASSWORD=change_me cosign generate-key-pair
go build ./cmd/calculator/
COSIGN_PASSWORD=change_me cosign sign-blob --key cosign.key calculator > calculator.sig
# We provide: cosign.pub, calculator.sig, calculator
cosign verify-blob --key cosign.pub --signature calculator.sig calculator
```

### Verification \w public key & artifact

Verify using rekor:

```sh
COSIGN_PASSWORD=change_me cosign generate-key-pair
go build ./cmd/calculator/
COSIGN_PASSWORD=change_me COSIGN_EXPERIMENTAL=1 cosign sign-blob --key cosign.key calculator > calculator.sig
# We provide: cosign.pub, calculator
uuid=$(rekor-cli search --artifact calculator | tail -n 1)
sig=$(rekor-cli get --uuid=$uuid --format=json | jq -r .Body.HashedRekordObj.signature.content)
cosign verify-blob --key cosign.pub --signature <(echo $sig) calculator
```

### Verification \w artifact & `sget`

sget is not yet production ready, not even feature complete for our usecase

sget will be able to [trust identities](https://github.com/sigstore/sget#sget-trust-identity)

```sh
COSIGN_PASSWORD=change_me cosign generate-key-pair
go build ./cmd/calculator/
url=$(cosign upload blob -f calculator ghcr.io/datosh/some-action/calculator:v0.1.0)
COSIGN_PASSWORD=change_me COSIGN_EXPERIMENTAL=1 cosign sign --key cosign.key ghcr.io/datosh/some-action/calculator:v0.1.0
# We provide: artifact link
go install github.com/sigstore/cosign/cmd/sget@latest
sget $url > calculator_downloaded
```
