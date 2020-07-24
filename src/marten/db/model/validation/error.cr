module Marten
  module DB
    abstract class Model
      module Validation
        # Represents a validation error.
        class Error
          @type : String
          @field : String?
          @message : String

          def initialize(@message : String, type : String | Symbol, field : Nil | String | Symbol = nil)
            @type = type.to_s
            @field = field.to_s unless field.nil?
          end
        end
      end
    end
  end
end
