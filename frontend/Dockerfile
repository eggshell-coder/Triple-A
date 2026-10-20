# frontend/Dockerfile
FROM nginx:alpine

# Flutter web build comes here
COPY build/web /usr/share/nginx/html

# Nginx config: proxy /api -> backend:5000
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]