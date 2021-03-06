require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # For each of the values of a hash entry, load the hash key's bundle group
  bundle_environment_aliases = Rails.groups(
      default: %w(production pre_production staging development test ci),
      headless: %w(development test ci),
      ci: %w(development test),
      test: %w(ci),
      development: %w(ci),
      assets: %w(development test)
  )
  Bundler.require(*bundle_environment_aliases)
end

module Vecnet
  class Application < Rails::Application
    config.vecnet_version = "v0.0.1"
    config.vecnet_release_date = "TBD"
    config.persistent_hostpath = "https://dl.vecnet.org/files/"
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true
    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?

    config.exceptions_app = lambda { |env| ErrorsController.action(:show).call(env) }

    config.action_dispatch.rescue_responses["ActionController::RoutingError"] = :not_found
    config.action_dispatch.rescue_responses["ActiveFedora::ObjectNotFoundError"] = :not_found
    config.action_dispatch.rescue_responses["ActiveFedora::ActiveObjectNotFoundError"] = :not_found
    config.action_dispatch.rescue_responses["Hydra::AccessDenied"] = :unauthorized
    config.action_dispatch.rescue_responses["CanCan::AccessDenied"] = :unauthorized

    config.build_identifier = begin
      Rails.root.join('config/build-identifier.txt').read.strip
    rescue Errno::ENOENT => e
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.generators do |g|
      g.test_framework :rspec, :spec => true, :fixture => false
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
    end

    # We are not using Antivirus, even though we require the ClamAV gem.
    config.default_antivirus_instance = lambda { |file_path|
      AntiVirusScanner::NO_VIRUS_FOUND_RETURN_VALUE
    }
  end
end
