module Marten::DB::Field::OneToOneSpec
  class Article < Marten::Model
    field :id, :uuid, primary_key: true
    field :title, :string, max_size: 255
    field :body, :text

    after_initialize :initialize_id

    private def initialize_id
      @id ||= ::UUID.random
    end
  end
end
