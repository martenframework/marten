class Comment < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :text, :text
  field :target, :polymorphic, to: [Post, ShowcasedPost], related: :comments
end
