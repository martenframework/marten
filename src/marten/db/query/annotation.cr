module Marten
  module DB
    module Query
      class Annotation
        getter alias_name
        getter field
        getter type

        getter? distinct

        def self.average(field : String, alias_name : String? = nil, distinct : Bool = false)
          new("average", field, alias_name.try(&.to_s) || "#{field}_average", distinct)
        end

        def self.count(field : String, alias_name : String? = nil, distinct : Bool = false)
          new("count", field, alias_name.try(&.to_s) || "#{field}_count", distinct)
        end

        def self.maximum(field : String, alias_name : String? = nil, distinct : Bool = false)
          new("maximum", field, alias_name.try(&.to_s) || "#{field}_maximum", distinct)
        end

        def self.minimum(field : String, alias_name : String? = nil, distinct : Bool = false)
          new("minimum", field, alias_name.try(&.to_s) || "#{field}_minimum", distinct)
        end

        def self.sum(field : String, alias_name : String? = nil, distinct : Bool = false)
          new("sum", field, alias_name.try(&.to_s) || "#{field}_sum", distinct)
        end

        def initialize(@type : String, @field : String, @alias_name : String, @distinct : Bool = false)
        end

        def alias(alias_name : String | Symbol)
          @alias_name = alias_name.to_s
          self
        end

        def distinct(distinct : Bool = true)
          @distinct = distinct
          self
        end
      end
    end
  end
end
