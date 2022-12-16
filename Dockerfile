FROM node:16-slim

RUN runDeps="openssl ca-certificates git libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb patch build-essential jq" \
 && apt-get update \
 && apt-get install -y --no-install-recommends $runDeps \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/frontend \
 && chown -R node /opt/frontend

WORKDIR /opt/frontend/
RUN npm install --no-audit --no-fund -g yo @plone/generator-volto wait-on \
 && corepack enable

USER node
RUN yo --no-insight @plone/volto my-volto-project --no-interactive --canary

COPY jsconfig docker-entrypoint.sh /
COPY --chown=node jest-addon.config.js /opt/frontend/my-volto-project/

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["test"]
