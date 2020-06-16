module Marten
  module DB
    abstract class Model
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

      macro field(*args, **kwargs)
        {% if args.size != 2 %}{% raise "A field name and type must be explicitly specified" %}{% end %}

        {% sanitized_id = args[0].is_a?(StringLiteral) || args[0].is_a?(SymbolLiteral) ? args[0].id : nil %}
        {% if sanitized_id.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[0]}' as a valid field name" %}{% end %}

        {% sanitized_type = args[1].is_a?(StringLiteral) || args[1].is_a?(SymbolLiteral) ? args[1].id : nil %}
        {% if sanitized_type.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[1]}' as a valid field type" %}{% end %}

        {% type_exists = false %}
        {% for field_klass in Marten::DB::Field::Base.all_subclasses %}
          {% field_ann = field_klass.annotation(Marten::DB::Field::Registration) %}
          {% if field_ann && field_ann[:field_id] == sanitized_type %}
            {% type_exists = true %}
          {% end %}
        {% end %}
        {% unless type_exists %}
          {% raise "'#{sanitized_type}' is not a valid type for field '#{@type.id}##{sanitized_id}'" %}
        {% end %}

        register_field({{ sanitized_id.stringify }}, {{ sanitized_type.stringify }}, **{{ kwargs }})

        def {{ sanitized_id }}
        end
      end

      protected setter new_record

      protected def self.from_db_result_set(result_set : ::DB::ResultSet)
        obj = new
        obj.new_record = false
        obj.from_db_result_set(result_set)
        obj
      end

      protected def self.register_field(id, type, **options)
        field_klass = Field.registry.fetch(type, nil)
        raise "Unknown model field type '#{type}' for field '#{id}'" if field_klass.nil?

        # TODO: handle fields registered more than once.
        # TODO: handle fields inheritance.

        @@fields[id] = field_klass.not_nil!.new(id, **options)
      end

      protected def self.fields
        @@fields.values
      end

      protected def from_db_result_set(result_set : ::DB::ResultSet)
        result_set.column_names.each do |column_name|
          field = @@fields.fetch(column_name, nil)
          next if field.nil?
          # assign... field.from_db_result_set(result_set)
        end
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

      macro inherited
        def self.dir_location
          __DIR__
        end
      end
    end
  end
end
