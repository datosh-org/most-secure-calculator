# gcr.io/distroless/static includes certificates necessary for TLS.
FROM gcr.io/distroless/static@sha256:0985f124d25d79a432b79e806764a9deb759e5c664be7c0633b9f13c3e12cbc0 as release
COPY --chmod=755 calculator /
ENTRYPOINT [ "/calculator" ]
