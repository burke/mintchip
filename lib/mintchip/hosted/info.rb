module Mintchip
  class Hosted
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
  end
end
