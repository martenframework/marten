module Marten
  module DB
    abstract class Model
      module Table
        # :nodoc:
        annotation FieldInstanceVariable; end

        macro included
          LOOKUP_SEP = {{ Marten::DB::Constants::LOOKUP_SEP }}

          @@db_table : String?
          @@fields : Hash(String, Field::Base) = {} of String => Field::Base
          @@fields_per_column : Hash(String, Field::Base) = {} of String => Field::Base
          @@relation_fields_per_relation_name : Hash(String, Field::Base) = {} of String => Field::Base
          @@reverse_relations : Array(ReverseRelation) = [] of ReverseRelation

          extend Marten::DB::Model::Table::ClassMethods

          macro inherited
            FIELDS_ = {} of Nil => Nil

            # Reset table-related class variables upon inheritance.
            # TODO: model class inheritance.
            @@fields = {} of String => Marten::DB::Field::Base
            @@fields_per_column = {} of String => Marten::DB::Field::Base
            @@relation_fields_per_relation_name = {} of String => Marten::DB::Field::Base
            @@reverse_relations = [] of Marten::DB::ReverseRelation

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
          def db_table
            @@db_table ||= String.build do |s|
              s << app_config.label.downcase
              s << '_'
              s << (model_name = name.gsub("::", "_").underscore)
              s << 's' unless model_name.ends_with?('s')
            end
          end

          # Allows to explicitely define the name of the table associated with the model.
          def db_table(db_table : String | Symbol)
            @@db_table = db_table.to_s
          end

          # Returns all the fields instances associated with the current model.
          def fields
            @@fields.values
          end

          # Allows to retrieve a specific field instance associated with the current model.
          #
          # The returned object will be an instance of a subclass of `Marten::DB::Field::Base`.
          def get_field(id : String | Symbol)
            @@fields.fetch(id.to_s) do
              @@relation_fields_per_relation_name.fetch(id.to_s) do
                raise Errors::UnknownField.new("Unknown field '#{id}'")
              end
            end
          end

          # :nodoc:
          def register_field(field : Field::Base)
            @@fields[field.id] = field
            @@fields_per_column[field.db_column!] = field if field.db_column?
            @@relation_fields_per_relation_name[field.relation_name] = field if field.relation?
          end

          # :nodoc:
          def register_reverse_relation(reverse_relation : ReverseRelation)
            @@reverse_relations << reverse_relation
          end

          protected def fields_per_column
            @@fields_per_column
          end

          protected def from_db_row_iterator(row_iterator : Query::SQL::RowIterator)
            obj = new
            obj.new_record = false
            obj.from_db_row_iterator(row_iterator)
            obj
          end

          protected def get_relation_field(relation_name)
            @@relation_fields_per_relation_name.fetch(relation_name) do
              raise Errors::UnknownField.new("Unknown relation field '#{relation_name}'")
            end
          end

          protected def pk_field
            _pk_field
          end

          protected def reverse_relations
            @@reverse_relations
          end

          private def _pk_field
            {% begin %}
            {%
              pkey = @type.instance_vars.find do |ivar|
                ann = ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable)
                ann && ann[:field_kwargs] && ann[:field_kwargs][:primary_key]
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
          {% if sanitized_id.stringify.includes?(LOOKUP_SEP) %}
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

        def self.db_unique_constraint(fields : Array(String) | Array(Symbol), name : String | Symbol) : Nil
          # @unique_constraints << Constraint::Unique.new(...)
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

        protected def from_db_row_iterator(row_iterator : Query::SQL::RowIterator)
          row_iterator.each_local_column do |result_set, column_name|
            assign_field_from_db_result_set(result_set, column_name)
          end

          row_iterator.each_joined_relation do |relation_row_iterator, relation_field|
            if get_field_value(relation_field.id).nil?
              # In that case the local relation field (relation ID, likely) is nil, which means that we need to
              # "advance" the row cursor so that the next relation can be correctly picked up afterwards.
              relation_row_iterator.advance
            else
              related_object = relation_field.related_model.from_db_row_iterator(relation_row_iterator)
              assign_related_object(related_object, relation_field.id)
            end
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
          self.{{ field_var.id }} = field.as({{ ann[:field_klass] }}).from_db_result_set(result_set)
          {% end %}
          else
          end
          {% end %}
        end

        protected def assign_related_object(related_object, relation_field_id)
          {% begin %}
          case relation_field_id
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
          {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
          {% if ann && ann[:relation_name] %}
          when {{ field_var.name.stringify }}
            if !related_object.nil? && !related_object.is_a?({{ ann[:related_model] }})
              raise Errors::UnexpectedFieldValue.new(
                "Value for relation {{ ann[:relation_name] }} should be of type {{ ann[:related_model] }}, " \
                "not #{typeof(related_object)}"
              )
            end
            self.{{ ann[:relation_name] }} = related_object.as({{ ann[:related_model] }}?)
          {% end %}
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
            values[field.db_column!] = {{ field_var.id }} if field.db_column?
          {% end %}
          values
        end

        private def assign_field_values(values : Hash(String, Field::Any | Model))
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
            if values.has_key?({{ field_var.name.stringify }})
              value = values[{{ field_var.name.stringify }}]
              if !value.is_a?({{ field_var.type }})
                raise Errors::UnexpectedFieldValue.new(
                  "Value for field {{ field_var.id }} should be of type {{ field_var.type }}, not #{typeof(value)}"
                )
              end
              self.{{ field_var.id }} = value
              values.delete({{field_var.name.stringify}})
            end

            {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
            {% if ann && ann[:relation_name] %}
              if values.has_key?({{ ann[:relation_name].stringify }})
                value = values[{{ ann[:relation_name].stringify }}]
                assign_related_object(value, {{ field_var.id.stringify }})
                values.delete({{ ann[:relation_name].stringify }})
              end
            {% end %}
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
            values[field.db_column!] = field.to_db(@{{ field_var.id }}) if field.db_column?
          {% end %}
          values
        end

        private def get_cached_related_object(relation_field)
          {% begin %}
          case relation_field.id
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
          {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
          {% if ann && ann[:relation_name] %}
          when {{ field_var.name.stringify }}
            @{{ ann[:relation_name] }}
          {% end %}
          {% end %}
          else
          end
          {% end %}
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

          def pk!
            {{ pkeys[0].id }}.not_nil!
          end

          def pk=(val)
            self.{{ pkeys[0].id }} = val
          end
        end
      end
    end
  end
end
