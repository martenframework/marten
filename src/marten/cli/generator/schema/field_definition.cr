module Marten
  module CLI
    abstract class Generator
      class Schema < Generator
        # Represents a schema field definition.
        #
        # Field definitions are specified using either of the following formats:
        #
        # * `name:type`
        # * `name:type:modifier:modifier`
        #
        # Where `name` is the name of the field and `type` is the type of the field.
        #
        # `modifier` is an optional field modifier. Field modifiers are used to specify additional (but non-mandatory)
        # field options. For example: `name:string:optional` will produce a string field whose `required` option is set
        # to `false`.
        class FieldDefinition
          enum Modifier
            BLANK
            OPTIONAL
            REQUIRED
          end

          getter modifiers
          getter name
          getter type

          def self.from_argument(argument : String) : FieldDefinition
            # Extract the name and type from the raw argument.
            definition_match = DEFINITION_RE.match(argument)
            if definition_match.nil?
              raise_invalid_argument(
                argument,
                "Please specify a field name and type using the 'name:type' or 'name:type:modifier' formats."
              )
            end

            field_name = definition_match.named_captures["name"].to_s.downcase
            field_type = definition_match.named_captures["type"].to_s.downcase

            # The remaining parts are field modifiers.
            modifiers = definition_match.post_match.split(":").reject(&.empty?).map(&.downcase)

            # Validate the field type.
            if !Marten::Schema::Field.registry.has_key?(field_type)
              raise_invalid_argument(
                argument,
                "The field type '#{field_type}' does not correspond to an existing field type.\n" \
                "Possible field types are: #{Marten::Schema::Field.registry.keys.join(", ")}."
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

            new(name: field_name, type: field_type, modifiers: field_modifiers)
          end

          private def self.raise_invalid_argument(argument : String, message) : Nil
            raise ArgumentError.new(
              "'#{argument}' is not a valid field definition\n\n" + message
            )
          end

          def initialize(
            @name : String,
            @type : String,
            @modifiers : Array(Modifier)
          )
          end

          def render : String
            parts = ["field :#{name}", ":#{type}"]

            modifiers.each do |modifier|
              parts << case modifier
              when Modifier::BLANK, Modifier::OPTIONAL
                "required: false"
              when Modifier::REQUIRED
                "required: true"
              end.not_nil!
            end

            parts.uniq!.join(", ")
          end

          private DEFINITION_RE = /^(?<name>[a-zA-Z0-9_]+):(?<type>[a-zA-Z0-9_]+)/
        end
      end
    end
  end
end
