FROM node:18.12
# Create app directory
WORKDIR /usr/src/app
ENV NODE_ENV=production
ENV VUE_APP_API_URL=http://0.0.0.0:8081
COPY . .
RUN npm install
RUN npm run serve

