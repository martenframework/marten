module Marten
  module DB
    abstract class Model
      module Table
        # :nodoc:
        annotation FieldInstanceVariable; end

        macro included
          @@table_name : String?
          @@fields : Hash(String, Field::Base) = {} of String => Field::Base
          @@fields_per_column : Hash(String, Field::Base) = {} of String => Field::Base
          @@relation_fields_per_relation_name : Hash(String, Field::Base)?

          extend Marten::DB::Model::Table::ClassMethods

          PRIMARY_KEY_ALIAS = "pk"

          macro inherited
            FIELDS_ = {} of Nil => Nil

            macro finished
              _verify_model_name
              _setup_primary_key
            end
          end
        end

        module ClassMethods
          # Returns the name of the table associated with the considered model.
          #
          # Unless explicitely specified, the table name is automatically generated based on the label of the app
          # associated with the considered model and the class name of the model.
          def table_name
            @@table_name ||= %{#{app_config.label.downcase}_#{name.gsub("::", "_").underscore}s}
          end

          # Allows to explicitely define the name of the table associated with the model.
          def table_name(table_name : String | Symbol)
            @@table_name = table_name.to_s
          end

          # :nodoc:
          def register_field(field : Field::Base)
            @@fields[field.id] = field
            @@fields_per_column[field.db_column] = field
          end

          protected def from_db_result_set(result_set : ::DB::ResultSet)
            obj = new
            obj.new_record = false
            obj.from_db_result_set(result_set)
            obj
          end

          protected def fields
            @@fields.values
          end

          protected def pk_field
            _pk_field
          end

          protected def get_field(id)
            @@fields.fetch(id) { raise Errors::UnknownField.new("Unknown field '#{id}'") }
          end

          protected def get_relation_field(relation_name)
            relation_fields_per_relation_name.fetch(relation_name) do
              raise Errors::UnknownField.new("Unknown relation field '#{relation_name}'")
            end
          end

          protected def fields_per_column
            @@fields_per_column
          end

          protected def relation_fields_per_relation_name
            @@relation_fields_per_relation_name ||= fields
              .select(&.relation?)
              .map { |field| [field.relation_name, field] }
              .to_h
          end

          private def _pk_field
            {% begin %}
            {%
              pkey = @type.instance_vars.find do |ivar|
                ann = ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable)
                ann && ann[:field_kwargs][:primary_key]
              end
            %}

            @@fields[{{ pkey.id.stringify }}]
            {% end %}
          end
        end

        macro field(*args, **kwargs)
          {% if args.size != 2 %}{% raise "A field name and type must be explicitly specified" %}{% end %}

          {% sanitized_id = args[0].is_a?(StringLiteral) || args[0].is_a?(SymbolLiteral) ? args[0].id : nil %}
          {% if sanitized_id.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[0]}' as a valid field name" %}{% end %}
          {% if sanitized_id.includes?(LOOKUP_SEP) %}
            {% raise "Cannot use '#{args[0]}' as a valid field name: field names cannot contain '#{LOOKUP_SEP.id}'" %}
          {% end %}

          {% sanitized_type = args[1].is_a?(StringLiteral) || args[1].is_a?(SymbolLiteral) ? args[1].id : nil %}
          {% if sanitized_type.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[1]}' as a valid field type" %}{% end %}

          {% type_exists = false %}
          {% field_klass = nil %}
          {% field_ann = nil %}
          {% for k in Marten::DB::Field::Base.all_subclasses %}
            {% ann = k.annotation(Marten::DB::Field::Registration) %}
            {% if ann && ann[:id] == sanitized_type %}
              {% type_exists = true %}
              {% field_klass = k %}
              {% field_ann = ann %}
            {% end %}
          {% end %}
          {% unless type_exists %}
            {% raise "'#{sanitized_type}' is not a valid type for field '#{@type.id}##{sanitized_id}'" %}
          {% end %}

          {% FIELDS_[sanitized_id.stringify] = kwargs %}

          {{ field_klass }}.check_definition(
            {{ sanitized_id }},
            {% unless kwargs.empty? %}{{ kwargs }}{% else %}nil{% end %}
          )

          {{ field_klass }}.contribute_to_model(
            {{ @type }},
            {{ sanitized_id }},
            {{ field_ann }},
            {% unless kwargs.empty? %}{{ kwargs }}{% else %}nil{% end %}
          )
        end

        # Allows to read the value of a specific field.
        #
        # This methods returns the value of the field corresponding to `field_name`. If the passed `field_name` doesn't
        # match any existing field, a `Marten::DB::Errors::UnknownField` exception is raised.
        def get_field_value(field_name : String | Symbol)
          {% begin %}
          case field_name.to_s
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
          when {{ field_var.name.stringify }}
            @{{ field_var.id }}
          {% end %}
          else
            raise Errors::UnknownField.new("Unknown field '#{field_name.to_s}'")
          end
          {% end %}
        end

        # Allows to set the value of a specific field.
        #
        # If the passed `field_name` doesn't match any existing field, a `Marten::DB::Errors::UnknownField` exception
        # will be raised.
        def set_field_value(field_name : String | Symbol, value : Field::Any)
          {% begin %}
          case field_name.to_s
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
          when {{ field_var.name.stringify }}
            if !value.is_a?({{ field_var.type }})
              raise Errors::UnexpectedFieldValue.new(
                "Value for field {{ field_var.id }} should be of type {{ field_var.type }}, not #{typeof(value)}"
              )
            end
            self.{{ field_var.id }} = value
          {% end %}
          else
            raise Errors::UnknownField.new("Unknown field '#{field_name.to_s}'")
          end
          {% end %}
        end

        def to_s(io)
          inspect(io)
        end

        def inspect(io)
          io << "#<#{self.class.name}:0x#{object_id.to_s(16)} "
          io << "#{self.class.pk_field.id}: #{pk.inspect}"
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
          {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
          {% unless ann[:field_kwargs] && ann[:field_kwargs][:primary_key] %}
          io << ", "
          io << {{ field_var.name.stringify }} + ": #{@{{ field_var.id }}.inspect}"
          {% end %}
          {% end %}
          io << ">"
        end

        protected def from_db_result_set(result_set : ::DB::ResultSet)
          result_set.column_names.each do |column_name|
            assign_field_from_db_result_set(result_set, column_name)
          end
        end

        protected def assign_field_from_db_result_set(result_set : ::DB::ResultSet, column_name : String)
          {% begin %}
          field = self.class.fields_per_column[column_name]?
          return if field.nil?
          case field.as(Field::Base).id
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
          {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
          when {{ field_var.name.stringify }}
          @{{ field_var.id }} = field.as({{ ann[:field_klass] }}).from_db_result_set(result_set)
          {% end %}
          else
          end
          {% end %}
        end

        protected def field_values
          values = {} of String => Field::Any
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
            field = self.class.get_field({{ field_var.name.stringify }})
            values[field.db_column] = {{ field_var.id }}
          {% end %}
          values
        end

        private def assign_field_values(values : Hash(String, Field::Any))
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
            if values.has_key?({{field_var.name.stringify}})
              value = values[{{field_var.name.stringify}}]
              if !value.is_a?({{ field_var.type }})
                raise Errors::UnexpectedFieldValue.new(
                  "Value for field {{ field_var.id }} should be of type {{ field_var.type }}, not #{typeof(value)}"
                )
              end
              self.{{ field_var.id }} = value
              values.delete({{field_var.name.stringify}})
            end
          {% end %}

          unless values.empty?
            raise Errors::UnknownField.new("Unknown field '#{values.first[0]}' for #{self.class.name}")
          end
        end

        private def field_db_values
          values = {} of String => ::DB::Any
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
            field = self.class.get_field({{ field_var.name.stringify }})
            values[field.db_column] = field.to_db(@{{ field_var.id }})
          {% end %}
          values
        end

        # :nodoc:
        macro _verify_model_name
          {% if @type.id.includes?(LOOKUP_SEP) %}
            {% raise "Cannot use '#{@type.id}' as a valid model name: model names cannot contain '#{LOOKUP_SEP.id}'" %}
          {% end %}
        end

        # :nodoc:
        macro _setup_primary_key
          {% pkeys = [] of StringLiteral %}
          {% for id, kwargs in FIELDS_ %}
            {% if kwargs && kwargs[:primary_key] %}{% pkeys << id %}{% end %}
          {% end %}

          {% if pkeys.size == 0 %}{{ raise "No primary key found for model '#{@type}'" }}{% end %}
          {% if pkeys.size > 1 %}
            {{ raise "Many primary keys found for model '#{@type}' ; only one is allowed" }}
          {% end %}

          def pk
            {{ pkeys[0].id }}
          end

          def pk=(val)
            self.{{ pkeys[0].id }} = val
          end
        end
      end
    end
  end
end
