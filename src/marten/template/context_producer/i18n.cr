module Marten
  module Template
    abstract class ContextProducer
      # Context producer that adds the current locale and the availables locales to the context.
      #
      # The current locale is exposed as a `locale` variable while the available locales are exposed as an
      # `available_locales` variable.
      class I18n < ContextProducer
        def produce(request : HTTP::Request? = nil)
          {
            "available_locales" => ::I18n.available_locales,
            "locale"            => ::I18n.locale,
          }
        end
      end
    end
  end
end
