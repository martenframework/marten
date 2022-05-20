module Marten::DB::Field::FileSpec
  class Attachment < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :file, :file, blank: true, null: true
  end
end
