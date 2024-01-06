require "./spec_helper"

describe Marten::DB::Query::Set do
  describe "#resolve_template_attribute" do
    it "returns the expected result when requesting the 'all' attribute" do
      tag_1 = Tag.create!(name: "tag_1", is_active: true)
      tag_2 = Tag.create!(name: "tag_2", is_active: true)

      result = Tag.all.resolve_template_attribute("all")
      result.should be_a Marten::DB::Query::Set(Tag)
      result = result.as(Marten::DB::Query::Set(Tag))
      result.to_set.should eq([tag_1, tag_2].to_set)
    end

    it "returns the expected result when requesting the 'all?' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.resolve_template_attribute("all?").should be_true
    end

    it "returns the expected result when requesting the 'any?' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.resolve_template_attribute("any?").should be_true
      Tag.filter(name: "unknown").resolve_template_attribute("any?").should be_false
    end

    it "returns the expected result when requesting the 'count' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.resolve_template_attribute("count").should eq 2
      Tag.filter(name: "unknown").resolve_template_attribute("count").should eq 0
    end

    it "returns the expected result when requesting the 'distinct' attribute" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      Post.create!(author: user_1, title: "Post 1", published: true)
      Post.create!(author: user_1, title: "Post 2", published: true)
      Post.create!(author: user_2, title: "Post 3", published: true)
      Post.create!(author: user_1, title: "Post 4", published: false)

      result = TestUser.filter(posts__published: true).resolve_template_attribute("distinct")
      result.should be_a Marten::DB::Query::Set(TestUser)
      result = result.as(Marten::DB::Query::Set(TestUser))
      result.to_set.should eq [user_1, user_2].to_set
    end

    it "returns the expected result when requesting the 'empty?' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.resolve_template_attribute("empty?").should be_false
      Tag.filter(name: "unknown").resolve_template_attribute("empty?").should be_true
    end

    it "returns the expected result when requesting the 'exists?' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.resolve_template_attribute("exists?").should be_true
      Tag.filter(name: "unknown").resolve_template_attribute("exists?").should be_false
    end

    it "returns the expected result when requesting the 'first' attribute" do
      tag_1 = Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.order(:id).resolve_template_attribute("first").should eq tag_1
      Tag.filter(name: "unknown").resolve_template_attribute("first").should be_nil
    end

    it "returns the expected result when requesting the 'first!' attribute" do
      tag_1 = Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.order(:id).resolve_template_attribute("first!").should eq tag_1
    end

    it "returns the expected result when requesting the 'first?' attribute" do
      tag_1 = Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.order(:id).resolve_template_attribute("first?").should eq tag_1
      Tag.filter(name: "unknown").resolve_template_attribute("first?").should be_nil
    end

    it "returns the expected result when requesting the 'last' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      tag_2 = Tag.create!(name: "tag_2", is_active: true)

      Tag.all.order(:id).resolve_template_attribute("last").should eq tag_2
      Tag.filter(name: "unknown").resolve_template_attribute("last").should be_nil
    end

    it "returns the expected result when requesting the 'last!' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      tag_2 = Tag.create!(name: "tag_2", is_active: true)

      Tag.all.order(:id).resolve_template_attribute("last!").should eq tag_2
    end

    it "returns the expected result when requesting the 'none' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      result = Tag.all.resolve_template_attribute("none")
      result.should be_a Marten::DB::Query::Set(Tag)
      result = result.as(Marten::DB::Query::Set(Tag))
      result.exists?.should be_false
    end

    it "returns the expected result when requesting the 'none?' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.resolve_template_attribute("none?").should be_false
      Tag.filter(name: "unknown").resolve_template_attribute("none?").should be_true
    end

    it "returns the expected result when requesting the 'one?' attribute" do
      Tag.create!(name: "tag_1", is_active: true)

      Tag.all.resolve_template_attribute("one?").should be_true
      Tag.filter(name: "unknown").resolve_template_attribute("one?").should be_false
    end

    it "returns the expected result when requesting the 'reverse' attribute" do
      tag_1 = Tag.create!(name: "tag_1", is_active: true)
      tag_2 = Tag.create!(name: "tag_2", is_active: true)

      result = Tag.all.order(:id).resolve_template_attribute("reverse")
      result.should be_a Marten::DB::Query::Set(Tag)
      result = result.as(Marten::DB::Query::Set(Tag))
      result.to_a.should eq [tag_2, tag_1]
    end

    it "returns the expected result when requesting the 'size' attribute" do
      Tag.create!(name: "tag_1", is_active: true)
      Tag.create!(name: "tag_2", is_active: true)

      Tag.all.resolve_template_attribute("size").should eq 2
    end
  end
end
