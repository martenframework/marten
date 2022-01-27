class Marten::Core::Validation::ErrorSet
  include Marten::Template::Object

  # :nodoc:
  def resolve_template_attribute(key : String)
    case key
    when "global"
      global
    else
      self[key]
    end
  end
end
