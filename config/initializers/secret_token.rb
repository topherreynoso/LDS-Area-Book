# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
AreaBook::Application.config.secret_key_base = ENV["SECRET_KEY_BASE"]

# Changed this to protect app, used the following to set up the variable for local dev and on heroku
# $ heroku config:set SECRET_KEY_BASE=some-random-secret
# $ export SECRET_KEY_BASE=some-random-secret