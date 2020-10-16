module Marten
  module DB
    abstract class Migration
      module DSL
        macro create_table(name)
          operations << CreateTable.new({{ name }}).build do
            {{ yield }}
          end.operation
        end

        macro _init_column(*args, **kwargs)
          {% if args.size != 2 %}{% raise "A column name and type must be explicitly specified" %}{% end %}

          {% sanitized_id = args[0].is_a?(StringLiteral) || args[0].is_a?(SymbolLiteral) ? args[0].id : nil %}
          {% if sanitized_id.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[0]}' as a valid column name" %}{% end %}

          {% sanitized_type = args[1].is_a?(StringLiteral) || args[1].is_a?(SymbolLiteral) ? args[1].id : nil %}
          {% if sanitized_type.is_a?(NilLiteral) %}
            {% raise "Cannot use '#{args[1]}' as a valid column type" %}
          {% end %}

          {% type_exists = false %}
          {% column_klass = nil %}
          {% for k in Marten::DB::Migration::Column::Base.all_subclasses %}
            {% ann = k.annotation(Marten::DB::Migration::Column::Registration) %}
            {% if ann && ann[:id] == sanitized_type %}
              {% type_exists = true %}
              {% column_klass = k %}
            {% end %}
          {% end %}
          {% unless type_exists %}
            {% raise "'#{sanitized_type}' is not a valid type for column '#{@type.id}##{sanitized_id}'" %}
          {% end %}

          {{ column_klass }}.new(
            {{ sanitized_id.stringify }},
            {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
          )
        end
      end
    end
  end
end
