default: test

PROJECTNAME=$(shell basename "$(PWD)")
KIND_IMG=kindest/node:v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72
CONTAINER_REPO=ghcr.io/datosh-org/most-secure-calculator

kind-up: kind-dep kind-create kind-deploy-nginx

kind-dep:
	@docker pull ${KIND_IMG}

kind-create:
	@kind create cluster --image=${IMG} --config=kind/kind-config.yml

kind-deploy-nginx:
	@kubectl apply -f kind/nginx.yml
	@sleep 30
	@kubectl -n ingress-nginx delete pods -l app.kubernetes.io/component=controller
	@kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

kind-down:
	@kind delete cluster

build: build-cli build-svc

build-cli:
	@CGO_ENABLED=0 go build \
		-trimpath -buildvcs=false \
		-ldflags "-s -w -buildid=''" \
		-o calculator ./cmd/calculator-cli/

build-svc:
	@KO_DOCKER_REPO=${CONTAINER_REPO} ko build -B ./cmd/calculator-svc/

build-and-sign-svc:
	@KO_DOCKER_REPO=${CONTAINER_REPO} ko build -B ./cmd/calculator-svc/ --image-refs=/tmp/to-be-signed.txt
	@COSIGN_EXPERIMENTAL=1 cosign sign $$(cat /tmp/to-be-signed.txt)
	@rm /tmp/to-be-signed.txt

deploy:
	@KO_DOCKER_REPO=kind.local ko apply -f k8s/deployment.yml

test-ci:
	@go test -v -timeout 60s -count=3 -race ./...

test:
	@go test -v -timeout 60s -race ./...
