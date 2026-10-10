require "./router/hints"
require "./router/base"

module Marten
  module DB
    # Database routing helpers.
    #
    # This module provides the framework-level API used to consult the configured database routers when resolving
    # connections and permissions. Routers are configured via the `database_routers` setting and are consulted in
    # order; the first non-`nil` opinion wins.
    module Router
      # Returns the database alias to use for read operations involving the given model.
      #
      # Configured routers are consulted in order. The first non-`nil` result is returned. If all routers abstain,
      # `nil` is returned and the caller should fall back to the default database.
      def self.db_for_read(model : Model.class, hints : Hints = Hints.new) : String?
        each_router do |router|
          if result = router.db_for_read(model, hints)
            return result
          end
        end

        nil
      end

      # Returns the database alias to use for write operations involving the given model.
      #
      # Configured routers are consulted in order. The first non-`nil` result is returned. If all routers abstain,
      # `nil` is returned and the caller should fall back to the default database.
      def self.db_for_write(model : Model.class, hints : Hints = Hints.new) : String?
        each_router do |router|
          if result = router.db_for_write(model, hints)
            return result
          end
        end

        nil
      end

      # Returns whether a relation between the two model instances should be allowed.
      #
      # Configured routers are consulted in order. The first non-`nil` result is returned. If all routers abstain, the
      # relation is allowed.
      def self.allow_relation?(obj1 : Model, obj2 : Model, hints : Hints = Hints.new) : Bool
        each_router do |router|
          result = router.allow_relation?(obj1, obj2, hints)
          return result unless result.nil?
        end

        true
      end

      # Returns whether a migration should be applied to the given database.
      #
      # Configured routers are consulted in order. The first non-`nil` result is returned. If all routers abstain, the
      # migration is allowed.
      def self.allow_migrate?(
        db : String,
        app_label : String,
        model_name : String? = nil,
        hints : Hints = Hints.new,
      ) : Bool
        each_router do |router|
          result = router.allow_migrate?(db, app_label, model_name, hints)
          return result unless result.nil?
        end

        true
      end

      private def self.each_router(&)
        Marten.settings.database_routers.each do |router_klass|
          yield router_klass.new
        end
      end
    end
  end
end
