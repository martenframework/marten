# :nodoc:
class Hash
  include Marten::Template::CanDefineTemplateAttributes

  template_attributes :any?, :compact, :empty?, :keys, :none?, :one?, :present?, :size, :values

  # Allows to resolve hash keys as template attributes.
  #
  # This makes it possible to access hash values using `{{ my_hash.my_key }}` in templates,
  # in addition to the standard hash methods (empty?, size, keys, etc.).
  def resolve_template_attribute(key : ::String)
    if has_key?(key)
      self[key]
    else
      previous_def
    end
  end
end
