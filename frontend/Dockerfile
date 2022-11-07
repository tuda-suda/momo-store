FROM node:16-alpine as builder
# Create app directory
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
ENV NODE_ENV=development
ENV VUE_APP_API_URL=/
RUN npm run build

FROM nginx:1.21.6-alpine
COPY --from=builder /usr/src/app/dist /usr/share/nginx/html/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
