module Marten
  module DB
    abstract class Model
      annotation FieldInstanceVariable; end

      LOOKUP_SEP = "__"
      PRIMARY_KEY_ALIAS = "pk"

      @@app_config : Marten::Apps::Config?
      @@fields : Hash(String, Field::Base) = {} of String => Field::Base
      @@table_name : String?

      # :nodoc:
      @new_record : Bool = true

      def self.table_name
        @@table_name ||= %{#{app_config.label.downcase}_#{name.gsub("::", "_").underscore}s}
      end

      def self.table_name(table_name : String | Symbol)
        @@table_name = table_name.to_s
      end

      def self.connection
        Connection.for(table_name)
      end

      def self.all
        QuerySet(self).new
      end

      def self.filter(**kwargs)
        QuerySet(self).new.filter(**kwargs)
      end

      def self.filter(&block)
        expr = Expression::Filter(self).new
        query : QueryNode(self) = with expr yield
        QuerySet(self).new.filter(query)
      end

      def self.exclude(**kwargs)
        QuerySet(self).new.exclude(**kwargs)
      end

      def self.exclude(&block)
        expr = Expression::Filter(self).new
        query : QueryNode(self) = with expr yield
        QuerySet(self).new.exclude(query)
      end

      def self.get(**kwargs)
        QuerySet(self).new.get(**kwargs)
      end

      def initialize(**kwargs)
        assign_field_values(kwargs.to_h.transform_keys(&.to_s))
      end

      def initialize
      end

      def self.first
        QuerySet(self).new.first
      end

      def self.last
        QuerySet(self).new.last
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

        register_field({{ sanitized_id.stringify }}, {{ sanitized_type.stringify }}, **{{ kwargs }})

        @[Marten::DB::Model::FieldInstanceVariable(
          field_klass: {{ field_klass }},
          field_kwargs: {{ kwargs }},
          field_type: {{ field_ann[:exposed_type] }}
        )]
        @{{ sanitized_id }} : {{ field_ann[:exposed_type] }}?

        def {{ sanitized_id }} : {{ field_ann[:exposed_type] }}?
         @{{ sanitized_id }}
        end

        def {{ sanitized_id }}!
         @{{ sanitized_id }}.not_nil!
        end

        def {{ sanitized_id }}=(@{{ sanitized_id }} : {{ field_ann[:exposed_type] }}?); end
      end

      protected setter new_record

      protected def self.from_db_result_set(result_set : ::DB::ResultSet)
        obj = new
        obj.new_record = false
        obj.from_db_result_set(result_set)
        obj
      end

      protected def self.register_field(id, type, **options)
        field_klass = Field.registry[type]
        @@fields[id] = field_klass.not_nil!.new(id, **options)
      end

      protected def self.fields
        @@fields.values
      end

      protected def self.pk_field
        {% begin %}
        {%
          pkey = @type.instance_vars.find do |ivar|
            ann = ivar.annotation(Marten::DB::Model::FieldInstanceVariable)
            ann && ann[:field_kwargs][:primary_key]
          end
        %}

        @@fields[{{ pkey.id.stringify }}]
        {% end %}
      end

      protected def self.get_field(id)
        @@fields.fetch(id) { raise Errors::UnknownField.new("Unknown field '#{id}'") }
      end

      protected def from_db_result_set(result_set : ::DB::ResultSet)
        {% begin %}
        result_set.column_names.each do |column_name|
          field = @@fields.fetch(column_name, nil)
          next if field.nil?
          case column_name
          {% for field_var in @type.instance_vars
            .select { |ivar| ivar.annotation(Marten::DB::Model::FieldInstanceVariable) } %}
          {% ann = field_var.annotation(Marten::DB::Model::FieldInstanceVariable) %}
          when {{ field_var.name.stringify }}
            @{{ field_var.id }} = field.as({{ ann[:field_klass] }}).from_db_result_set(result_set)
          {% end %}
          else
          end
        end
        {% end %}
      end

      private def self.app_config
        @@app_config ||= begin
          config = Marten.apps.get_containing_model(self)

          if config.nil?
            raise "Model class is not part of an application defined in Marten.settings.installed_apps"
          end

          config.not_nil!
        end
      end

      private def assign_field_values(values : Hash(String, Field::Any))
        {% for field_var in @type.instance_vars
          .select { |ivar| ivar.annotation(Marten::DB::Model::FieldInstanceVariable) } %}
          if values.has_key?({{field_var.name.stringify}})
            value = values[{{field_var.name.stringify}}]
            if !value.is_a?({{ field_var.type }})
              raise Errors::UnexpectedFieldValue.new(
                "Value for field {{ field_var.id }} should of type {{ field_var.type }}, not #{typeof(value)}"
              )
            end
            @{{ field_var.id }} = value
          end
        {% end %}
      end

      macro inherited
        class NotFound < Marten::DB::Errors::RecordNotFound; end

        def self.dir_location
          __DIR__
        end

        FIELDS_ = {} of Nil => Nil

        macro finished
          _verify_model_name
          _setup_primary_key
        end
      end

      macro _verify_model_name
        {% if @type.id.includes?(LOOKUP_SEP) %}
          {% raise "Cannot use '#{@type.id}' as a valid model name: model names cannot contain '#{LOOKUP_SEP.id}'" %}
        {% end %}
      end

      macro _setup_primary_key
        {% pkeys = [] of StringLiteral %}
        {% for id, kwargs in FIELDS_ %}
          {% if kwargs[:primary_key] %}{% pkeys << id %}{% end %}
        {% end %}

        {% if pkeys.size == 0 %}{{ raise "No primary key found for model '#{@type}'" }}{% end %}
        {% if pkeys.size > 1 %}{{ raise "Many primary keys found for model '#{@type}' ; only one is allowed" }}{% end %}

        def pk
          {{ pkeys[0].id }}
        end
      end
    end
  end
end
