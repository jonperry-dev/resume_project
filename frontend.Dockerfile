FROM node:20 AS build

ARG FRONTEND_DIR
ARG REACT_APP_RANK_ENDPOINT
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

RUN echo "REACT_APP_RANK_ENDPOINT=${REACT_APP_RANK_ENDPOINT}" > .env
RUN --mount=type=secret,id=api_token \
    echo "REACT_APP_RANK_API_KEY=$(cat /run/secrets/api_token)" > .env

CMD ["nginx", "-g", "daemon off;"]
