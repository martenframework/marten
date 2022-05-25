class Marten::Schema::BoundField
  include Marten::Template::Object

  template_attributes :id, :errored?, :errors, :value
end
