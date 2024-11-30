FROM node:20 AS build

ARG FRONTEND_DIR
WORKDIR /app

COPY ${FRONTEND_DIR}/package*.json .
RUN npm install

COPY ${FRONTEND_DIR}/src ./src
COPY ${FRONTEND_DIR}/public ./public
RUN npm run build

FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
