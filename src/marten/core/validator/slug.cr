module Marten
    module Core
      module Validator
        # Slug validator.
        module Slug
          extend self

          # Returns `true` if the passed string corresponds to a valid slug.
          def self.valid?(value : String) : Bool
            !!value.match(SLUG_RE)
          end

          private SLUG_RE = /^[a-z0-9]+(?:(?:-|_)[a-z0-9]+)*$/
        end
      end
    end
  end
