require 'openssl'
require 'net/http'
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

    # GET /info/{responseformat}
    def info
      @info ||= Info.new get "/info/json"
    end

    class Info
      ATTRIBUTES = %w(id currencyCode balance creditLogCount debitLogCount) +
        %w(creditLogCountRemaining debitLogCountRemaining maxCreditAllowed maxDebitAllowed version)

      attr_reader *ATTRIBUTES.map(&:underscore).map(&:to_sym)

      def initialize(str)
        attrs = JSON.parse(str)
        ATTRIBUTES.each do |attr|
          instance_variable_set("@#{attr.underscore}", attrs[attr])
        end
      end
    end

    # POST /receipts
    def load_value(vm)
      res = post "/receipts", vm, "application/vnd.scg.ecn-message"
      # body is an empty string on success, which is gross.
      res == ""
    end

    # creates a base64 encoded value request message
    def create_value_request(value, annotation_ = "", response_url_ = "")
      packet = create_value_message_request_packet(value, response_url_)
      message = create_mintchip_message(packet, annotation_)
      encoded_value_request_message = Base64.strict_encode64(message.to_der)
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
      list = JSON.parse get "/payments/#{start}/#{stop}/json"
      list.map{|item| TransactionLogEntry.new item}
    end

    # GET /receipts/{startindex}/{stopindex}/{responseformat}
    def credit_log(start, stop)
      list = JSON.parse get "/receipts/#{start}/#{stop}/json"
      list.map{|item| TransactionLogEntry.new item}
    end

    class TransactionLogEntry
      ATTRIBUTES = %w(amount challenge index logType payerId payeeId transactionTime currencyCode)

      attr_reader *ATTRIBUTES.map(&:underscore).map(&:to_sym)

      def initialize(attrs)
        ATTRIBUTES.each do |attr|
          instance_variable_set("@#{attr.underscore}", attrs[attr])
        end
      end
    end

    private

    # converts an integer to a binary coded decimal string
    def to_binary_coded_decimal(n)
      str = n.to_s
      bin = ""
      str.each_char do |c|
        bin << c.to_i.to_s(2).rjust(4,'0')
      end
      bin
    end

    # 64 bit bcd representation, padded with zeros, in ascii
    def to_padded_ascii_binary_coded_decimal(value, length_in_bits, pad_character = '0')
      res = to_binary_coded_decimal(value).to_s
      res = res.rjust(length_in_bits, pad_character)
      res = [res].pack("B*")
    end

    # wrapper for OpenSSL::ASN1::OctectString.new()
    def to_octet_string(value, tag = -1, tagging = :EXPLICIT)
      if tag == -1 then
        res = OpenSSL::ASN1::OctetString.new(value)
      else
          res = OpenSSL::ASN1::OctetString.new(value, tag, tagging)
       end
      res
    end

    def create_value_message_request_packet(value, response_url = "")
      payee_id = to_octet_string(to_padded_ascii_binary_coded_decimal(info.id, 64))
      currency_code = to_octet_string(info.currency_code.chr)
      transfer_value = to_octet_string(to_padded_ascii_binary_coded_decimal(value, 24))
      include_cert = OpenSSL::ASN1::Boolean.new(true)
      response_url = OpenSSL::ASN1::IA5String(response_url)
      random_challenge = to_octet_string(Random.new().bytes(4), 0, :IMPLICIT)
      
      packet = OpenSSL::ASN1::Sequence.new( [ payee_id, currency_code, transfer_value, include_cert, response_url, random_challenge ], 1, :EXPLICIT )
      packet = OpenSSL::ASN1::ASN1Data.new( [ packet ] , 2, :CONTEXT_SPECIFIC)
    end

    def create_mintchip_message(packet, annotation = "")
      message_version = OpenSSL::ASN1::Enumerated.new(1, 0, :EXPLICIT)
      annotation = OpenSSL::ASN1::IA5String.new(annotation, 1, :EXPLICIT)
      message = OpenSSL::ASN1::Sequence.new( [ message_version, annotation, packet ], 0, :EXPLICIT, :APPLICATION)
    end

    def connection
      uri               = URI.parse RESOURCE_BASE
      https             = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl     = true
      https.cert        = @p12.certificate
      https.key         = @p12.key
      https.ca_file     = File.expand_path("../../mintchip.pem", __FILE__)
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER

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

