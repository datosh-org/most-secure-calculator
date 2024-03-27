# gcr.io/distroless/static includes certificates necessary for TLS.
FROM gcr.io/distroless/static@sha256:6e980fa0da240d1b21dbf1c2280319bec05a9667fca40cc2cf4277762dd8690f as release
COPY --chmod=755 calculator /
ENTRYPOINT [ "/calculator" ]
