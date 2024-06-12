require "./concerns/sanitizer"

module Marten
  module DB
    module Query
      module SQL
        class RawPredicateNode < PredicateNode
          include Sanitizer

          getter statement
          getter params

          def initialize(
            @statement : String,
            @params = [] of ::DB::Any,
            @children = [] of PredicateNode,
            @connector = SQL::PredicateConnector::AND,
            @negated = false
          )
            @predicates = [] of Predicate::Base
          end

          def initialize(
            @statement : String,
            @params : Array(::DB::Any) | Hash(String, ::DB::Any),
            @children : Array(PredicateNode),
            @connector : PredicateConnector,
            @negated : Bool,
            @predicates : Array(Predicate::Base)
          )
          end

          def ==(other : RawPredicateNode)
            (
              (other.statement == statement) &&
                (other.params == params) &&
                (other.children == children) &&
                (other.connector == connector) &&
                (other.negated == negated)
            )
          end

          def clone
            RawPredicateNode.new(
              statement: @statement,
              params: params,
              children: @children.map(&.clone),
              connector: @connector,
              negated: @negated,
              predicates: @predicates.dup
            )
          end

          def to_sql(connection : Connection::Base)
            # Escape % characters to be not be considered
            # during formatting process
            @statement = @statement.gsub("%", "%%")

            case params
            when Array(::DB::Any)
              sanitize_positional_parameters(@statement, params.as(Array(::DB::Any)))
            else
              sanitize_named_parameters(@statement, params.as(Hash(String, ::DB::Any)))
            end
          end
        end
      end
    end
  end
end
