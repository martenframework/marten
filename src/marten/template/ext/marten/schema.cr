abstract class Marten::Schema
  include Marten::Template::Object

  # :nodoc:
  def resolve_template_attribute(key : String)
    case key
    when "errors"
      errors
    else
      self[key]?
    end
  end
end
