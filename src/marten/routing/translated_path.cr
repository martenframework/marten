module Marten
  module Routing
    # Represents a translated path used in routes.
    struct TranslatedPath
      getter key

      def initialize(@key : String)
      end

      def ==(other : TranslatedPath)
        super || key == other.key
      end

      def to_s(io)
        io << I18n.t(key)
      end
    end
  end
end
