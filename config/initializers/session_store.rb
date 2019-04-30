# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

# Be sure to restart your server when you modify this file.

options = { key: '_rubygems_session', expire_after: Gemcutter::REMEMBER_FOR }
Rails.application.config.session_store :cookie_store, options

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# Rails.application.config.session_store :active_record_store
