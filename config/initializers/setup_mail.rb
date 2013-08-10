ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "gmail.com",
  :user_name            => ENV["EMAIL_NAME"],
  :password             => ENV["EMAIL_PASSWORD"],
  :authentication       => "plain",
  :enable_starttls_auto => true
}

ActionMailer::Base.default_url_options[:host] = AppConfig['host_address']

# Used the following to set up the variable for local dev, redis server and on heroku
# $ heroku config:set EMAIL_NAME=username
# $ export EMAIL_NAME=username
# $ heroku config:set EMAIL_PASSWORD=password
# $ export EMAIL_PASSWORD=password