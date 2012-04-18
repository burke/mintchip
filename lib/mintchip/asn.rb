module Mintchip
  class ASN
    module Builder
      def sequence(name, &block)
        register_term Sequence.new(name).with_body(&block)
      end
      def choice(name, options = {}, &block)
        tag = options.delete(:tag)
        tagging = options.delete(:tagging)
        register_term Choice.new(name, tag, tagging).with_body(&block)
      end
      def enumerated(name, choices, options = {})
        tag = options.delete(:tag)
        tagging = options.delete(:tagging)
        register_term Enumerated.new(name, choices, tag, tagging)
      end
      def ia5string(name, options = {})
        tag = options.delete(:tag)
        tagging = options.delete(:tagging)
        register_term IA5String.new(name, tag, tagging)
      end
      def octet_string(name, options = {})
        size = options.delete(:size)
        register_term OctetString.new(name, size)
      end
      def boolean(name)
        register_term Boolean.new(name)
      end
      def ref(type, name, options = {})
        if term = Builder.terms[type]
          puts "MMM #{type} : #{name}"
        else
          raise ArgumentError, "Undefined term #{type}"
        end
      end
      def method_missing(sym, name, options = {})
        ref(sym, name, options)
      end
      def self.terms
        @terms ||= {}
      end
      def register_term(term)
        Builder.terms[term.name.to_sym] = term
        add_term(term)
      end
    end

    class Sequence < Struct.new(:name)
      include Builder
      def add_term(term)
        puts "SSS " + term.inspect
      end
      def with_body(&block)
        instance_eval &block
        self
      end
    end

    class Choice < Struct.new(:name, :tag, :tagging)
      include Builder
      def add_term(term)
        puts "CCC " + term.inspect
      end
      def with_body(&block)
        instance_eval &block
        self
      end
    end

    class Enumerated < Struct.new(:name, :choices, :tag, :tagging)
    end

    class OctetString < Struct.new(:name, :size)
    end

    class Boolean < Struct.new(:name)
    end

    class IA5String < Struct.new(:name, :tag, :tagging)
    end

    def self.add_term(term)
      puts "    " + term.inspect
    end

    extend Builder
  end
end
