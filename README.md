# Dockerized Next.js Application

The goal is to use a multi-stage `Dockerfile` with multiple `docker-compose.yml`s to be able to develop a containerized app locally as well as be able to create a production build.

## How To Use

Run `docker-compose build` to build the image and then `docker-compose up` to run the app and you should be able to visit `localhost:3000/` to see a Next.js starter page.

The repo is already set up with a `package-lock.json` that was generated from the container. You should not run `npm install` from the host.

For local development, there is a bind-mount configured through `docker-compose.yml`
file which will sync code changes to the container.

To build a production image, you will need to specify the `production` yaml file.

```
docker-compose -f docker-compose.yml -f docker-compose.production.yml build
```

**Note:** The `app` service will run with the configuration of the last `docker build` command.

### How to modify packages:

You _should not_ run `npm install` locally. We want to use the `node_modules` that are generated in the container, not from the host. We also don't want to modify `package-lock.json` for the same reason.

We want consistent dependencies, so _all_ package modifications should happen through the container.

For example:

```
docker-compose run --rm app bash

npm install --save express
```

Will modify the `node_modules` within the container, as well as generate a new `package-lock.json` on your local machine (which you can and should commit to source control).

## Dockerfile

The `Dockerfile` is set up to use multi stage builds using the "builder" pattern. One stage is to install packages from a certain image, and another stage starts from a smaller image, and pulls the packages in, in order to reduce overall image size for the application.

The current approach is to start from a cypress image base in order to be able to install and run cypress correctly. There is a stage where `npm ci` is run _twice_ in order to generate a `node_modules` folder for local development, which will include `devDependencies`, and another `node_modules` without `devDependencies`, intended for the released image.

Additionally to the cypress base image, the cypress stage will also need to pull in the cypress cache which contains the binary for it to run.

## docker-compose

The `docker-compose.yml` is using the `override` approach so that the "non-override" yaml is considered the base. By default, the `docker-compose.override.yml` will get applied when you run `docker-compose up` and is alrerady configured for local development.

It is taking advantage of the `Dockerfile`'s multi stage builds for different targets.

For local development, each service has the bind-mount for local code so that changes locally will get reflected in the container and vice-versa. The exception to this is the `node_modules` folder.
