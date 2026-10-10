module Marten
  module DB
    module Router
      # Hints passed to database routers when resolving connections or permissions.
      #
      # Routers can use these hints to make more informed routing decisions. For example, the `instance` hint allows a
      # router to stick to the database already associated with a specific model record.
      struct Hints
        # Returns the model instance associated with the current operation, if any.
        getter instance

        def initialize(@instance : Model? = nil)
        end
      end
    end
  end
end
