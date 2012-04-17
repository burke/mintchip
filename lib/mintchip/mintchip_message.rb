module Mintchip
  class MintchipMessage

    def initialize(value, response_url, annotation, *)
      @value = value
      @response_url = response_url
      @annotation = annotation
    end

    def packet
      raise NotImplementedError
    end

    protected

    def to_base64
      Base64.strict_encode64(message.to_dar)
    end

    def message(packet, annotation = "")
      message_version = OpenSSL::ASN1::Enumerated.new(1, 0, :EXPLICIT)
      annotation = OpenSSL::ASN1::IA5String.new(annotation, 1, :EXPLICIT)
      message = OpenSSL::ASN1::Sequence.new([message_version, annotation, packet], 0, :EXPLICIT, :APPLICATION)
    end

    def to_binary_coded_decimal(n)
      str = n.to_s
      bin = ""
      str.each_char do |c|
        bin << c.to_i.to_s(2).rjust(4,'0')
      end
      bin
    end

    def to_padded_ascii_binary_coded_decimal(value, length_in_bits, pad_character = '0')
      res = to_binary_coded_decimal(value).to_s
      res = res.rjust(length_in_bits, pad_character)
      res = [res].pack("B*")
    end

    def to_octet_string(value, tag = -1, tagging = :EXPLICIT)
      ret = tag == -1 ? OpenSSL::ASN1::OctetString.new(value) : OpenSSL::ASN1::OctetString.new(value, tag, tagging)
    end

  end
end
