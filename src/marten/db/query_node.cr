require "./field"

module Marten
  module DB
    class QueryNode(Model)
      def initialize(@children = [] of self, @connector = SQL::PredicateConnector::AND, @negated = false, **kwargs)
        @filters = {} of String | Symbol => Field::Any
        @filters.merge!(kwargs.to_h)
      end

      def initialize(
        @children : Array(self),
        @connector : SQL::PredicateConnector,
        @negated : Bool,
        @filters : Hash(String | Symbol, Field::Any)
      )
      end

      def ==(other : self)
        (
          (other.filters == @filters) &&
          (other.children == @children) &&
          (other.connector == @connector) &&
          (other.negated == @negated)
        )
      end

      def &(other : self)
        combine(other, SQL::PredicateConnector::AND)
      end

      def |(other : self)
        combine(other, SQL::PredicateConnector::OR)
      end

      protected getter children
      protected getter connector
      protected getter filters
      protected getter negated

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
        combined = self.class.new(connector: conn)
        combined.add(self, conn)
        combined.add(other, conn)
        combined
      end
    end
  end
end
