require 'base64'
require 'cgi'
require 'openssl'

module AmazonFPS

  SIGNATURE_VERSION = 2.freeze
  SIGNATURE_METHOD = 'HmacSHA256'.freeze
  
  COBRAND_VERSION = "2009-01-09"
  
  PIPELINE_SANDBOX_SERVICE_URI = "https://authorize.payments-sandbox.amazon.com/cobranded-ui/actions/start"
  PIPELINE_SERVICE_URI = 'https://authorize.payments.amazon.com/cobranded-ui/actions/start'

  mattr_accessor :access_key
  mattr_accessor :secret_key

  def self.cobrand_url(amount, pipeline_name, caller_reference, payment_reason, return_url)
    uri = URI.parse(PIPELINE_SANDBOX_SERVICE_URI)

    params = HashWithIndifferentAccess.new({
      :callerKey => self.access_key,
      :transactionAmount => amount,
      :pipelineName => pipeline_name,
      :returnUrl => return_url,
      :version => COBRAND_VERSION,
      :callerReference => caller_reference,
      :paymentReason => payment_reason,
      :SignatureVersion => SIGNATURE_VERSION,
      :SignatureMethod => SIGNATURE_METHOD
    })

    params[:Signature] = sign(uri, 'GET', params)

    param_string = params.map {|key, value| "#{encode(key)}=#{encode(value)}" }.join("&")

    "#{PIPELINE_SANDBOX_SERVICE_URI}?#{param_string}"
  end

  def self.sign(uri, method, params)
    SignatureUtils.sign_parameters({
      :parameters => params,
      :aws_secret_key => self.secret_key,
      :host => uri.host,
      :verb => method,
      :uri => uri.path
    })
  end

  def self.encode(s)
    SignatureUtils.urlencode(s)
  end

  class SignatureUtils 

    SIGNATURE_KEYNAME = "Signature"
    SIGNATURE_METHOD_KEYNAME = "SignatureMethod"
    SIGNATURE_VERSION_KEYNAME = "SignatureVersion"

    HMAC_SHA256_ALGORITHM = "HmacSHA256"
    HMAC_SHA1_ALGORITHM = "HmacSHA1"

    def self.sign_parameters(args)
      string_to_sign = calculate_string_to_sign_v2(args)

      compute_signature(string_to_sign, args[:aws_secret_key])
    end
    
    # Convert a string into URL encoded form.
    def self.urlencode(plaintext)
      CGI.escape(plaintext.to_s).gsub("+", "%20").gsub("%7E", "~")
    end

    private # All the methods below are private

    def self.calculate_string_to_sign_v2(args)
      parameters = args[:parameters]

      uri = args[:uri] 
      uri = "/" if uri.nil? or uri.empty?
      uri = urlencode(uri).gsub("%2F", "/") 

      verb = args[:verb]
      host = args[:host].downcase


      # exclude any existing Signature parameter from the canonical string
      sorted = (parameters.reject { |k, v| k == SIGNATURE_KEYNAME }).sort
      
      canonical = "#{verb}\n#{host}\n#{uri}\n"
      isFirst = true

      sorted.each { |v|
        if(isFirst) then
          isFirst = false
        else
          canonical << '&'
        end

        canonical << urlencode(v[0])
        unless(v[1].nil?) then
          canonical << '='
          canonical << urlencode(v[1])
        end
      }

      return canonical
    end

    def self.compute_signature(canonical, aws_secret_key)
      digest = OpenSSL::Digest::Digest.new('sha256')
      return Base64.encode64(OpenSSL::HMAC.digest(digest, aws_secret_key, canonical)).chomp
    end

  end

end
