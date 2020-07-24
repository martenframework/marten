module Marten
  module DB
    abstract class Model
      module Validation
        # Represents a set of validation errors.
        class ErrorSet
          include Enumerable(Error)

          def initialize
            @errors = [] of Error
          end

          def add(message : String, *, type : Nil | String | Symbol = nil)
            @errors << Error.new(type: type || :invalid, field: nil, message: message)
          end

          def add(field : String | Symbol, message : String, *, type : Nil | String | Symbol = nil)
            @errors << Error.new(type: type || :invalid, field: field, message: message)
          end

          delegate each, to: @errors
        end
      end
    end
  end
end
