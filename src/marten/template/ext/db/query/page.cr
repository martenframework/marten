class Marten::DB::Query::Page(M)
  include Marten::Template::Object

  def resolve_template_attribute(key : String)
    case key
    when "all?"
      all?
    when "any?"
      any?
    when "count"
      count
    when "empty?"
      empty?
    when "first?"
      first?
    when "next_page?"
      next_page?
    when "next_page_number"
      next_page_number
    when "none?"
      none?
    when "number"
      number
    when "one?"
      one?
    when "previous_page?"
      previous_page?
    when "previous_page_number"
      previous_page_number
    when "size"
      size
    end
  end
end
