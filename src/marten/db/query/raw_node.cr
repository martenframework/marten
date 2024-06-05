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
          @negated = false
        )
          @filters = FilterHash.new
        end

        def initialize(
          @statement : String,
          @params : Array(::DB::Any) | Hash(String, ::DB::Any),
          @children = [] of Node,
          @connector = SQL::PredicateConnector::AND,
          @negated = false
        )
          @filters = FilterHash.new
        end

        def ==(other : self)
          (
            (other.statement == @statement) &&
              (other.params == @params) &&
              (other.children == @children) &&
              (other.connector == @connector) &&
              (other.negated == @negated)
          )
        end
      end
    end
  end
end
