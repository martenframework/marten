module Marten
  module Template
    # Allows to add support for custom classes to template contexts.
    #
    # Including this module in a class will make it "compatible" with the template engine so that instances of this
    # class can be included in context objects. The module will automatically ensure that every "attribute-like" method
    # can be accessed in templates when performing variable lookups.
    module Object
      # :nodoc:
      def resolve_template_attribute(key : String)
        {% begin %}
          value = case key
          {% if !@type.abstract? %}
            {% already_processed = [] of String %}
            {% for type in [@type] + @type.ancestors %}
              {% if type.name != "Object" && type.name != "Reference" %}
                {% for method in type.methods %}
                  {% if !already_processed.includes?(method.name.id.stringify) %}
                    {% if method.visibility == :public && !method.accepts_block? && method.args.empty? %}
                      when {{ method.name.id.stringify }}
                        self.{{ method.name.id }}
                      {% already_processed << method.name.id.stringify %}
                    {% end %}
                  {% end %}
                {% end %}
              {% end %}
            {% end %}
          {% end %}
          end

          value
        {% end %}
      end
    end
  end
end
