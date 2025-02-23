class Marten::Routing::Reverser
  def exposed_build_mismatch(*args, **kwargs)
    build_mismatch(*args, **kwargs)
  end

  def exposed_path_for_interpolations
    @path_for_interpolations
  end
end
