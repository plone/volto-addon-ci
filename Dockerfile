FROM node:12-stretch-slim

RUN runDeps="openssl ca-certificates git libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb patch" \
 && apt-get update \
 && apt-get install -y --no-install-recommends $runDeps \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/frontend \
 && chown -R node /opt/frontend

WORKDIR /opt/frontend/
RUN npm install -g yo @plone/generator-volto wait-on

USER node
RUN yo --no-insight @plone/volto my-volto-project --no-interactive

COPY jsconfig docker-entrypoint.sh /
COPY jest-addon.config.js /opt/frontend/my-volto-project/

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["test"]
