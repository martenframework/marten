class DB::Statement
  @@query_count = {} of UInt64 => Int32

  def_around_query_or_exec do |_|
    res = yield
    DB::Statement.increment_query_count
    res
  end

  def self.increment_query_count
    @@query_count[Fiber.current.object_id] ||= 0
    @@query_count[Fiber.current.object_id] += 1
  end

  def self.query_count
    @@query_count[Fiber.current.object_id] ||= 0
  end

  def self.reset_query_count
    @@query_count[Fiber.current.object_id] = 0
  end
end
