# gcr.io/distroless/static includes certificates necessary for TLS.
FROM gcr.io/distroless/static@sha256:d49f214e6f1bae819e24f651156552b073725592cae128a66eade0c6280f02e1 as release
COPY --chmod=755 calculator /
ENTRYPOINT [ "/calculator" ]
