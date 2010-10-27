module Registrar
  mattr_accessor :handler

  def self.allowable_top_level_domains
    %w(net com)
  end

  class DNSSimpleHandler

    TEMPLATE_NAME = 'tumblr'

    def initialize(domain)
      @domain
    end

    def register!
      begin
        @dns_domain = DNSimple::Domain.register(@domain, {:id => contact.id})
        @dns_domain.apply('tumblr')
      rescue RuntimeError => e
        @error = e
      rescue DNSimple::Error => e
        @error = e
      end

      self
    end

    def success?
      @error.blank?
    end

    def error_message
      @error
    end

    def domain_id
      @dns_domain.id
    end

    private

    def contact
      DNSimple::Contact.all.first
    end

  end

  class MockHandler
    def initialize(*args); end
    def register!; end
    def apply_tumblr_template!; end
    def success?; true; end
    def domain_id; rand(100000); end
  end
end
