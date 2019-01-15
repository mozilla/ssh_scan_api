FROM ruby:2.6.0
MAINTAINER Jonathan Claudius
COPY ./Gemfile /app/Gemfile
COPY ./lib /app/lib
COPY ./bin /app/bin
COPY ./ssh_scan_api.gemspec /app/ssh_scan_api.gemspec
COPY ./db /app/db
RUN cd /app && \
    gem install bundler && \
    bundle install
COPY ./lib /app/lib
COPY ./bin /app/bin
COPY ./Rakefile /app/Rakefile