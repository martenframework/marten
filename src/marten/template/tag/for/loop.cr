module Marten
  module Template
    module Tag
      class For < Base
        class Loop
          include Object::Auto

          getter parent

          setter index

          def initialize(@items_size : Int32, @parent : Value? = nil)
            @index = 0
          end

          def first?
            @index == 0
          end

          def index
            @index + 1
          end

          def index0
            @index
          end

          def last?
            @index == (@items_size - 1)
          end

          def revindex
            @items_size - @index
          end

          def revindex0
            @items_size - @index - 1
          end
        end
      end
    end
  end
end
