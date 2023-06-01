module Marten::DB::Field::ManyToOneSpec
  class Comment < Marten::Model
    field :id, :uuid, primary_key: true
    field :article, :many_to_one, to: Marten::DB::Field::ManyToOneSpec::Article
    field :text, :text

    after_initialize :initialize_id

    private def initialize_id
      @id ||= ::UUID.random
    end
  end
end
