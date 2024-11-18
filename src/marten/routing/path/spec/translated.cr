require "./base"

module Marten
  module Routing
    module Path
      module Spec
        # Represents a translated path specification.
        #
        # A translated path specification is a path specification whose path can be translated into multiple locales.
        # As such, it contains a mapping of locales to static path specifications that are determined by translating a
        # translated path using the project's locales.
        class Translated < Base
          @path_info_mapping : Hash(String, Static)?

          def initialize(@translated_path : TranslatedPath, @regex_suffix : String? = nil)
          end

          def resolve(path : String) : Path::Match?
            return unless path_info_mapping.has_key?(I18n.locale)

            path_info_mapping[I18n.locale].resolve(path)
          end

          def reverser(name : String) : Reverser
            path_for_interpolations = Hash(String?, String).new

            path_for_interpolations[nil] = path_info_mapping[Marten.settings.i18n.default_locale].path_for_interpolation
            path_info_mapping.each do |locale, path_info|
              path_for_interpolations[locale] = path_info.path_for_interpolation
            end

            Reverser.new(name, path_for_interpolations, path_info_mapping.values.first.parameters)
          end

          private getter regex_suffix
          private getter translated_path

          private def path_info_mapping : Hash(String, Static)
            @path_info_mapping ||= begin
              h = {} of String => Static

              # Determine the list of locales to translate the path into.
              available_locales = [Marten.settings.i18n.default_locale]
              if !(a = Marten.settings.i18n.available_locales).nil?
                available_locales += a
              end

              # Generate a path info object for each locale.
              available_locales.each do |locale|
                I18n.with_locale(locale) do
                  path = begin
                    I18n.t!(translated_path.key, default: nil)
                  rescue I18n::Errors::MissingTranslation
                    if locale == Marten.settings.i18n.default_locale
                      raise Errors::InvalidRulePath.new(
                        "No default locale translation found for route associated with '#{translated_path.key}' " \
                        "translation key"
                      )
                    end

                    nil
                  end

                  h[locale] = if !path.nil?
                                regex, path_for_interpolation, parameters = Rule::Base.path_to_regex(path, regex_suffix)
                                Path::Spec::Static.new(regex, path_for_interpolation, parameters)
                              else
                                # If the translation is missing and the locale is not the default one, we fallback to
                                # the default locale translation.
                                h[Marten.settings.i18n.default_locale]
                              end
                end
              end

              h
            end
          end
        end
      end
    end
  end
end
