# gcr.io/distroless/static includes certificates necessary for TLS.
FROM gcr.io/distroless/static@sha256:30c679764948df7b86cfb4a09f8f5baf6243849fe96cd97ea700f8319803e941 as release
COPY --chmod=755 calculator /
ENTRYPOINT [ "/calculator" ]
