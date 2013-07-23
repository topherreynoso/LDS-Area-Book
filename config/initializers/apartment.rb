Apartment.configure do |config|
  config.excluded_models = ["User", "Ward"]
  config.database_names = lambda{ Ward.pluck(:unit) }
end