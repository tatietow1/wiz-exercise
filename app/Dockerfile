# Container image for the Wiz Exercise app
FROM node:20-alpine

WORKDIR /app

# Required exercise file containing your name
COPY wizexercise.txt /wizexercise.txt

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src
COPY public ./public

EXPOSE 8080
CMD ["npm", "start"]
