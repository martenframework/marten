module Marten::DB::Field::JSONSpec
  class Record < Marten::Model
    class Serializable
      include ::JSON::Serializable

      property a : Int32 | Nil
      property b : ::String | Nil
    end

    field :id, :big_int, primary_key: true, auto: true
    field :metadata, :json, blank: true, null: true
    field :serializable_metadata, :json, serializable: Serializable, blank: true, null: true
  end
end
