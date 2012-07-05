require 'mintchip/version'
require 'mintchip/hosted'
require 'mintchip/mintchip_message'
require 'mintchip/value_request_message'

module Mintchip
  CURRENCY_CODES = { :CAD => 1 }

  def self.currency_code(name)
    CURRENCY_CODES[name.to_sym] or raise InvalidCurrency
  end

  class InvalidCurrency < StandardError; end
  class Error < StandardError ; end
  class SystemError < Error   ; end
  class CryptoError < Error   ; end
  class FormatError < Error   ; end
  class MintchipError < Error ; end
end

