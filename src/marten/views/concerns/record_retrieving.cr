module Marten
  module Views
    # Provides the ability to retrieve a specific model record.
    module RecordRetrieving
      macro included
        @@lookup_param : String? = nil

        @record : DB::Model? = nil

        # Returns the name of the model field that will be used to retrieve the record (defaults to `pk`).
        class_getter lookup_field : String = "pk"

        # Returns the configured model class.
        class_getter model : DB::Model.class | Nil

        extend Marten::Views::RecordRetrieving::ClassMethods
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

        # Allows to configure the model class that should be used to retrieve the record.
        def model(model : DB::Model.class | Nil)
          @@model = model
        end
      end

      # Returns the model used to retrieve the record.
      def model : Model.class
        self.class.model || raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a model class via the '::model' class method method or by overriding the " \
          "'#model' method"
        )
      end

      # Returns the queryset used to retrieve the record displayed by the view.
      def queryset
        model.all
      end

      # Returns the record that will be exposed by the view.
      def record
        @record ||= queryset.get!(DB::Query::Node.new({self.class.lookup_field => params[self.class.lookup_param]}))
      rescue DB::Errors::RecordNotFound
        raise HTTP::Errors::NotFound.new("No #{self.class.model.not_nil!.name} record can be found for the given query")
      end
    end
  end
end
