module Marten::DB::Field::OneToOneSpec
  class Comment < Marten::Model
    field :id, :uuid, primary_key: true
    field :article, :one_to_one, to: Marten::DB::Field::OneToOneSpec::Article
    field :text, :text

    after_initialize :initialize_id

    private def initialize_id
      @id ||= ::UUID.random
    end
  end
end
