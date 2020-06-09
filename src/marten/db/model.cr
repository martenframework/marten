module Marten
  module DB
    abstract class Model
      @@app_config : Marten::Apps::Config?
      @@table_name : String?

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
        QuerySet.new(self)
      end

      macro field(*args, **kwargs)
        {% if args.size != 2 %}{% raise "A field name and type must be explicitly specified" %}{% end %}

        {% sanitized_id = args[0].is_a?(StringLiteral) || args[0].is_a?(SymbolLiteral) ? args[0].id : nil %}
        {% if sanitized_id.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[0]}' as a valid field name" %}{% end %}

        {% sanitized_type = args[1].is_a?(StringLiteral) || args[1].is_a?(SymbolLiteral) ? args[1].id : nil %}
        {% if sanitized_type.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[1]}' as a valid field type" %}{% end %}

        register_field({{ sanitized_id.stringify }}, {{ sanitized_type.stringify }}, **{{ kwargs }})

        def {{ sanitized_id }}
        end
      end

      protected def self.register_field(id, type, **options)
        # Do something...
      end

      private def self.app_config
        @@app_config ||= begin
          config = Marten.apps.get_containing_model(self)

          if config.nil?
            raise Exception.new("Model class is not part of an application defined in Marten.settings.installed_apps")
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
