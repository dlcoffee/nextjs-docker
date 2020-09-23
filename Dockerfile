# --- Base ----
FROM cypress/base:14 AS base

# Change directory so that our commands run inside this new directory
WORKDIR /usr/src/app


# --- Builder ----
FROM base AS builder

# Creates a caching layer using both package.json AND package-lock.json
COPY package*.json /usr/src/app/

# Install production only modules to be used in the released image
RUN npm ci --only=production 
RUN cp -R node_modules prod_node_modules

# Install all modules for everything else
RUN npm ci


# --- Development ---
FROM base AS dev

ENV PORT 3000
EXPOSE 3000

# Copies over pre-installed dependencies
COPY --from=builder /usr/src/app/node_modules ./node_modules

RUN npx next telemetry disable

# maybe can move the build into the builder step?
# Copies the source code into the working directory in the container
COPY . /usr/src/app

CMD [ "npm", "run", "dev" ]


# --- Release ---
FROM base AS release

ENV NODE_ENV production
ENV PORT 3000
EXPOSE 3000

# Copies over pre-installed dependencies for production
COPY --from=builder /usr/src/app/prod_node_modules ./node_modules

# maybe can move the build into the builder step?
# Copies the source code into the working directory in the container
COPY . /usr/src/app

# Builds the nextjs application
RUN npm run build

RUN npx next telemetry disable

# RUN addgroup -g 1001 -S nodejs
# RUN adduser -S nextjs -u 1001

# USER nextjs

CMD [ "npm", "start" ]

# --- Cypress E2E ---
FROM base AS cypress

# Cypress caches the binary in ~/root
COPY --from=builder /root/.cache/ /root/.cache/

# Copies over pre-installed dependencies
COPY --from=builder /usr/src/app/node_modules ./node_modules

# maybe can move the build into the builder step?
# Copies the source code into the working directory in the container
COPY . /usr/src/app

CMD [ "npm", "run", "test:cypress" ]