module Marten::DB::Model::PersistenceSpec
  class UndeletableRecord < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255, default: "default name"

    after_delete :prevent_deletion

    private def prevent_deletion
      raise "Deletion prevented!"
    end
  end
end
