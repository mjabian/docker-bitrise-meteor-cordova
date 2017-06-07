# docker build -t wkd:docker-bitrise-meteor-cordova .
FROM bitriseio/docker-bitrise-base:latest

WORKDIR /opt/meteor/deps
ADD ./mongod.service .
RUN cp -f /opt/meteor/deps/mongod.service /lib/systemd/system/mongod.service

# Install MongoDB 
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 \
    && echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn mongodb-org \
    && mkdir -p /data/db

# Create non admin meteor user.
RUN adduser --disabled-password --gecos '' meteor \
    && adduser meteor sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to non-admin.
USER meteor

# Install and prime meteor.
RUN curl https://install.meteor.com/ | sh \
    && meteor create --full ~/prime_app \
    && mkdir ~/prime_app_debug \
    && mkdir ~/prime_app_release \
    && cd ~/prime_app \
    && meteor build ~/prime_app_debug --debug \
    && meteor build ~/prime_app_release

# Install the dependencies
RUN cd ~/prime_app_release \
    && tar xf prime_app.tar.gz \
    && cd bundle \
    && (cd programs/server && yarn install)

# Set working directory
WORKDIR /var/www/src

# Remove primer files.
RUN rm -rf ~/prime*
