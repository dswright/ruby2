
Rails.application.configure do

  require 'rails_extensions'
  # Settings specified here will take precedence over those in config/application.rb.

  #enable garbagae collector stats
  GC::Profiler.enable

  #set errors to be expressed and not surpressed that are returned from ActiveRecord callbacks.
  config.active_record.raise_in_transactional_callbacks = true

  config.action_controller.asset_host = 'http://10.0.0.2:5000'
  config.action_mailer.asset_host = config.action_controller.asset_host

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false


  #SET MAILER CONFIGURATION
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
  :address              => "smtp.mandrillapp.com",
  :port                 => 587,
  :domain               => 'heroku.com',
  :user_name            => 'dylansamuelwright@gmail.com',
  :password             => 'Qvh1r0BpRJEKdnP_TYTjMg',
  :authentication       => 'plain',
  :enable_starttls_auto => true
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

end


