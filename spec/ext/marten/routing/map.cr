class Marten::Routing::Map
  def exposed_localized_rule
    @localized_rule
  end

  def exposed_localizing?
    @localizing
  end

  def exposed_localizing=(value)
    @localizing = value
  end

  def exposed_root?
    @root
  end

  def exposed_root=(value)
    @root = value
  end
end
