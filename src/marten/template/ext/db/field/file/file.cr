class Marten::DB::Field::File::File
  include Marten::Template::Object

  # :nodoc:
  def resolve_template_attribute(key : ::String)
    case key
    when "attached?"
      attached?
    when "name"
      name
    when "size"
      size
    when "url"
      url
    end
  end
end
