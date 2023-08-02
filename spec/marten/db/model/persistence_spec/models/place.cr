module Marten::DB::Model::PersistenceSpec
  class Place < Marten::Model
    field :id, :uuid, primary_key: true
    field :name, :string, max_size: 128
    field :address, :many_to_one, to: Marten::DB::Model::PersistenceSpec::Address

    after_initialize :initialize_id

    private def initialize_id
      @id ||= UUID.random
    end
  end
end
