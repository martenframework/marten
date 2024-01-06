require "./spec_helper"

describe Marten::DB::Query::Page do
  describe "#accumulate" do
    it "raises NotImplementedError" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)
      page = Marten::DB::Query::Page(Tag).new([tag], 2, paginator)

      expect_raises(NotImplementedError) { page.accumulate }
    end
  end

  describe "#count" do
    it "returns the number of records in the page" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)

      Marten::DB::Query::Page(Tag).new([tag], 2, paginator).count.should eq 1
      Marten::DB::Query::Page(Tag).new([] of Tag, 2, paginator).count.should eq 0
    end
  end

  describe "#next_page?" do
    it "returns true if there is a next page number" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page_1.next_page?.should be_true

      page_2 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 2, paginator)
      page_2.next_page?.should be_true
    end

    it "returns false if there is no next page number" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page = Marten::DB::Query::Page(Tag).new([tag_5], 3, paginator)
      page.next_page?.should be_false
    end
  end

  describe "#next_page_number" do
    it "returns the next page number if there is a next page" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page_1.next_page_number.should eq 2

      page_2 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 2, paginator)
      page_2.next_page_number.should eq 3
    end

    it "returns nil if there is no next page number" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page = Marten::DB::Query::Page(Tag).new([tag_5], 3, paginator)
      page.next_page_number.should be_nil
    end
  end

  describe "#number" do
    it "returns the page number" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 2, paginator)

      page.number.should eq 2
    end
  end

  describe "#previous_page?" do
    it "returns true if there is a previous page number" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 2, paginator)
      page_1.previous_page?.should be_true

      page_2 = Marten::DB::Query::Page(Tag).new([tag_5], 3, paginator)
      page_2.previous_page?.should be_true
    end

    it "returns false if there is no previous page number" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page.previous_page?.should be_false
    end
  end

  describe "#previous_page_number" do
    it "returns the previous page number if there is a previous page number" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page_1 = Marten::DB::Query::Page(Tag).new([tag_3, tag_4], 2, paginator)
      page_1.previous_page_number.should eq 1

      page_2 = Marten::DB::Query::Page(Tag).new([tag_5], 3, paginator)
      page_2.previous_page_number.should eq 2
    end

    it "returns nil if there is no previous page number" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      page = Marten::DB::Query::Page(Tag).new([tag_1, tag_2], 1, paginator)
      page.previous_page_number.should be_nil
    end
  end

  describe "#product" do
    it "raises NotImplementedError" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)
      page = Marten::DB::Query::Page(Tag).new([tag], 2, paginator)

      expect_raises(NotImplementedError) { page.product }
    end
  end

  describe "#sum" do
    it "raises NotImplementedError" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)
      page = Marten::DB::Query::Page(Tag).new([tag], 2, paginator)

      expect_raises(NotImplementedError) { page.sum }
    end
  end

  describe "#to_h" do
    it "raises NotImplementedError" do
      tag = Tag.create!(name: "a_tag", is_active: true)
      paginator = Tag.all.order(:name).paginator(2)
      page = Marten::DB::Query::Page(Tag).new([tag], 2, paginator)

      expect_raises(NotImplementedError) { page.to_h }
    end
  end
end
