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
yo --force --no-insight @plone/volto --volto=$VOLTO --no-interactive --skip-install $WORKSPACES $ADDONS

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

yarn

if [[ "$1" == "test"* ]]; then
  yarn add -W --dev jest-junit jest-transform-stub
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
    grep -Rl coverage-start /opt/frontend/my-volto-project/src/addons/$GIT_NAME/cypress/* |  xargs sed -i '/\/\*[ ]*coverage-start/d'
    grep -Rl coverage-end /opt/frontend/my-volto-project/src/addons/$GIT_NAME/cypress/* |  xargs sed -i '/coverage-end[ ]*\*\//d'
  fi
  
  RAZZLE_API_PATH=$RAZZLE_API_PATH yarn start &

  cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME
  exec bash -c "wait-on -t $TIMEOUT http://localhost:3000 && CYPRESS_API_PATH=$CYPRESS_API_PATH ../../../node_modules/cypress/bin/cypress run"
fi

exec "$@"
