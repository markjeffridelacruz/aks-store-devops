# Stage 1 - Build
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

# Stage 2 - Serve
FROM nginx:stable-alpine

RUN apk add --no-cache wget gettext

COPY --from=builder /app/dist /usr/share/nginx/html

ARG APP_VERSION=0.1.0
ENV APP_VERSION=$APP_VERSION

COPY nginx.conf /etc/nginx/conf.d/nginx.conf.template
RUN envsubst '${APP_VERSION}' < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/default.conf

EXPOSE 8081

CMD ["nginx", "-g", "daemon off;"]
