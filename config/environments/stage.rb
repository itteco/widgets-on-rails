# Settings specified here will take precedence over those in config/environment.rb

config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

config.action_controller.cache_store = :file_store, "tmp/cache" 

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
