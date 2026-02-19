# :nodoc:
class Hash
  include Marten::Template::CanDefineTemplateAttributes

  template_attributes :any?, :compact, :empty?, :keys, :none?, :one?, :present?, :size, :values
end
