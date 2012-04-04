require "mintchip/version"

module Mintchip

  CURRENCY_CODES = {
    CAD: 1
  }

  class InvalidCurrency < StandardError; end

  def self.currency_code(name)
    CURRENCY_CODES(name.to_sym) or raise InvalidCurrency
  end

  # GET /mintchip/info/{responseformat}
  def info
    get "/mintchip/info/json"
  end

  # POST /mintchip/receipts
  def load_value(vm)
    post "/mintchip/receipts", {"Value Message" => vm}, {"Content-Type" => "application/vnd.scg.ecn-message"}
  end

  # POST /mintchip/payments/request
  def create_value1(vrm)
    post "/mintchip/payments/request", {"Value Request Message" => vrm}, {"Content-Type" => "application/vnd.scg.ecn-request"}
  end

  def create_value2(payee_id, currency_name, amount_in_cents)
    currency_code = MintChip.currency_code(currency_name)
    post "/mintchip/payments/#{payee_id}/#{currency_code}/#{amount_in_cents}"
  end

  # GET /mintchip/payments/lastdebit
  def last_debit
    get "/mintchip/payments/lastdebit"
  end

  # GET /mintchip/payments/{startindex}/{stopindex}/{responseformat}
  def debit_log()
    get "/mintchip/payments/#{start}/#{stop}/json"
  end

  # GET /mintchip/receipts/{startindex}/{stopindex}/{responseformat}
  def ASDF
    get "/mintchip/receipts/#{start}/#{stop}/json"
  end

end
