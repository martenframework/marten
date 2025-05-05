class Marten::Schema::BoundField
  include Marten::Template::Object

  # :nodoc:
  def resolve_template_attribute(key : ::String)
    case key
    when "errored?"
      errored?
    when "errors"
      errors
    when "field"
      field
    when "id"
      id
    when "required?"
      required?
    when "value"
      value
    else
      raise Marten::Template::Errors::UnknownVariable.new
    end
  end
end
