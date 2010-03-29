# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_provider_session',
  :secret      => 'e897597384f6d7e09e1d2a190277c082b92c4185df090ac94c860467d2d3b167300988e9c3a73d48faa7b8dba38dff9396cd8c816ccd7a191b216e9ffb2c7bef'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
