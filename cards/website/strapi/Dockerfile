FROM node:22-slim AS build
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
COPY package.json package-lock.json ./
RUN npm config set fetch-retry-maxtimeout 600000 && npm ci
ENV PATH=/opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY . .
ENV NODE_ENV=production
RUN npm run build

FROM node:22-slim
ENV NODE_ENV=production
WORKDIR /opt
COPY --from=build /opt/package.json /opt/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
ENV PATH=/opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY --from=build /opt/app ./
RUN chown -R node:node /opt/app
USER node
EXPOSE 1337
CMD ["npm", "run", "start"]
