module Marten
  module DB
    module Query
      class RawNode < Node
        getter statement
        getter params

        def initialize(
          @statement : String,
          @params = [] of ::DB::Any,
          @children = [] of Node,
          @connector = SQL::PredicateConnector::AND,
          @negated = false,
          @filters = FilterHash.new
        )
        end

        def initialize(
          @statement : String,
          @params = [] of ::DB::Any,
          @children = [] of Node,
          @connector = SQL::PredicateConnector::AND,
          @negated = false,
          @filters = FilterHash.new
        )
        end

        def initialize(
          @statement : String,
          @params : Array(::DB::Any) | Hash(String, ::DB::Any),
          @children = [] of Node,
          @connector = SQL::PredicateConnector::AND,
          @negated = false,
          @filters = FilterHash.new
        )
        end

        def ==(other : self)
          (
            (other.statement == @statement) &&
              (other.params == @params) &&
              (other.connector == @connector) &&
              (other.negated == @negated)
          )
        end

        protected def add(other : self, conn : SQL::PredicateConnector)
          return if @children.includes?(other)

          if @connector == conn
            @children << other
          else
            new_child = self.class.new(children: @children, connector: @connector, negated: @negated, filters: @filters)
            @connector = conn
            @children = [new_child, other]
          end
        end

        private def combine(other, conn)
          combined = Node.new(connector: conn)
          combined.add(self, conn)
          combined.add(other, conn)
          combined
        end
      end
    end
  end
end
