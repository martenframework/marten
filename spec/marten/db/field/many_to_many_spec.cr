require "./spec_helper"
require "./many_to_many_spec/**"

describe Marten::DB::Field::ManyToMany do
  with_installed_apps Marten::DB::Field::ManyToManySpec::App

  describe "::contribute_to_model" do
    it "works as expected for non-recursive many-to-many relationships" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      tag_1 = Tag.create!(name: "coding", is_active: true)
      tag_2 = Tag.create!(name: "crystal", is_active: true)
      tag_3 = Tag.create!(name: "ruby", is_active: true)

      user_1.tags.add(tag_1)
      user_1.tags.add(tag_2)
      user_2.tags.add(tag_1)
      user_2.tags.add(tag_3)

      user_1 = TestUser.get!(id: user_1.id)
      user_1.tags.to_a.to_set.should eq [tag_1, tag_2].to_set

      user_2 = TestUser.get!(id: user_2.id)
      user_2.tags.to_a.to_set.should eq [tag_1, tag_3].to_set

      tag_1 = Tag.get!(id: tag_1.id)
      tag_1.test_users.to_a.to_set.should eq [user_1, user_2].to_set

      tag_2 = Tag.get!(id: tag_2.id)
      tag_2.test_users.to_a.should eq [user_1]

      tag_3 = Tag.get!(id: tag_3.id)
      tag_3.test_users.to_a.should eq [user_2]
    end

    it "works as expected for recursive many-to-many relationships" do
      parent_node = Marten::DB::Field::ManyToManySpec::TreeNode.create!(label: "Parent")
      child_node_1 = Marten::DB::Field::ManyToManySpec::TreeNode.create!(label: "Child 1")
      child_node_2 = Marten::DB::Field::ManyToManySpec::TreeNode.create!(label: "Child 2")

      parent_node.children.add(child_node_1, child_node_2)

      parent_node = Marten::DB::Field::ManyToManySpec::TreeNode.get!(id: parent_node.id)
      parent_node.children.to_a.to_set.should eq [child_node_1, child_node_2].to_set

      child_node_1 = Marten::DB::Field::ManyToManySpec::TreeNode.get!(id: child_node_1.id)
      child_node_1.parents.to_a.should eq [parent_node]
    end
  end

  describe "#db_column" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.db_column.should be_nil
    end
  end

  describe "#default" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.default.should be_nil
    end
  end

  describe "#from_db" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.from_db(42).should be_nil
    end
  end

  describe "#from_db_result_set" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)

      Marten::DB::Connection.default.open do |db|
        db.query("SELECT 42") do |rs|
          rs.each do
            field.from_db_result_set(rs).should be_nil
          end
        end
      end
    end
  end

  describe "#related_model" do
    it "returns the related model" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.related_model.should eq Tag
    end
  end

  describe "#relation?" do
    it "returns true" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.relation?.should be_true
    end
  end

  describe "#relation_name" do
    it "returns the relation name" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.relation_name.should eq "tags"
    end
  end

  describe "#to_column" do
    it "returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.to_column.should be_nil
    end
  end

  describe "#to_db" do
    it "always returns nil" do
      field = Marten::DB::Field::ManyToMany.new("tags", Tag, PostTags)
      field.to_db(nil).should be_nil
    end
  end
end
