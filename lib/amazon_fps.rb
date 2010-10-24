require 'base64'
require 'cgi'
require 'openssl'

module AmazonFPS

  SIGNATURE_VERSION = 2.freeze
  SIGNATURE_METHOD = 'HmacSHA256'.freeze
  
  COBRAND_VERSION = "2009-01-09"
  
  PIPELINE_SANDBOX_SERVICE_URI = "https://authorize.payments-sandbox.amazon.com/cobranded-ui/actions/start"
  PIPELINE_SERVICE_URI = 'https://authorize.payments.amazon.com/cobranded-ui/actions/start'

  FPS_SERVICE_URI = 'https://fps.amazonaws.com'
  FPS_SANDBOX_URI = 'https://fps.sandbox.amazonaws.com'

  FPS_VERSION = '2008-09-17'

  GLOBAL_LIMIT = "1000"

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
      :SignatureMethod => SIGNATURE_METHOD,
      :paymentMethod => 'CC,ACH,ABT',
      :recurringPeriod => '1 month'
    })

    params[:Signature] = sign(uri, 'GET', params)

    param_string = params.map {|key, value| "#{encode(key)}=#{encode(value)}" }.join("&")

    "#{PIPELINE_SANDBOX_SERVICE_URI}?#{param_string}"
  end

  class Request

  end
 
  class Pay < Request
    include HTTParty

    default_params(
      'Action' => 'Pay', 
      'SignatureVersion' => SIGNATURE_VERSION, 
      'SignatureMethod' => SIGNATURE_METHOD,
      'Version' => FPS_VERSION
    )

    def initialize(caller_reference, token_id, amount)
      @options = {
        'CallerReference' => caller_reference,
        'SenderTokenId' => token_id,
        'TransactionAmount.Value' => amount,
        'TransactionAmount.CurrencyCode' => 'USD',
        'Timestamp' => Time.now.gmtime.iso8601,
        'AWSAccessKeyId' => AmazonFPS.access_key 
      }
    end

    def call
      response = self.class.get(FPS_SANDBOX_URI, :query => @options.merge(:Signature => signature))

      @response = if response.parsed_response.is_a?(String)
        Crack::XML.parse(response.parsed_response)
      else
        response.parsed_response
      end

      self
    end

    def success?
      !!@response["PayResponse"]
    end

    def transaction_id
      @response["PayResponse"]["PayResult"]["TransactionId"]
    end

    def transaction_status
      @response["PayResponse"]["PayResult"]["TransactionStatus"]
    end

    def error_message
      @response["Response"]["Errors"]["Error"]["Message"]
    rescue NoMethodError
      "Unspecified Error"
    end

    private

    def signature
      AmazonFPS.sign(URI.parse(FPS_SANDBOX_URI), 'GET', self.class.default_params.merge(@options))
    end
  end

  class CobrandResponse
    SUCCESS_STATUSES = %w(SC SA SB)
    ERROR_STATUSES = %w(SE A CE PE NP NM)

  #  {
  #    "signature"=>"mfT87zqvCCafsLrXt3BBcxSTk/rPX3toBKpPbiz/GpL1kJoKVfbCKyPwHdmwSTRh7xZuMmLxf7SG\nOYERDPO701Q1tfYfpmCJMA+opjlmqV7Alx6M7U0K35d2zoyg/AIYMyfrBkntfKGgjsv3etN1r1CE\ntn6z63vLVd3O3qrniDA=", 
  #    "expiry"=>"04/2016", 
  #    "signatureVersion"=>"2", 
  #    "signatureMethod"=>"RSA-SHA1", 
  #    "certificateUrl"=>"https://fps.sandbox.amazonaws.com/certs/090910/PKICert.pem?requestId=bjzkf92v93h797ucgzcv6ay8idf9qjobhpul5f10o76j6aln48j", "tokenID"=>"G6UURNZFCUR819UE5JAC2FRPENIGMLXD4DP9Q4MEER1PRE3E9Q9A2M4EITF2LFKS", 
  #    "status"=>"SC", 
  #    "callerReference"=>"tumblr-21" 
  #  }
    def initialize(params)
      @params = params
    end

    def success?
      SUCCESS_STATUSES.include? @params[:status]
    end

    def token
      @params[:tokenID]
    end

    def error_message
      @params[:errorMessage]
    end

    def caller_reference
      @params[:callerReference]
    end


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
