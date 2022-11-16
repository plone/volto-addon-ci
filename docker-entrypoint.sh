#!/bin/bash
set -e

if [ -z "$TIMEOUT" ]; then
  TIMEOUT="300000"
fi

if [ -z "$RAZZLE_API_PATH" ]; then
  RAZZLE_API_PATH="http://plone:8080/Plone"
fi

if [ -z "$CYPRESS_API_PATH" ]; then
  CYPRESS_API_PATH="$RAZZLE_API_PATH"
fi

if [ -z "$GIT_URL" ]; then
  GIT_URL="https://github.com"
fi

if [ -z "$GIT_BRANCH" ]; then
  GIT_BRANCH="master"
fi

if [ -z "$GIT_USER" ]; then
  GIT_USER="eea"
fi

if [ -z "$NODE_ENV" ]; then
  NODE_ENV="test"
fi

if [ -z "$GIT_NAME" ]; then
  echo "GIT_NAME is required"
  exit 1
fi

PACKAGE="$GIT_NAME"
if [ ! -z "$NAMESPACE" ]; then
  PACKAGE="$NAMESPACE/$GIT_NAME"
fi

WORKSPACES="--workspace src/addons/$GIT_NAME"
ADDONS="--addon $PACKAGE"

if [ ! -z "$DEPENDENCIES" ]; then
  for dep in $DEPENDENCIES; do
    ADDONS="$ADDONS --addon $dep"
  done
fi

if [ -z "$RAZZLE_JEST_CONFIG" ]; then
  RAZZLE_JEST_CONFIG="jest-addon.config.js"
fi

cd /opt/frontend/my-volto-project
if [ -z "$VOLTO" ]; then
  yo --force --no-insight @plone/volto --canary --no-interactive --skip-install $WORKSPACES $ADDONS
else
  yo --force --no-insight @plone/volto --volto=$VOLTO --no-interactive --skip-install $WORKSPACES $ADDONS
fi

if [ ! -d "/opt/frontend/my-volto-project/src/addons/$GIT_NAME" ]; then
  cd /opt/frontend/my-volto-project/src/addons/
  git clone "$GIT_URL/$GIT_USER/$GIT_NAME"
  cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME
  if [ ! -z "$GIT_CHANGE_ID" ]; then
    GIT_BRANCH=PR-${GIT_CHANGE_ID}
    git fetch origin pull/$GIT_CHANGE_ID/head:$GIT_BRANCH
  fi
  git checkout $GIT_BRANCH
  cd /opt/frontend/my-volto-project/
fi

node /jsconfig $PACKAGE addons/$GIT_NAME/src

if [ -f "/opt/frontend/my-volto-project/src/addons/$GIT_NAME/jest-addon.config.js" ]; then
  cp /opt/frontend/my-volto-project/src/addons/$GIT_NAME/jest-addon.config.js /opt/frontend/my-volto-project/.
fi

if [ -f "/opt/frontend/my-volto-project/src/addons/$GIT_NAME/.project.eslintrc.js" ]; then
  cp /opt/frontend/my-volto-project/src/addons/$GIT_NAME/.project.eslintrc.js /opt/frontend/my-volto-project/.eslintrc.js
fi

resolutions=$(jq ".resolutions" /opt/frontend/my-volto-project/src/addons/$GIT_NAME/package.json)
if [ "$resolutions" != "null" ]; then
  jq ".resolutions = $resolutions" package.json > package.json.res
  mv package.json.res package.json
fi

yarn

if [[ "$1" == "test"* ]]; then
  exec bash -c "set -o pipefail; RAZZLE_JEST_CONFIG=$RAZZLE_JEST_CONFIG CI=true yarn test src/addons/$GIT_NAME/src --watchAll=false --reporters=default --reporters=jest-junit --collectCoverage --coverageReporters lcov cobertura text 2>&1 | tee -a unit_tests_log.txt"
fi

if [[ "$1" == "eslint"* ]]; then
  cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME
  exec ../../../node_modules/eslint/bin/eslint.js --max-warnings=0 'src/**/*.{js,jsx,json}'
fi

if [[ "$1" == "stylelint"* ]]; then
  cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME
  exec ../../../node_modules/stylelint/bin/stylelint.js --allow-empty-input 'src/**/*.{css,less}'
fi

if [[ "$1" == "prettier"* ]]; then
  cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME
  exec ../../../node_modules/.bin/prettier --single-quote --check 'src/**/*.{js,jsx,json,css,less,md}'
fi

if [[ "$1" == "cypress"* ]]; then

  if [ -f /opt/frontend/my-volto-project/src/addons/$GIT_NAME/.coverage.babel.config.js ]; then
    cp /opt/frontend/my-volto-project/src/addons/$GIT_NAME/.coverage.babel.config.js /opt/frontend/my-volto-project/babel.config.js
  fi

  export RAZZLE_API_PATH=$RAZZLE_API_PATH
  export CYPRESS_API_PATH=$CYPRESS_API_PATH
  export NODE_ENV=$NODE_ENV

  yarn start &
  wait-on -t $TIMEOUT http://localhost:3000
  cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME

  # Allow custom cypress params
  if [ -z "$2" ]; then
    exec ../../../node_modules/cypress/bin/cypress run
  else
    exec "../../../node_modules/cypress/bin/$@"
  fi
fi

exec "$@"
