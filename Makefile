default: test

PROJECTNAME=$(shell basename "$(PWD)")
MAKEFLAGS += --silent
KIND_IMG=kindest/node:v1.25.3@sha256:f52781bc0d7a19fb6c405c2af83abfeb311f130707a0e219175677e366cc45d1
CONTAINER_REPO=ghcr.io/datosh-org/most-secure-calculator

kind-up: kind-dep kind-create kind-deploy-nginx

kind-dep:
	@docker pull ${KIND_IMG}

kind-create:
	@kind create cluster --image=${IMG} --config=kind/kind-config.yml

kind-deploy-nginx:
	@kubectl apply -f kind/nginx.yml
	@kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

kind-down:
	@kind delete cluster

build: build-cli build-svc

build-cli:
	@CGO_ENABLED=0 go build -o calculator -buildvcs=false -ldflags "-buildid=''" ./cmd/calculator-cli/

build-svc:
	@KO_DOCKER_REPO=${CONTAINER_REPO}/calculator-svc ko build ./cmd/calculator-svc/ --image-refs=to-be-signed.txt
	@COSIGN_EXPERIMENTAL=1 cosign sign $$(cat to-be-signed.txt)
	@rm to-be-signed.txt

deploy:
	@KO_DOCKER_REPO=kind.local ko apply -f k8s/deployment.yml

test:
	@go test -v -timeout 60s -race ./...
