WOR_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/widgets-on-rails.yml")[RAILS_ENV]
CACHE_PREFIX = WOR_CONFIG['session_cache_prefix'].to_s
WIDGET_PREFIX = WOR_CONFIG['widget_cache_prefix'].to_s
