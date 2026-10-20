# backend/Dockerfile
FROM node:22-alpine

WORKDIR /app

# Install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY src ./src
COPY .env ./

# Backend listens on port 5000
EXPOSE 5000

CMD ["node", "src/server.js"]