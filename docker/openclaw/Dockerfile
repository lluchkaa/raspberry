FROM node:krypton-slim

RUN apt-get update && apt-get install -y \
      git curl gnupg \
    && curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
       https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
       > /etc/apt/sources.list.d/brave-browser-release.list \
    && apt-get update && apt-get install -y --no-install-recommends brave-browser \
    && rm -rf /var/lib/apt/lists/*

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
