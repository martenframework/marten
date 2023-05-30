module Marten
  abstract class Middleware
    # Activates the right I18n locale based on the incoming requests.
    #
    # This middleware will activate the right locale based on the Accept-Language header. Only explicitly-configured
    # locales can be activated by this middleware (that is, locales that are specified in the
    # `Marten.settings.i18n.available_locales` and `Marten.settings.i18n.default_locale` settings). If the incoming
    # locale can't be found in the project configuration, the default locale will be used instead.
    class I18n < Middleware
      @available_locales : Array(String)?
      @downcased_available_locales : Array(String)?

      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        locale = get_locale_from(request)
        ::I18n.activate(locale)

        response = get_response.call

        # Ensures the Vary header includes Accept-Language (so that caches take it into account) and sets the
        # Content-Language header.
        response.headers.patch_vary("Accept-Language")
        response.headers["Content-Language"] ||= ::I18n.locale

        response
      end

      private ACCEPT_LANGUAGE_RE = %r{
        ([A-Za-z]{1,8}(?:-[A-Za-z0-9]{1,8})*|\*) # Locale tag
        (?:\s*;\s*q=([0-9]\.[0-9]))?             # Optional priority
      }x

      private LOCALE_TAG_RE = /^[a-z]{1,8}(?:-[a-z0-9]{1,8})*(?:@[a-z0-9]{1,20})?$/

      private def available_locales
        @available_locales ||= Marten.settings.i18n.available_locales || [Marten.settings.i18n.default_locale]
      end

      private def downcased_available_locales
        @downcased_available_locales ||= available_locales.map(&.downcase)
      end

      private def get_locale_from(request)
        # TODO: add support for path-based language discovery.

        # First attempt to discover the current locale from the cookies.
        if !(locale = request.cookies[Marten.settings.i18n.locale_cookie_name]?).nil?
          return locale if LOCALE_TAG_RE.matches?(locale) && downcased_available_locales.includes?(locale.downcase)

          if !(supported_locale = get_supported_locale(locale.downcase)).nil?
            return supported_locale
          end
        end

        # Then try to parse the Accept-Language header.
        parsed_accept_language_chain(request.headers.fetch(:ACCEPT_LANGUAGE, "")).each do |parsed_locale|
          break if parsed_locale == "*"

          supported_locale = get_supported_locale(parsed_locale)
          return supported_locale if !supported_locale.nil?
        end

        Marten.settings.i18n.default_locale
      end

      private def get_supported_locale(locale)
        return unless LOCALE_TAG_RE.matches?(locale)

        base_locale_tag = locale.split('-').first.downcase
        locale_candidates = [locale.downcase, base_locale_tag]

        # First try to return a locale that is explicitly supported by the application.
        matching_locale = locale_candidates.each do |lc|
          index = downcased_available_locales.index(lc)
          break available_locales[index] unless index.nil?
        end
        return matching_locale if !matching_locale.nil?

        # Otherwise tries to return a locale that is supported and that matches the base locale tag.
        matching_locale = available_locales.find { |l| l.downcase.starts_with?("#{base_locale_tag}-") }
        return matching_locale if !matching_locale.nil?
      end

      private def parsed_accept_language_chain(accept_language)
        # Parse an "Accept-Language" string and build an array of locales ordered by priority.
        chain = [] of Tuple(String, Float64)
        accept_language.downcase.scan(ACCEPT_LANGUAGE_RE).each do |match|
          locale = match.captures[0].not_nil!

          raw_priority = match.captures[1]
          priority = begin
            raw_priority.nil? || raw_priority.try(&.empty?) ? 1.0 : raw_priority.to_f
          rescue ArgumentError
            1.0
          end

          chain << {locale, priority}
        end

        chain.sort { |a, b| a[1] <=> b[1] }.reverse!.map(&.first)
      end
    end
  end
end
