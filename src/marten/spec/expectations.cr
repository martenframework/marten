# Allows to expect a certain number of queries to be executed within a block.
def expect_db_query_count(count, &block)
  current_count = DB::Statement.query_count
  block.call
  (DB::Statement.query_count - current_count).should(
    eq(count), "Expected #{count} querie(s), but got #{DB::Statement.query_count - current_count}",
  )
end
