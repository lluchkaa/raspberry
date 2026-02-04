FROM node:krypton-slim

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm add -g openclaw

RUN useradd -m -s /bin/bash node || true
USER node
WORKDIR /home/node

RUN mkdir -p /home/node/.openclaw

EXPOSE 18789 18790

ENTRYPOINT ["openclaw"]
CMD ["gateway"]
