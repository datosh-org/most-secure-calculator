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
FROM gcr.io/distroless/static@sha256:6e980fa0da240d1b21dbf1c2280319bec05a9667fca40cc2cf4277762dd8690f as release
COPY --chmod=755 --from=build /app/calculator-svc /
ENTRYPOINT [ "/calculator-svc" ]
