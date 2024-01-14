FROM golang:1.21.4 as build

WORKDIR /app

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build \
    -trimpath -buildvcs=false \
    -ldflags "-s -w -buildid=''" \
    -o calculator-svc ./cmd/calculator-svc/

# gcr.io/distroless/static includes certificates necessary for TLS.
FROM gcr.io/distroless/static@sha256:30c679764948df7b86cfb4a09f8f5baf6243849fe96cd97ea700f8319803e941 as release
COPY --chmod=755 --from=build /app/calculator-svc /
ENTRYPOINT [ "/calculator-svc" ]
