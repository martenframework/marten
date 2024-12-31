module Marten
  module Routing
    module Rule
      class Localized < Base
        @reversers : Array(Reverser)?

        getter rules

        def initialize(@prefix_default_locale = true)
          @rules = Array(Rule::Base).new
        end

        def name
          raise NotImplementedError.new("Localized rules don't provide names")
        end

        def resolve(path : String) : Nil | Match
          return unless path.starts_with?(locale_prefix)

          inner_path = path[(locale_prefix.size - 1)..]
          rules.each do |r|
            matched = r.resolve(inner_path)
            break matched unless matched.nil?
          end
        end

        protected getter? prefix_default_locale

        protected def reversers : Array(Reverser)
          @reversers ||= rules.flat_map(&.reversers).tap do |reversers|
            reversers.each do |reverser|
              reverser.prefix_locales = true
              reverser.prefix_default_locale = prefix_default_locale?
            end
          end
        end

        private def locale_prefix : String
          if I18n.locale == Marten.settings.i18n.default_locale && !prefix_default_locale?
            "/"
          else
            "/#{I18n.locale}/"
          end
        end
      end
    end
  end
end
