module Marten
  module Conf
    abstract class Settings
      abstract def initialize

      macro namespace(ns)
        {% sanitized_ns = ns.is_a?(StringLiteral) || ns.is_a?(SymbolLiteral) ? ns.id : nil %}
        {% if sanitized_ns.is_a?(NilLiteral) %}{% raise "Cannot use '#{ns}' as a valid setting namespace" %}{% end %}
        class Marten::Conf::GlobalSettings
          def {{ sanitized_ns }} : Marten::Conf::Settings
            @{{ sanitized_ns }} ||= {{ @type }}.new
          end
        end
      end
    end
  end
end
