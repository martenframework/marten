require "./column/concerns/**"

require "./column/base"
require "./column/big_int"
require "./column/bool"
require "./column/date_time"
require "./column/int"
require "./column/string"
require "./column/text"
require "./column/uuid"

require "./column/auto"
require "./column/big_auto"

require "./column/foreign_key"

module Marten
  module DB
    abstract class Migration
      module Column
      end
    end
  end
end
