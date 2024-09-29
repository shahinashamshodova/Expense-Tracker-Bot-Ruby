FROM ruby:3.3

ENV APP_HOME /app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile Gemfile.lock $APP_HOME/
RUN bundle install
COPY . $APP_HOME/

CMD ["ruby", "app.rb"]
