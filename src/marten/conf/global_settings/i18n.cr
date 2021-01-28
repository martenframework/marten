module Marten
  module Conf
    class GlobalSettings
      # Allows to configure internationalization-related settings.
      class I18n
        @available_locales : Array(String)?
        @default_locale : String = "en"

        getter available_locales
        getter default_locale

        # Allows to set the available locales.
        def available_locales=(available_locales : Array(String | Symbol) | Nil)
          @available_locales = available_locales.nil? ? nil : available_locales.map(&.to_s)
        end

        # Allows to set the default locale.
        def default_locale=(locale : String | Symbol)
          @default_locale = locale.to_s
        end
      end
    end
  end
end
