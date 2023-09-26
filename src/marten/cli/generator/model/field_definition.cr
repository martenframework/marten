module Marten
  module CLI
    abstract class Generator
      class Model < Generator
        # Represents a model field definition.
        #
        # Field definitions are specified using either of the following formats:
        #
        # * `name:type`
        # * `name:type{qualifier}`
        # * `name:type:modifier:modifier`
        #
        # Where `name` is the name of the field and `type` is the type of the field.
        #
        # `qualifier` can be required depending on the considered field type; when this is the case, it corresponds to a
        # mandatory field option. For example, `label:string{128}` will produce a string field whose `max_size` option
        # is set to `128`. Another example: `author:many_to_one{User}` will produce a many-to-one field whose `to`
        # option is set to target the `User` model.
        #
        # `modifier` is an optional field modifier. Field modifiers are used to specify additional (but non-mandatory)
        # field options. For example: `name:string:uniq` will produce a string field whose `unique` option is set to
        # `true`. Another example: `name:string:uniq:index` will produce a string field whose `unique` and `index`
        # options are set to `true`.
        class FieldDefinition
          enum Modifier
            AUTO
            INDEX
            NULL
            PRIMARY
            PRIMARY_KEY
            UNIQ
            UNIQUE
          end

          getter modifiers
          getter name
          getter qualifier
          getter type

          def self.from_argument(argument : String) : FieldDefinition
            # Extract the name, type, and qualifier from the raw argument.
            definition_match = DEFINITION_RE.match(argument)
            if definition_match.nil?
              raise_invalid_argument(
                argument,
                "Please specify a field name and type using the 'name:type' or 'name:type{qualifier}' formats."
              )
            end

            field_name = definition_match.named_captures["name"].to_s.downcase
            field_type = definition_match.named_captures["type"].to_s.downcase
            field_qualifier = definition_match.named_captures["qualifier"]

            # The remaining parts are field modifiers.
            modifiers = definition_match.post_match.split(":").reject(&.empty?).map(&.downcase)

            # Validate the field type.
            if !Marten::DB::Field.registry.has_key?(field_type)
              raise_invalid_argument(
                argument,
                "The field type '#{field_type}' does not correspond to an existing field type.\n" \
                "Possible field types are: #{Marten::DB::Field.registry.keys.join(", ")}."
              )
            end

            # Validate modifiers.
            field_modifiers = modifiers.each_with_object([] of Modifier) do |raw_modifier, arr|
              arr << Modifier.parse(raw_modifier)
            rescue ArgumentError
              raise_invalid_argument(
                argument,
                "The field modifier '#{raw_modifier}' does not correspond to an existing field modifier.\n" \
                "Possible field modifiers are: #{Modifier.values.map(&.to_s.downcase).join(", ")}."
              )
            end

            new(name: field_name, type: field_type, qualifier: field_qualifier, modifiers: field_modifiers)
          end

          private def self.raise_invalid_argument(argument : String, message) : Nil
            raise ArgumentError.new(
              "'#{argument}' is not a valid field definition\n\n" + message
            )
          end

          def initialize(
            @name : String,
            @type : String,
            @qualifier : String?,
            @modifiers : Array(Modifier)
          )
          end

          def render : String
            parts = ["field :#{name}", ":#{type}"]

            if !(rendered_qualifier = render_qualifier).nil?
              parts << rendered_qualifier
            end

            modifiers.each do |modifier|
              parts << case modifier
              when Modifier::AUTO
                "auto: true"
              when Modifier::INDEX
                "index: true"
              when Modifier::NULL
                "blank: true, null: true"
              when Modifier::PRIMARY, Modifier::PRIMARY_KEY
                "primary_key: true"
              when Modifier::UNIQ, Modifier::UNIQUE
                "unique: true"
              end.not_nil!
            end

            parts.join(", ")
          end

          def primary_key?
            modifiers.includes?(Modifier::PRIMARY_KEY) || modifiers.includes?(Modifier::PRIMARY)
          end

          private DEFINITION_RE = /^(?<name>[a-zA-Z0-9_]+):(?<type>[a-zA-Z0-9_]+)(\{(?<qualifier>[a-zA-Z0-9_:]+)\})?/

          private def render_qualifier
            qualifier_renderer = QualifierRenderer.registry[type]?
            return if qualifier_renderer.nil?

            qualifier_renderer.call(qualifier)
          end
        end
      end
    end
  end
end
