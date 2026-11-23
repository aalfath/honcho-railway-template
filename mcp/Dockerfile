# Honcho MCP server (Streamable HTTP), built from the pinned Honcho v3.6.1 source.
# Upstream publishes no MCP image, so we build mcp/ exactly as upstream's mcp/Dockerfile does.
FROM oven/bun:1.4.4@sha256:1d22548f177f4ff38e0c15baa3c2c46c6c2060ba2d1bc573bb4720b407548f1d AS src
ARG HONCHO_COMMIT=70c67624169683b9e265517aec95a51b8077cabc
ARG HONCHO_SHA256=ece5b12d352a7896a69f27ddd5d8135c93bb6d347291acef70795338ebf2d6c5
ADD https://codeload.github.com/plastic-labs/honcho/tar.gz/${HONCHO_COMMIT} /tmp/honcho.tgz
RUN echo "${HONCHO_SHA256}  /tmp/honcho.tgz" | sha256sum -c - \
 && mkdir -p /src && tar -xzf /tmp/honcho.tgz -C /src --strip-components=1 \
 && rm /tmp/honcho.tgz

FROM oven/bun:1.4.4@sha256:1d22548f177f4ff38e0c15baa3c2c46c6c2060ba2d1bc573bb4720b407548f1d
WORKDIR /app
RUN chown bun:bun /app
USER bun
COPY --from=src --chown=bun:bun /src/mcp/package.json /src/mcp/bun.lock /src/mcp/bunfig.toml /src/mcp/tsconfig.json ./
COPY --from=src --chown=bun:bun /src/mcp/instructions.md ./
COPY --from=src --chown=bun:bun /src/mcp/src ./src
RUN bun install --frozen-lockfile --production
ENV PORT=3000 HOST=0.0.0.0
EXPOSE 3000
CMD ["bun", "src/http.ts"]
