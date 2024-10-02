FROM golang:1.23.2 as build

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
FROM gcr.io/distroless/static@sha256:be1b7d7cd6a73c147005df4c81041a5aafb28a7c2e9821fb2c7a878024edc23d as release
COPY --chmod=755 --from=build /app/calculator-svc /
ENTRYPOINT [ "/calculator-svc" ]
