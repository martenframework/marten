module Marten
  module DB
    module Management
      module Migrations
        class Graph
          class Node
            getter children
            getter migration
            getter parents

            def initialize(@migration : Migration)
              @parents = Set(self).new
              @children = Set(self).new
            end

            def add_child(child : self)
              @children << child
            end

            def add_parent(parent : self)
              @parents << parent
            end
          end
        end
      end
    end
  end
end
