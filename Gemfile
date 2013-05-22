source 'https://rubygems.org'
ruby '2.0.0'

gem 'rails', '4.0.0.rc1'
gem 'bootstrap-sass', '2.3.0.1'
gem 'bcrypt-ruby', '3.0.1'
gem 'will_paginate', '3.0.4'
gem 'bootstrap-will_paginate', '0.0.9'

group :development, :test do
  gem 'sqlite3', '1.3.7'
  gem 'rspec-rails', '2.13.1'
  gem 'annotate', ">=2.5.0"
end

group :test do
  gem 'selenium-webdriver', '2.0'
  gem 'capybara', '2.1.0.rc1'
end

group :assets do
  gem 'sass-rails',   '4.0.0.rc1'
  gem 'coffee-rails', '4.0.0'
  gem 'uglifier', '1.0.3'
end

gem 'jquery-rails', '2.2.1'
gem 'turbolinks', '1.0.0'
gem 'jbuilder', '1.0.1'

group :production do
  gem 'pg', '0.14.1'
  gem 'rails_log_stdout',           github: 'heroku/rails_log_stdout'
  gem 'rails3_serve_static_assets', github: 'heroku/rails3_serve_static_assets'
end