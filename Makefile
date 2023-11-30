default: test build

PROJECTNAME=$(shell basename "$(PWD)")
KIND_IMG=kindest/node:v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72
CONTAINER_REPO=ghcr.io/datosh-org/most-secure-calculator


build: build-cli build-svc

build-oci: build-cli-oci build-svc-oci

build-cli:
	@CGO_ENABLED=0 go build \
		-trimpath -buildvcs=false \
		-ldflags "-s -w -buildid=''" \
		-o calculator ./cmd/calculator-cli/

build-cli-oci:
	@docker build -t calculator-cli \
		-f ./cmd/calculator-cli/Dockerfile \
		.

build-svc:
	@CGO_ENABLED=0 go build \
		-trimpath -buildvcs=false \
		-ldflags "-s -w -buildid=''" \
		-o calculator-service ./cmd/calculator-svc/

build-svc-oci:
	@docker build -t calculator-svc \
		-f ./cmd/calculator-svc/Dockerfile \
		.

test:
	@go test -v -timeout 60s -race ./...


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
