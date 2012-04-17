module Mintchip
  class ValueRequestMessage < MintchipMessage

    def initialize(value, response_url, annotation, info)
      super
      @info = info
    end

    def packet
      OpenSSL::ASN1::ASN1Data.new([sequence], 2, :CONTEXT_SPECIFIC)
    end

    private

    def sequence
      OpenSSL::ASN1::Sequence.new(sequence_data, 1, :EXPLICIT)
    end

    def sequence_data
      [payee_id, currency_code, transfer_value, include_cert,
        response_url, random_challenge]
    end

    def payee_id
      to_octet_string(to_padded_ascii_binary_coded_decimal(@info.id, 64))
    end

    def currency_code
      to_octet_string(@info.currency_code.chr)
    end

    def include_cert
      OpenSSL::ASN1::Boolean.new(true)
    end

    def transfer_value
      to_octet_string(to_padded_ascii_binary_coded_decimal(@value, 24))
    end

    def response_url
      OpenSSL::ASN1::IA5String(@response_url)
    end

    def random_challenge
      to_octet_string(random_bytes(4), 0, :IMPLICIT)
    end

    def random_bytes(n)
      Random.new().bytes(n)
    end

  end
end


