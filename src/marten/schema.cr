require "./schema/**"

module Marten
  # Abstract base schema class.
  #
  # Schemas allows to define how a data set should be validated and what fields are expected. Schemas can be used to
  # validate query parameters, forms data, files, or JSON objects.
  abstract class Schema
    include Core::Validation

    # :nodoc:
    annotation FieldInstanceVariable; end

    # :nodoc:
    alias DataHash = Hash(String, Field::Any | Nil | HTTP::UploadedFile | Routing::Parameter::Types)

    # :nodoc:
    alias AnyDataHash = DataHash | Routing::MatchParameters | HTTP::Params::Data | HTTP::Params::Query

    @@fields : Hash(String, Field::Base) = {} of String => Field::Base

    @bound_fields : Hash(String, BoundField) | Nil = nil
    @validated_data = {} of String => Field::Any | Nil | HTTP::UploadedFile

    getter validated_data

    macro inherited
      FIELDS_ = {} of Nil => Nil

      _inherit_fields
    end

    # Allows to define a schema field.
    #
    # At least two positional arguments are required when defining schema fields: a field identifier and a field type.
    # Depending on the considered field types, additional keyword arguments can be used in order to customize on the
    # field behaves and how it handles validations:
    #
    # ```
    # class MySchema  < Marten::Schema
    #   field :my_field, :string, required: true, max_size: 128
    # end
    # ```
    macro field(*args, **kwargs)
      {% if args.size != 2 %}{% raise "A field name and type must be explicitly specified" %}{% end %}

      {% sanitized_id = args[0].is_a?(StringLiteral) || args[0].is_a?(SymbolLiteral) ? args[0].id : nil %}
      {% if sanitized_id.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[0]}' as a valid field name" %}{% end %}

      {% sanitized_type = args[1].is_a?(StringLiteral) || args[1].is_a?(SymbolLiteral) ? args[1].id : nil %}
      {% if sanitized_type.is_a?(NilLiteral) %}{% raise "Cannot use '#{args[1]}' as a valid field type" %}{% end %}

      {% type_exists = false %}
      {% field_klass = nil %}
      {% field_ann = nil %}
      {% for k in Marten::Schema::Field::Base.all_subclasses %}
        {% ann = k.annotation(Marten::Schema::Field::Registration) %}
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

      {{ field_klass }}.contribute_to_schema(
        {{ @type }},
        {{ sanitized_id }},
        {{ field_ann }},
        {% unless kwargs.empty? %}{{ kwargs }}{% else %}nil{% end %}
      )
    end

    # Returns all the fields instances associated with the current schema.
    def self.fields
      @@fields.values
    end

    # Allows to retrieve a specific field instance associated with the current schema.
    #
    # The returned object will be an instance of a subclass of `Marten::Schema::Field::Base`.
    def self.get_field(id : String | Symbol)
      @@fields.fetch(id.to_s) do
        raise Errors::UnknownField.new("Unknown field '#{id}'")
      end
    end

    # :nodoc:
    def self.register_field(field : Field::Base)
      @@fields[field.id] = field
    end

    def initialize(@data : AnyDataHash, @initial : AnyDataHash = DataHash.new)
    end

    # Returns the bound field associated with the passed field name or raises if the field is not present.
    def [](field_name : String | Symbol)
      bound_fields[field_name.to_s]
    rescue KeyError
      raise Errors::UnknownField.new("Unknown field '#{field_name}'")
    end

    # Returns the bound field associated with the passed field name or `nil` if the field is not present.
    def []?(field_name : String | Symbol)
      bound_fields[field_name.to_s]?
    end

    # Allows to read the value of a specific field.
    #
    # This methods returns the value of the field corresponding to `field_name`. If the passed `field_name` doesn't
    # match any existing field, a `Marten::Schema::Errors::UnknownField` exception is raised.
    def get_field_value(field_name : String | Symbol)
      field = self.class.get_field(field_name)
      @data[field.id]? || @initial[field.id]?
    end

    protected getter data
    protected getter initial

    private def bound_fields
      @bound_fields ||= begin
        bound_fields_hash = {} of String => BoundField

        self.class.fields.map do |field|
          bound_fields_hash[field.id] = BoundField.new(schema: self, field: field)
        end

        bound_fields_hash
      end
    end

    private def perform_validation
      self.class.fields.each do |field|
        value = field.perform_validation(self)
        validated_data[field.id] = value if errors[field.id].empty?
      end

      super
    end

    # :nodoc:
    macro _inherit_fields
      {% if @type.ancestors.first.has_constant?("FIELDS_") %}
        {% for field_id, field_config in @type.ancestors.first.constant("FIELDS_") %}
          {% FIELDS_[field_id] = field_config %}

          {% field_klass = nil %}
          {% field_ann = nil %}
          {% for k in Marten::Schema::Field::Base.all_subclasses %}
            {% ann = k.annotation(Marten::Schema::Field::Registration) %}
            {% if ann && ann[:id] == field_config[:type] %}
              {% field_klass = k %}
              {% field_ann = ann %}
            {% end %}
          {% end %}

          {{ field_klass }}.contribute_to_schema(
            {{ @type }},
            {{ field_id.id }},
            {{ field_ann }},
            {% unless field_config[:kwargs].empty? %}{{ field_config[:kwargs] }}{% else %}nil{% end %}
          )
        {% end %}
      {% end %}
    end
  end
end
