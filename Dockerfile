FROM node:14.0.0

RUN mkdir -p /opt/app
ENV NODE_ENV production
ENV PORT 3000
EXPOSE 3000

# Change directory so that our commands run inside this new directory
WORKDIR /usr/src/app

# Creates a caching layer using both package.json AND package-lock.json
COPY package*.json /usr/src/app/

# Create another caching layer, since Docker assumes the same command produces the same output
RUN npm ci

# Copies the source code into the working directory in the container
COPY . /usr/src/app

# Builds the nextjs application
RUN npm run build

RUN npx next telemetry disable

# RUN addgroup -g 1001 -S nodejs
# RUN adduser -S nextjs -u 1001

# USER nextjs

CMD [ "npm", "start" ]