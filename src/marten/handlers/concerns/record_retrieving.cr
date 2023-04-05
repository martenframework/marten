module Marten
  module Handlers
    # Provides the ability to retrieve a specific model record.
    module RecordRetrieving
      macro included
        @@lookup_param : String? = nil

        # Returns the name of the model field that will be used to retrieve the record (defaults to `pk`).
        class_getter lookup_field : String = "pk"

        extend Marten::Handlers::RecordRetrieving::ClassMethods
      end

      module ClassMethods
        # Allows to configure the name of the model field that will be used to retrieve the record.
        def lookup_field(lookup_field : String | Symbol)
          @@lookup_field = lookup_field.to_s
        end

        # Returns the the name of the URL parameter containing the ID used to retrieve the record.
        #
        # By default, the lookup param name corresponds to the value returned by `#lookup_field`.
        def lookup_param : String
          @@lookup_param.nil? ? lookup_field : @@lookup_param.not_nil!
        end

        # Allows to configure the name of the URL parameter containing the ID used to retrieve the record.
        def lookup_param(lookup_param : String | Symbol)
          @@lookup_param = lookup_param.to_s
        end
      end

      # Allows to configure the model class that should be used to retrieve the record.
      macro model(model_klass)
        @record : {{ model_klass }}? = nil

        # Returns the model used to retrieve the record.
        def model
          {{ model_klass }}
        end

        # Returns the record that will be exposed by the handler.
        def record
          @record ||= queryset.get!(
            Marten::DB::Query::Node.new({self.class.lookup_field => params[self.class.lookup_param]})
          )
        rescue Marten::DB::Errors::RecordNotFound
          raise Marten::HTTP::Errors::NotFound.new(
            "No #{model.not_nil!.name} record can be found for the given query"
          )
        end
      end

      # Returns the model used to retrieve the record.
      def model
        raise_improperly_configured_model
      end

      # Returns the queryset used to retrieve the record displayed by the handler.
      def queryset
        model.all
      end

      # Returns the record that will be exposed by the handler.
      def record
        raise_improperly_configured_model
      end

      private def raise_improperly_configured_model
        raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a model class via the '::model' macro or by overriding the " \
          "'#model' method"
        )
      end
    end
  end
end
