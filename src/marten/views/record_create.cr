require "./schema"

module Marten
  module Views
    # View allowing to create a new model record by processing a schema.
    #
    # This view can be used to process a form, validate its data through the use of a schema, and create a record by
    # using the validated data. It is expected that the view will be accessed through a GET request first: when this
    # happens the configured template is rendered and displayed, and the configured schema which is initialized can be
    # accessed from the template context in order to render a form for example. When the form is submitted via a POST
    # request, the configured schema is validated using the form data. If the data is valid, the corresponding model
    # record is created and the view returns an HTTP redirect to a configured success URL.
    #
    # ```
    # class MyFormView < Marten::Views::RecordCreate
    #   model MyModel
    #   schema MyFormSchema
    #   template_name "my_form.html"
    #   success_route_name "my_form_success"
    # end
    # ```
    #
    # It should be noted that the redirect response issued will be a 302 (found).
    #
    # The model class used to create the new record can be configured through the use of the `#model` class method. The
    # schema used to perform the validation can be defined through the use of the `#schema` class method. Alternatively,
    # the `#schema_class` method can also be overridden to dynamically define the schema class as part of the request
    # view handling.
    #
    # The `#template_name` class method allows to define the name of the template to use to render the schema while the
    # `#success_route_name` method can be used to specify the name of a route to redirect to once the schema has been
    # validated. Alternatively, the `#sucess_url` class method can be used to provide a raw URL to redirect to. The same
    # method can also be overridden at the instance level in order to rely on a custom logic to generate the sucess URL
    # to redirect to.
    class RecordCreate < Views::Schema
      # Returns the configured model class.
      class_getter model : DB::Model.class | Nil

      # Allows to configure the model class that should be used to create the new record.
      def self.model(model : DB::Model.class | Nil)
        @@model = model
      end

      # Produces the response when the processed schema is valid.
      #
      # By default, this will create the new record and return a 302 redirect targetting the configured success URL.
      def process_valid_schema
        record = model.new(schema.validated_data)
        record.save!

        super
      end

      # Returns the model used to create the new record.
      def model : Model.class
        self.class.model || raise Errors::ImproperlyConfigured.new(
          "'#{self.class.name}' must define a model class via the '::model' class method method or by overriding the " \
          "'#model' method"
        )
      end
    end
  end
end
