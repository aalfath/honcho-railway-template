# Honcho API (official image, pinned by version and digest)
FROM ghcr.io/plastic-labs/honcho:v3.6.1@sha256:2ced1a958f14c128ddb05e68deb549f9281681e44595a7a3c34adebf5b432b16
COPY --chown=app:app env.sh start.sh /app/railway/
EXPOSE 8000
ENTRYPOINT ["/bin/sh", "/app/railway/start.sh"]
