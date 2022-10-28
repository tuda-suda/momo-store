FROM node:18.12 as builder
# Create app directory
WORKDIR /usr/src/app
ENV NODE_ENV=production
ENV VUE_APP_API_URL=http://0.0.0.0:8081
COPY . .
RUN npm install && npm run build

FROM nginx:1.21.6-alpine
COPY --from=builder /usr/src/app/dist /usr/share/nginx/html/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
