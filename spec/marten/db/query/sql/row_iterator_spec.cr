require "./spec_helper"

describe Marten::DB::Query::SQL::RowIterator do
  describe "#each_local_column" do
    it "allows to yield the result set for each of the local columns of a model" do
      tag_1 = Tag.create!(name: "crystal", is_active: true)
      tag_2 = Tag.create!(name: "coding", is_active: true)

      Marten::DB::Connection.default.open do |db|
        db.query "SELECT * FROM #{Tag.db_table}" do |result_set|
          outer_iteration = 0
          result_set.each do
            row_iterator = Marten::DB::Query::SQL::RowIterator.new(
              Tag,
              result_set,
              Array(Marten::DB::Query::SQL::Join).new
            )

            inner_iteration = 0
            row_iterator.each_local_column do |rs, column_name|
              if outer_iteration == 0
                if inner_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq tag_1.id
                elsif inner_iteration == 1
                  column_name.should eq "name"
                  rs.read(String).should eq "crystal"
                end
              elsif outer_iteration == 1
                if inner_iteration == 0
                  column_name.should eq "id"
                  rs.read(Int64).should eq tag_2.id
                elsif inner_iteration == 1
                  column_name.should eq "name"
                  rs.read(String).should eq "coding"
                end
              end

              inner_iteration += 1
            end

            outer_iteration += 1
          end
        end
      end
    end
  end
end
