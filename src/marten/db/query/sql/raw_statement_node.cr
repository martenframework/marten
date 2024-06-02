module Marten
  module DB
    module Query
      module SQL
        class RawStatementNode < PredicateNode
          getter statement
          getter params

          def initialize(
            @statement : String,
            @params = [] of ::DB::Any,
            @children = [] of PredicateNode,
            @connector = SQL::PredicateConnector::AND, @negated = false, *args
          )
            @predicates = [] of Predicate::Base
            @predicates.concat(args.to_a)
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

          def ==(other : RawStatementNode)
            (
              (other.statement == statement) &&
                (other.predicates == predicates) &&
                (other.children == children) &&
                (other.connector == connector) &&
                (other.negated == negated)
            )
          end

          def clone
            RawStatementNode.new(
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
              sanitize_positional_parameters(connection)
            else
              sanitize_named_parameters(connection)
            end
          end

          private NAMED_PARAMETER_RE        = /(:?):([a-zA-Z]\w*)/
          private POSITIONAL_PARAMETER_CHAR = '?'
          private POSITIONAL_PARAMETER_RE   = /#{"\\" + POSITIONAL_PARAMETER_CHAR}/

          private def sanitize_positional_parameters(connection)
            if @statement.count(POSITIONAL_PARAMETER_CHAR) != params.size
              raise Errors::UnmetQuerySetCondition.new("Wrong number of parameters provided for query: #{@statement}")
            end

            {@statement.gsub(POSITIONAL_PARAMETER_RE, "%s"), params.as(Array(::DB::Any))}
          end

          private def sanitize_named_parameters(connection)
            sanitized_params = [] of ::DB::Any

            sanitized_query = @statement.gsub(NAMED_PARAMETER_RE) do |match|
              # Specifically handle PostgreSQL's cast syntax (::).
              next match if $1 == ":"

              parameter_match = $2.to_s
              if !params.as(Hash).has_key?(parameter_match)
                raise Errors::UnmetQuerySetCondition.new(
                  "Missing parameter '#{parameter_match}' for query: #{@statement}"
                )
              end

              sanitized_params << params.as(Hash(String, ::DB::Any))[parameter_match]
              "%s"
            end

            {sanitized_query, sanitized_params}
          end
        end
      end
    end
  end
end
