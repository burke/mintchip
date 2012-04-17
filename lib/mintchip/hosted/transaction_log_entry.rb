module Mintchip
  class Hosted
    class TransactionLogEntry
      ATTRIBUTES = %w(amount challenge index logType payerId payeeId transactionTime currencyCode)

      attr_reader *ATTRIBUTES.map(&:underscore).map(&:to_sym)

      def initialize(attrs)
        ATTRIBUTES.each do |attr|
          instance_variable_set("@#{attr.underscore}", attrs[attr])
        end
      end
    end
  end
end
