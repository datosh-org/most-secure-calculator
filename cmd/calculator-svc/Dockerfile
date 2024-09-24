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
FROM gcr.io/distroless/static@sha256:de2d52749444512ec179baca0ebc4e969b9b140be46737548f35be34b206147b as release
COPY --chmod=755 --from=build /app/calculator-svc /
ENTRYPOINT [ "/calculator-svc" ]
