module Marten
  module DB
    module Field
      # :nodoc:
      module IsAutoField
        # :nodoc:
        def perform_validation(_record : Model); end

        # :nodoc:
        macro check_definition(field_id, kwargs)
          {% if kwargs.is_a?(NilLiteral) || kwargs[:primary_key].is_a?(NilLiteral) || !kwargs[:primary_key] %}
            {% raise "Auto fields fields must define 'primary_key: true'" %}
          {% end %}

          {% if !kwargs.is_a?(NilLiteral) && kwargs[:null].is_a?(BoolLiteral) && kwargs[:null] %}
            {% raise "Auto fields fields cannot set 'null: true'" %}
          {% end %}
        end
      end
    end
  end
end
