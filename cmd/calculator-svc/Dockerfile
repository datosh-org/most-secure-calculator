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
FROM gcr.io/distroless/static@sha256:d49f214e6f1bae819e24f651156552b073725592cae128a66eade0c6280f02e1 as release
COPY --chmod=755 --from=build /app/calculator-svc /
ENTRYPOINT [ "/calculator-svc" ]
