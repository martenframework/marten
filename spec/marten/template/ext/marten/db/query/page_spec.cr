require "./spec_helper"

describe Marten::DB::Query::Page do
  describe "#resolve_template_attribute" do
    it "returns the expected result when requesting the 'all?' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)
      page = Marten::DB::Query::Page(Tag).new([tag], 2, paginator)

      page.resolve_template_attribute("all?").should be_true
    end

    it "returns the expected result when requesting the 'any?' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).resolve_template_attribute("any?").should be_true
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).resolve_template_attribute("any?").should be_false
    end

    it "returns the expected result when requesting the 'count' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).resolve_template_attribute("count").should eq 1
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).resolve_template_attribute("count").should eq 0
    end

    it "returns the expected result when requesting the 'empty?' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).resolve_template_attribute("empty?").should be_false
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).resolve_template_attribute("empty?").should be_true
    end

    it "returns the expected result when requesting the 'first?' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).resolve_template_attribute("first?").should eq tag
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).resolve_template_attribute("first?").should be_nil
    end

    it "returns the expected result when requesting the 'next_page?' attribute" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page_1.resolve_template_attribute("next_page?").should be_true

      page_2 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 3, paginator)
      page_2.resolve_template_attribute("next_page?").should be_false
    end

    it "returns the expected result when requesting the 'next_page_number' attribute" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page_1.resolve_template_attribute("next_page_number").should eq 2

      page_2 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 3, paginator)
      page_2.resolve_template_attribute("next_page_number").should be_nil
    end

    it "returns the expected result when requesting the 'none?' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).resolve_template_attribute("none?").should be_false
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).resolve_template_attribute("none?").should be_true
    end

    it "returns the expected result when requesting the 'number' attribute" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page_1.resolve_template_attribute("number").should eq 1

      page_2 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 3, paginator)
      page_2.resolve_template_attribute("number").should eq 3
    end

    it "returns the expected result when requesting the 'one?' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).resolve_template_attribute("any?").should be_true
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).resolve_template_attribute("any?").should be_false
    end

    it "returns the expected result when requesting the 'previous_page?' attribute" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page_1.resolve_template_attribute("previous_page?").should be_false

      page_2 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 3, paginator)
      page_2.resolve_template_attribute("previous_page?").should be_true
    end

    it "returns the expected result when requesting the 'previous_page_number' attribute" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page_1.resolve_template_attribute("previous_page_number").should be_nil

      page_2 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 3, paginator)
      page_2.resolve_template_attribute("previous_page_number").should eq 2
    end

    it "returns the expected result when requesting the 'size' attribute" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).resolve_template_attribute("size").should eq 1
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).resolve_template_attribute("size").should eq 0
    end
  end
end
