module Marten
  module DB
    # Wraps a DB transaction and allows to bind commit and rollback observers to it.
    class Transaction
      @commit_observers = [] of -> Nil
      @rollback_observers = [] of -> Nil
      @rolled_back = false

      getter? rolled_back
      setter rolled_back

      def initialize(@transaction : ::DB::Transaction)
      end

      def notify_observers : Nil
        if rolled_back?
          @rollback_observers.each(&.call)
        else
          @commit_observers.each(&.call)
        end
      end

      def observe_commit(block)
        @commit_observers << block
      end

      def observe_rollback(block)
        @rollback_observers << block
      end

      delegate connection, to: @transaction
    end
  end
end
