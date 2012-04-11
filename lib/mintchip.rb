require 'openssl'
require 'net/https'
require 'uri'
require 'json'
require 'active_support/all'

require "mintchip/version"

module Mintchip
  CURRENCY_CODES = { CAD: 1 }

  class InvalidCurrency < StandardError; end
  class Error < StandardError ; end
  class SystemError < Error   ; end
  class CryptoError < Error   ; end
  class FormatError < Error   ; end
  class MintchipError < Error ; end


  def self.currency_code(name)
    CURRENCY_CODES[name.to_sym] or raise InvalidCurrency
  end

  class Hosted
    RESOURCE_BASE = "https://remote.mintchipchallenge.com/mintchip"

    def initialize(key, password)
      @p12 = OpenSSL::PKCS12.new(key, password)
    end

    %w(id currencyCode balance creditLogCount debitLogCount creditLogCountRemaining debitLogCountRemaining maxCreditAllowed maxDebitAllowed version).each do |attr|
      define_method(attr.underscore) { info[attr] }
    end

    # GET /info/{responseformat}
    def info
      JSON.parse get "/info/json"
    end

    # POST /receipts
    def load_value(vm)
      res = post "/receipts", vm, "application/vnd.scg.ecn-message"
      # body is an empty string on success, which is gross.
      res == ""
    end

    # POST /payments/request
    def create_value1(vrm)
      post "/payments/request", vrm, "application/vnd.scg.ecn-request"
    end

    def create_value2(payee_id, currency_name, amount_in_cents)
      currency_code = Mintchip.currency_code(currency_name)
      post "/payments/#{payee_id}/#{currency_code}/#{amount_in_cents}"
    end

    # GET /payments/lastdebit
    def last_debit
      get "/payments/lastdebit"
    end

    # GET /payments/{startindex}/{stopindex}/{responseformat}
    def debit_log(start, stop)
      JSON.parse get "/payments/#{start}/#{stop}/json"
    end

    # GET /receipts/{startindex}/{stopindex}/{responseformat}
    def credit_log(start, stop)
      JSON.parse get "/receipts/#{start}/#{stop}/json"
    end

    private

    def connection
      uri               = URI.parse RESOURCE_BASE
      https             = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl     = true
      https.cert        = @p12.certificate
      https.key         = @p12.key
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: Fix this.
      # https.ca_file   = File.join(TestDataPath, 'cacert.pem')

      https
    end

    def get(path)
      uri = URI.parse(RESOURCE_BASE + path)
      req = Net::HTTP::Get.new(uri.path)
      handle_response connection.start { |cx| cx.request(req) }
    end

    def post(path, data = {}, content_type = nil)
      uri = URI.parse(RESOURCE_BASE + path)
      req = Net::HTTP::Post.new(uri.path)

      Hash === data ? req.set_form_data(data) : req.body = data
      req.content_type = content_type if content_type

      handle_response connection.start { |cx| cx.request(req) }
    end

    def handle_response(resp)
      case resp.code.to_i
      when 200 ; resp.body
      when 452 ; raise Mintchip::SystemError, resp.msg
      when 453 ; raise Mintchip::CryptoError, resp.msg
      when 454 ; raise Mintchip::FormatError, resp.msg
      when 455 ; raise Mintchip::MintchipError, resp.msg
      else     ; raise Mintchip::Error, resp.msg
      end
    end

  end

end

