class String
  include Marten::Template::CanDefineTemplateAttributes

  template_attributes :ascii_only?, :blank?, :bytesize, :empty?, :size, :valid_encoding?
end
