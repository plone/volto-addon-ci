# Testing Volto Add-ons Docker Image

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/plone/volto-addon-ci)

Docker Image optimized for running tests over Volto Add-ons

## Supported tags and respective Dockerfile links

- [Tags](https://hub.docker.com/r/plone/volto-addon-ci/tags/)

## Base docker image

- [hub.docker.com](https://hub.docker.com/r/plone/volto-addon-ci/)

## Source code

- [github.com](http://github.com/plone/volto-addon-ci)

## Simple Usage

    $ docker run -it --rm \
                 -e GIT_NAME=volto-group-block \
                 -e GIT_BRANCH=develop \
                 -e NAMESPACE=@eeacms \
                 -e DEPENDENCIES="@eeacms/volto-blocks-form" \
             plone/volto-addon-ci eslint

## Advanced Usage

    $ docker run -it --rm \
                 -e GIT_NAME=volto-group-block \
                 -e GIT_CHANGE_ID=50 \
                 -e GIT_BRANCH=PR-50 \
                 -e NAMESPACE=@eeacms \
                 -e DEPENDENCIES="@eeacms/volto-blocks-form" \
             plone/volto-addon-ci eslint

## Local usage

    $ cd src/addons/volto-slate

    $ docker run -it --rm \
                 -v $(pwd):/opt/frontend/my-volto-project/src/addons/volto-slate \
                 -e GIT_NAME=volto-slate \
             plone/volto-addon-ci

## Resolutions

Volto add-ons may depend on other JS libraries and/or other Volto add-ons. In order to
enforce specific versions, you can use [selective dependency resolutions](https://classic.yarnpkg.com/lang/en/docs/selective-version-resolutions/) within your add-on.

### Troubleshooting

1. Make sure your Volto project `yarn.lock` is not polluted. You can always reset your Volto project `yarn.lock` with:

        $ cd my-volto-project
        $ rm yarn.lock
        $ yo @plone/volto --skip-install
        $ yarn

2. Add-on `resolutions` don't work with `workspaces` (development mode), thus you'll need to define `resolutions` within Volto project. To tackle this issue, this Docker image automatically extracts `resolutions` from add-on and add them also to the Volto project before running tests.

3. [See also](https://medium.com/swlh/welcome-to-dependency-hell-754a896f0440)

## Supported environment variables

- `VOLTO` Volto version that the project will use. Default: Latest released version is used.
- `TIMEOUT` Timeout in ms (e.g.: `TIMEOUT=60000`). Default: `120000`
- `GIT_NAME` Git repo name (e.g.: `GIT_NAME=volto-group-block`). Required
- `GIT_URL` Git repo root url (e.g.: `GIT_URL=https://gitlab.com`). Default `https://github.com`
- `GIT_BRANCH` Run tests over the provided git branch (e.g.: `GIT_BRANCH=develop`). Default: `master`
- `GIT_USER` Override git user (e.g.: `GIT_USER=collective`). Default: `eea`
- `GIT_CHANGE_ID` Run tests over a github pull-request (e.g.: `GIT_CHANGE_ID=PR-5`. Default: `<not-set>`
- `NAMESPACE` Volto add-on namespace (e.g.: `NAMESPACE=@eeacms`). Default: `<not-set>`
- `DEPENDENCIES` Volto add-on dependencies space separated (e.g.: DEPENDENCIES=`@eeacms/volto-blocks-form volto-slate`). Default: `<not-set>`
- `RAZZLE_API_PATH` Razzle API path (e.g.: `RAZZLE_API_PATH=http://foo.bar:8080/plone`). Default: `http://plone:8080/Plone`
- `CYPRESS_API_PATH` Cypress API Path (e.g.: `CYPRESS_API_PATH=http://foo.bar:8080/plone`). Default: `$RAZZLE_API_PATH`

## Supported commands

- `test` Run `jest` Volto add-on unit tests (Default)
- `eslint` Run `eslint` checks over Volto add-on code
- `stylelint` Run `stylelint` checks over Volto add-on code
- `prettier` Run `prettier` checks over Volto add-on code
- `cypress` Run `cypress` checks over Volto add-on code

## Copyright and license

The Initial Owner of the Original Code is European Environment Agency (EEA).
All Rights Reserved.

The Original Code is free software;
you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later
version.

## Funding

[European Environment Agency (EU)](http://eea.europa.eu)
