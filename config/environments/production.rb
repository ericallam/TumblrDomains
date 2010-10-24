Tumblrdomains::Application.configure do
  config.cache_classes = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  config.serve_static_assets = false

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.after_initialize do
    DNSimple::Client.username = 'rubymaverick@gmail.com'
    DNSimple::Client.password = 'maverick1moneygood'

    AmazonFPS.access_key = "01A0AGCYE9V8P8BJ7T02"
    AmazonFPS.secret_key = "fVPcyE/vAWnL8xUXv0jwolGAfKsaEZAAzA9hRHna"

    Registrar.handler = Registrar::DNSSimpleHandler
  end
end
