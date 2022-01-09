class TagWithUUID < Marten::Model
  field :id, :uuid, primary_key: true
  field :label, :string, max_size: 128

  after_initialize :initialize_id

  def initialize_id
    @id ||= UUID.random
  end
end
