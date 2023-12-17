require "./table/**"

module Marten
  module DB
    abstract class Model
      module Table
        # :nodoc:
        annotation FieldInstanceVariable; end

        # :nodoc:
        annotation RelationInstanceVariable; end

        macro included
          LOOKUP_SEP = {{ Marten::DB::Constants::LOOKUP_SEP }}

          @@db_indexes : Array(Index) = [] of Index
          @@db_table : String?
          @@db_unique_constraints : Array(Constraint::Unique) = [] of Constraint::Unique
          @@field_contexts_map : Hash(String, FieldContext) | Nil = nil
          @@local_fields : Hash(String, Field::Base) = {} of String => Field::Base
          @@local_fields_per_column : Hash(String, Field::Base) = {} of String => Field::Base
          @@local_relation_fields_per_relation_name : Hash(String, Field::Base) = {} of String => Field::Base
          @@local_reverse_relations : Array(ReverseRelation) = [] of ReverseRelation
          @@parent_models : Array(Marten::DB::Model.class) = [] of Marten::DB::Model.class
          @@reverse_relation_contexts : Array(ReverseRelationContext) | Nil = nil

          extend Marten::DB::Model::Table::ClassMethods

          macro inherited
            FIELDS_ = {} of Nil => Nil

            _reset_table_attributes
            _inherit_table_attributes

            macro finished
              _verify_model_name
              _setup_primary_key
            end
          end
        end

        module ClassMethods
          # Allows to explicitly configure a new index for a specific set of fields.
          #
          # This method allows to configure a new index targetting a specific set of `fields`. Indexes must be
          # associated with a mandatory `name` that must be unique accross all the indexes of the considered model.
          def db_index(name : String | Symbol, field_names : Array(String) | Array(Symbol)) : Nil
            @@db_indexes << Index.new(
              name.to_s,
              field_names.map do |fname|
                get_field(fname.to_s)
              rescue Errors::UnknownField
                raise Errors::UnknownField.new("Unknown field '#{fname}' in index definition")
              end
            )
          end

          # Returns the configured database indexes.
          def db_indexes
            @@db_indexes
          end

          # Returns the name of the table associated with the considered model.
          #
          # Unless explicitely specified, the table name is automatically generated based on the label of the app
          # associated with the considered model and the class name of the model.
          def db_table
            @@db_table ||= String.build do |s|
              s << app_config.label.downcase
              s << '_'
              s << (model_name = name.split("::").last.underscore)
            end
          end

          # Allows to explicitely define the name of the table associated with the model.
          def db_table(db_table : String | Symbol)
            @@db_table = db_table.to_s
          end

          # Allows to explicitly configure a new unique constraint for a specific set of fields.
          #
          # This method allows to configure a new unique constraint targetting a specific set of `fields`. Unique
          # constraints must be associated with a mandatory `name` that must be unique accross all the constraints of
          # the considered model.
          def db_unique_constraint(name : String | Symbol, field_names : Array(String) | Array(Symbol)) : Nil
            @@db_unique_constraints << Constraint::Unique.new(
              name.to_s,
              field_names.map do |fname|
                get_field(fname.to_s)
              rescue Errors::UnknownField
                raise Errors::UnknownField.new("Unknown field '#{fname}' in unique constraint definition")
              end
            )
          end

          # Returns the configured unique database constraints.
          def db_unique_constraints
            @@db_unique_constraints
          end

          # Returns all the fields instances associated with the current model.
          #
          # It is worth mentioning that this method will return all the fields of the considered model: the local model
          # fields and model fields from parent classes.
          def fields
            field_contexts_map.values.map(&.field).uniq!
          end

          # Allows to retrieve a specific field instance associated with the current model.
          #
          # The returned object will be an instance of a subclass of `Marten::DB::Field::Base`. It is worth mentioning
          # that this method will return local model fields as well as parent model fields.
          def get_field(id : String | Symbol) : Field::Base
            get_field_context(id).field
          end

          # Allows to retrieve a specific field instance associated with the current model.
          #
          # The returned object will be an instance of a subclass of `Marten::DB::Field::Base`. It is worth mentioning
          # that this method will return local model fields only.
          def get_local_field(id : String | Symbol) : Field::Base
            @@local_fields.fetch(id.to_s) do
              @@local_relation_fields_per_relation_name.fetch(id.to_s) do
                raise Errors::UnknownField.new("Unknown field '#{id}'")
              end
            end
          end

          # Returns all the local fields instances associated with the current model.
          def local_fields
            @@local_fields.values
          end

          # Returns the parent models.
          def parent_models
            @@parent_models
          end

          # :nodoc:
          def register_field(field : Field::Base)
            @@local_fields[field.id] = field
            @@local_fields_per_column[field.db_column!] = field if field.db_column?
            @@local_relation_fields_per_relation_name[field.relation_name] = field if field.relation?
          end

          # :nodoc:
          def register_reverse_relation(reverse_relation : ReverseRelation)
            @@local_reverse_relations << reverse_relation
          end

          protected def local_fields_per_column
            @@local_fields_per_column
          end

          protected def local_fields_per_id
            @@local_fields
          end

          protected def local_relation_fields_per_relation_name
            @@local_relation_fields_per_relation_name
          end

          protected def from_db_row_iterator(row_iterator : Query::SQL::RowIterator)
            obj = new
            obj.new_record = false
            obj.from_db_row_iterator(row_iterator)
            obj
          end

          protected def get_field_context(id : String | Symbol) : FieldContext
            field_contexts_map.fetch(id.to_s) do
              raise Errors::UnknownField.new("Unknown field '#{id}'")
            end
          end

          protected def get_local_relation_field(relation_name : String | Symbol) : Field::Base
            @@local_relation_fields_per_relation_name.fetch(relation_name.to_s) do
              raise Errors::UnknownField.new("Unknown relation field '#{relation_name}'")
            end
          end

          protected def get_relation_field_context(relation_name : String | Symbol) : FieldContext
            field_context = field_contexts_map[relation_name.to_s]?

            if field_context.nil? || !field_context.field.relation?
              raise Errors::UnknownField.new("Unknown relation field '#{relation_name}'")
            end

            field_context
          end

          protected def get_reverse_relation_context(relation_name : String | Symbol) : Nil | ReverseRelationContext
            reverse_relation_contexts.find do |r|
              r.reverse_relation.id == relation_name.to_s
            end
          end

          protected def local_reverse_relations
            @@local_reverse_relations
          end

          protected def parent_fields
            parent_models.compact_map do |parent_model|
              if (f = pk_field).is_a?(Field::OneToOne) && f.parent_link?
                pk_field
              end
            end
          end

          protected def pk_field
            _pk_field
          end

          protected def reverse_relations
            reverse_relation_contexts.map(&.reverse_relation).uniq!
          end

          private def field_contexts_map
            @@field_contexts_map ||= begin
              map = {} of String => FieldContext

              @@parent_models.each do |parent_model|
                parent_model.local_fields.each { |f| map[f.id] = FieldContext.new(f, parent_model) }
                parent_model.local_relation_fields_per_relation_name.each do |k, v|
                  map[k] = FieldContext.new(v, parent_model)
                end
              end

              @@local_relation_fields_per_relation_name.each { |k, v| map[k] = FieldContext.new(v, self) }
              @@local_fields.values.each { |f| map[f.id] = FieldContext.new(f, self) }

              map
            end
          end

          private def reverse_relation_contexts
            @@reverse_relation_contexts ||= begin
              contexts = [] of ReverseRelationContext

              @@parent_models.each do |parent_model|
                parent_model.local_reverse_relations.each do |r|
                  contexts << ReverseRelationContext.new(r, parent_model)
                end
              end

              @@local_reverse_relations.each { |r| contexts << ReverseRelationContext.new(r, self) }

              contexts
            end
          end

          private def _pk_field
            {% begin %}
            {%
              pkey = @type.instance_vars.find do |ivar|
                ann = ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable)
                ann && ann[:model_klass].id == @type.name.id && ann[:field_kwargs] && ann[:field_kwargs][:primary_key]
              end
            %}

            @@local_fields[{{ pkey.id.stringify }}]
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

          {% FIELDS_[sanitized_id.stringify] = {type: sanitized_type.stringify, kwargs: kwargs} %}

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

        # Allows to automatically configure creation and update timestamp fields.
        #
        # This macro will contribute two model fields to the models it is applied to: one `created_at` field containing
        # the creation time of the record, and one `updated_at` field containing the update time of the record (which is
        # also refreshed every time the model is updated).
        macro with_timestamp_fields
          field :created_at, :date_time, auto_now_add: true
          field :updated_at, :date_time, auto_now: true
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
            {{ field_var.id }}
          {% end %}
          else
            raise Errors::UnknownField.new("Unknown field '#{field_name.to_s}'")
          end
          {% end %}
        end

        # Allows to return the record associated with a specific relation name.
        #
        # If no record is associated with the specified relation (eg. if the corresponding field is nullable), then
        # `nil` is returned. If the specified relation name is not defined on the model, then a
        # `Marten::DB::Errors::UnknownField` exception is raised.
        def get_relation(relation_name : String | Symbol)
          {% begin %}
          case relation_name.to_s
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
          {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
          {% if ann && ann[:relation_name] %}
          when {{ ann[:relation_name].stringify }}
            {{ ann[:relation_name] }}
          {% end %}
          {% end %}
          else
            raise Errors::UnknownField.new("Unknown relation '#{relation_name.to_s}'")
          end
          {% end %}
        end

        # Returns the primary key value.
        def pk
          {% begin %}
          {%
            pkey = @type.instance_vars.find do |ivar|
              ann = ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable)
              ann && ann[:model_klass].id == @type.name.id && ann[:field_kwargs] && ann[:field_kwargs][:primary_key]
            end
          %}

          {% if pkey %}self.{{ pkey.id }}{% end %}
          {% end %}
        end

        # Returns true if a primary key value is set on the record.
        def pk? : Bool
          self.class.pk_field.getter_value?(pk)
        end

        # Returns the primary key value or raise `NilAssertionError`.
        def pk!
          pk.not_nil!
        end

        # Allows to set the primary key value.
        def pk=(val)
          set_field_value(self.class.pk_field.id, val)
        end

        # Allows to set the value of a specific field.
        #
        # If the passed `field_name` doesn't match any existing field, a `Marten::DB::Errors::UnknownField` exception
        # will be raised.
        def set_field_value(field_name : String | Symbol, value : Field::Any | Model)
          sanitized_values = Hash(String, Field::Any | Model).new
          sanitized_values[field_name.to_s] = value
          assign_field_values(sanitized_values)
        end

        # Allows to set the values of multiple fields.
        #
        # If one of the specified field names doesn't match any existing field, a `Marten::DB::Errors::UnknownField`
        # exception will be raised.
        def set_field_values(**values)
          set_field_values(values)
        end

        # :ditto:
        def set_field_values(values : Hash | NamedTuple)
          sanitized_values = Hash(String, Field::Any | Model).new
          values.each { |key, value| sanitized_values[key.to_s] = value }
          assign_field_values(sanitized_values)
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
          io << {{ field_var.name.stringify }} + ": #{{{ field_var.id }}.inspect}"
          {% end %}
          {% end %}
          io << ">"
        end

        protected def assign_local_field_from_db_result_set(result_set : ::DB::ResultSet, column_name : String)
          {% begin %}
          field = self.class.local_fields_per_column[column_name]?
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

        protected def assign_parent_model_field_from_db_result_set(
          parent_model : Model.class,
          result_set : ::DB::ResultSet,
          column_name : String
        )
          {% begin %}
          field = parent_model.local_fields_per_column[column_name]?
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

        protected def assign_reverse_related_object(related_object, relation_field_id)
          {% begin %}
          case relation_field_id
          {% for relation_var in @type.instance_vars
                                   .select { |ivar| ivar.annotation(Marten::DB::Model::Table::RelationInstanceVariable) } %} # ameba:disable Layout/LineLength
          {% ann = relation_var.annotation(Marten::DB::Model::Table::RelationInstanceVariable) %}
          {% if ann && ann[:relation_name] %}
          when {{ ann[:relation_name].stringify }}
            if !related_object.nil? && !related_object.is_a?({{ ann[:related_model] }})
              raise Errors::UnexpectedFieldValue.new(
                "Value for relation {{ ann[:relation_name] }} should be of type {{ ann[:related_model] }}, " \
                "not #{typeof(related_object)}"
              )
            end
            @{{ relation_var.name }} = related_object.as({{ ann[:related_model] }}?)
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

        protected def from_db_row_iterator(row_iterator : Query::SQL::RowIterator)
          row_iterator.each_local_column do |result_set, column_name|
            assign_local_field_from_db_result_set(result_set, column_name)
          end

          row_iterator.each_parent_column do |parent_model, result_set, column_name|
            assign_parent_model_field_from_db_result_set(parent_model, result_set, column_name)
          end

          row_iterator.each_joined_relation do |relation_row_iterator, relation_field, reverse_relation|
            if reverse_relation.nil?
              if get_field_value(relation_field.id).nil?
                # In that case the local relation field (relation ID, likely) is nil, which means that we need to
                # "advance" the row cursor so that the next relation can be correctly picked up afterwards.
                relation_row_iterator.advance
              else
                related_object = relation_field.related_model.from_db_row_iterator(relation_row_iterator)
                assign_related_object(related_object, relation_field.id)
              end
            else
              related_object = reverse_relation.model.from_db_row_iterator(relation_row_iterator)

              # Only assign the retrieved object if it is persisted (ie. if it has a primary key value). If that's not
              # then case, then this means that current record does not have a reverse related object.
              assign_reverse_related_object(related_object, reverse_relation.id) if related_object.pk?
            end
          end
        end

        private def assign_field_values(values : Hash(String, Field::Any | Model))
          {% for field_var in @type.instance_vars
                                .select { |ivar| ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable) } %}
            {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
            if values.has_key?({{ field_var.name.stringify }})
              value = values[{{ field_var.name.stringify }}]
              if !value.is_a?(
                {{ field_var.type }}{% if ann[:field_type] %} | {{ ann[:field_type] }}{% end %}
              )
                raise Errors::UnexpectedFieldValue.new(
                  "Value for field {{ field_var.id }} should be of type {{ field_var.type }}, not #{typeof(value)}"
                )
              end
              self.{{ field_var.id }} = value
              values.delete({{field_var.name.stringify}})
            end

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

        private def local_field_db_values
          {% begin %}
          values = {} of String => ::DB::Any

          {%
            local_field_vars = @type.instance_vars.select do |ivar|
              ann = ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable)
              ann && ann[:model_klass].id == @type.name.id
            end
          %}

          {% for field_var in local_field_vars %}
            field = self.class.get_field({{ field_var.name.stringify }})
            values[field.db_column!] = field.to_db({{ field_var.id }}) if field.db_column?
          {% end %}

          values
          {% end %}
        end

        private def parent_model_field_db_values(model_klass)
          {% begin %}
          values = {} of String => ::DB::Any

          {%
            local_field_vars = @type.instance_vars.select do |ivar|
              ivar.annotation(Marten::DB::Model::Table::FieldInstanceVariable)
            end
          %}

          {% for field_var in local_field_vars %}
            {% ann = field_var.annotation(Marten::DB::Model::Table::FieldInstanceVariable) %}
            if model_klass.name == {{ ann[:model_klass].id.stringify }}
              field = {{ ann[:model_klass].id }}.get_field({{ field_var.name.stringify }})
              values[field.db_column!] = field.to_db({{ field_var.id }}) if field.db_column?
            end
          {% end %}

          values
          {% end %}
        end

        private def reset_relation_instance_variables : Nil
          {% for field_var in @type.instance_vars.select { |ivar| ivar.annotation(Marten::DB::Model::Table::RelationInstanceVariable) } %} # ameba:disable Layout/LineLength
            @{{ field_var.id }} = nil
          {% end %}
        end

        # :nodoc:
        macro _inherit_table_attributes
          {% ancestor_model = @type.ancestors.first %}

          {% if ancestor_model.has_constant?("FIELDS_") %}
            {% if ancestor_model.abstract? %}
              {% for field_id, field_config in ancestor_model.constant("FIELDS_") %}
                {% FIELDS_[field_id] = field_config %}

                {% field_klass = nil %}
                {% field_ann = nil %}
                {% for k in Marten::DB::Field::Base.all_subclasses %}
                  {% ann = k.annotation(Marten::DB::Field::Registration) %}
                  {% if ann && ann[:id] == field_config[:type] %}
                    {% field_klass = k %}
                    {% field_ann = ann %}
                  {% end %}
                {% end %}

                {{ field_klass }}.contribute_to_model(
                  {{ @type }},
                  {{ field_id.id }},
                  {{ field_ann }},
                  {% unless field_config[:kwargs].empty? %}{{ field_config[:kwargs] }}{% else %}nil{% end %}
                )
              {% end %}

              @@db_indexes = {{ ancestor_model.name }}.db_indexes.clone
              @@db_unique_constraints = {{ ancestor_model.name }}.db_unique_constraints.clone
            {% else %}
              @@parent_models = [{{ ancestor_model }}] + {{ ancestor_model }}.parent_models

              {% for field_id, field_config in ancestor_model.constant("FIELDS_") %}
                {% if field_config[:kwargs][:primary_key] %}
                  field(
                    :{{ ancestor_model.name.split("::").last.underscore.id }}_ptr,
                    :one_to_one,
                    to: {{ ancestor_model.name }},
                    primary_key: true,
                    parent_link: true,
                    on_delete: :cascade,
                    related: {{ @type.name.stringify.split("::").last.underscore }}
                  )
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        end

        # :nodoc:
        macro _reset_table_attributes
          @@db_indexes = [] of Marten::DB::Index
          @@db_table = nil
          @@db_unique_constraints = [] of Marten::DB::Constraint::Unique
          @@field_contexts_map = nil
          @@local_fields = {} of ::String => Marten::DB::Field::Base
          @@local_fields_per_column = {} of ::String => Marten::DB::Field::Base
          @@local_relation_fields_per_relation_name = {} of ::String => Marten::DB::Field::Base
          @@local_reverse_relations = [] of Marten::DB::ReverseRelation
          @@parent_models : Array(Marten::DB::Model.class) = [] of Marten::DB::Model.class
          @@reverse_relation_contexts = nil
        end

        # :nodoc:
        macro _setup_primary_key
          {% pkeys = [] of StringLiteral %}
          {% for id, config in FIELDS_ %}
            {% if config[:kwargs] && config[:kwargs][:primary_key] %}{% pkeys << id %}{% end %}
          {% end %}

          {% if pkeys.size == 0 && !@type.abstract? %}{{ raise "No primary key found for model '#{@type}'" }}{% end %}
          {% if pkeys.size > 1 %}
            {{ raise "Many primary keys found for model '#{@type}' ; only one is allowed" }}
          {% end %}
        end

        # :nodoc:
        macro _verify_model_name
          {% if @type.id.includes?(LOOKUP_SEP) %}
            {% raise "Cannot use '#{@type.id}' as a valid model name: model names cannot contain '#{LOOKUP_SEP.id}'" %}
          {% end %}
        end
      end
    end
  end
end
