module Marten
  module DB
    module Router
      # Base class for database routers.
      #
      # Database routers allow defining which database should be used for read/write operations, whether relations
      # between objects are allowed, and whether migrations should be applied to a given database. Custom routers should
      # inherit from this class and override the methods for which they want to provide an opinion.
      #
      # Each method may return `nil` to indicate that the router has no opinion. When multiple routers are configured,
      # they are consulted in order and the first non-`nil` result is used. If all routers abstain, Marten falls back to
      # allowing the operation (for `allow_*?` methods) or to the `"default"` database (for `db_for_*` methods).
      abstract class Base
        # Returns the database alias to use for read operations involving the given model.
        #
        # Returning `nil` indicates that this router has no opinion.
        def db_for_read(model : Model.class, hints : Hints = Hints.new) : String?
          nil
        end

        # Returns the database alias to use for write operations involving the given model.
        #
        # Returning `nil` indicates that this router has no opinion.
        def db_for_write(model : Model.class, hints : Hints = Hints.new) : String?
          nil
        end

        # Returns whether a relation between the two model instances should be allowed.
        #
        # Returning `true` allows the relation, `false` forbids it, and `nil` indicates that this router has no opinion.
        def allow_relation?(obj1 : Model, obj2 : Model, hints : Hints = Hints.new) : Bool?
          nil
        end

        # Returns whether a migration should be applied to the given database.
        #
        # Returning `true` allows the migration, `false` forbids it, and `nil` indicates that this router has no
        # opinion. The optional `model_name` argument identifies a specific model within the app when available.
        def allow_migrate?(
          db : String,
          app_label : String,
          model_name : String? = nil,
          hints : Hints = Hints.new,
        ) : Bool?
          nil
        end
      end
    end
  end
end
