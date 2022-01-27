class Marten::Schema::BoundField
  include Marten::Template::Object

  # :nodoc:
  def resolve_template_attribute(key : String)
    case key
    when "id"
      id
    when "errored?"
      errored?
    when "errors"
      errors
    end
  end
end
