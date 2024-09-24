# gcr.io/distroless/static includes certificates necessary for TLS.
FROM gcr.io/distroless/static@sha256:de2d52749444512ec179baca0ebc4e969b9b140be46737548f35be34b206147b as release
COPY --chmod=755 calculator /
ENTRYPOINT [ "/calculator" ]
