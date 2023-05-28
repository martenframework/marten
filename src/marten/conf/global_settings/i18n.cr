module Marten
  module Conf
    class GlobalSettings
      # Allows to configure internationalization-related settings.
      class I18n
        @available_locales : Array(String)?
        @default_locale : String = "en"
        @locale_cookie_name : String = "marten_locale"

        # Returns the available locales.
        getter available_locales

        # Returns the default locale.
        getter default_locale

        # Returns the name of the cookie used to determine the current locale.
        getter locale_cookie_name

        # Allows to set the available locales.
        def available_locales=(available_locales : Array(String | Symbol) | Nil)
          @available_locales = available_locales.nil? ? nil : available_locales.map(&.to_s)
        end

        # Allows to set the default locale.
        def default_locale=(locale : String | Symbol)
          @default_locale = locale.to_s
        end

        # Allows to set the name of the cookie used to determine the current locale.
        def locale_cookie_name=(name : String | Symbol)
          @locale_cookie_name = name.to_s
        end
      end
    end
  end
end
