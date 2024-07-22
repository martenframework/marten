class Marten::HTTP::FlashStore
  include Marten::Template::Object

  # :nodoc:
  def resolve_template_attribute(key : String)
    case key
    when "empty?"
      empty?
    when "size"
      size
    else
      self[key]
    end
  rescue KeyError
    raise Marten::Template::Errors::UnknownVariable.new
  end
end
