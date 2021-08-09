module Marten
  module DB
    module Management
      module Column
        class Float < Base
          include IsBuiltInColumn

          def clone
            self.class.new(
              name,
              primary_key: primary_key?,
              null: null?,
              unique: unique?,
              index: index?,
              default: default
            )
          end
        end
      end
    end
  end
end
