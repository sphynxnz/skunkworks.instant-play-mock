FROM node:8
WORKDIR /app
COPY package.json /app
COPY . /app
RUN npm install mountebank -g
RUN npm install uuid -g
RUN npm install moment-timezone -g
RUN npm install randomstring -g
RUN npm install faker -g
CMD npm run start:instant-play:mock
EXPOSE 2525 8090