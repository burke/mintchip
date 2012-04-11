require 'openssl'
require 'rest-client'
require 'json'
require 'active_support/all'

require "mintchip/version"

module Mintchip

  CURRENCY_CODES = {
    CAD: 1
  }

  class InvalidCurrency < StandardError; end

  def self.currency_code(name)
    CURRENCY_CODES[name.to_sym] or raise InvalidCurrency
  end

  class Hosted
    RESOURCE_BASE = "https://remote.mintchipchallenge.com/mintchip"

    def initialize(key, password)
      @p12 = OpenSSL::PKCS12.new(key, password)
    end

    %w(id currencyCode balance creditLogCount debitLogCount creditLogCountRemaining debitLogCountRemaining maxCreditAllowed maxDebitAllowed version).each do |attr|
      define_method attr.underscore { info[attr] }
    end

    # GET /info/{responseformat}
    def info
      JSON.parse get "/info/json"
    end

    # POST /receipts
    def load_value(vm)
      res = post "/receipts", vm, {"Content-Type" => "application/vnd.scg.ecn-message"}

      res == ""
    end

    # POST /payments/request
    def create_value1(vrm)
      post "/payments/request", {"Value Request Message" => vrm}, {"Content-Type" => "application/vnd.scg.ecn-request"}
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

    def get(path)
      resource = RestClient::Resource.new(RESOURCE_BASE + path, ssl_client_key: @p12.key, ssl_client_cert: @p12.certificate)
      resource.get
    end

    def post(path, data = {}, headers = {})
      resource = RestClient::Resource.new(RESOURCE_BASE + path, ssl_client_key: @p12.key, ssl_client_cert: @p12.certificate)
      resource.post(data, headers)
    end

  end

end
