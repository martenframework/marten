require "./spec_helper"

describe Marten::DB::Query::Paginator do
  describe "#page" do
    it "returns the expected pages" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)
      paginator.page(1).to_a.should eq [tag_1, tag_2]
      paginator.page(2).to_a.should eq [tag_3, tag_4]
      paginator.page(3).to_a.should eq [tag_5]
    end

    it "returns an empty page if there are no records" do
      paginator = Tag.all.order(:name).paginator(2)
      paginator.page(1).to_a.should be_empty
    end

    it "returns the last page if the passed number is less than 0" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)
      paginator.page(-1).to_a.should eq [tag_5]
    end

    it "returns the last page if the passed number is greater than the pages count" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)
      paginator.page(4).to_a.should eq [tag_5]
    end
  end

  describe "#page!" do
    it "returns the expected pages" do
      tag_1 = Tag.create!(name: "a_tag", is_active: true)
      tag_2 = Tag.create!(name: "b_tag", is_active: true)
      tag_3 = Tag.create!(name: "c_tag", is_active: true)
      tag_4 = Tag.create!(name: "d_tag", is_active: true)
      tag_5 = Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)
      paginator.page!(1).to_a.should eq [tag_1, tag_2]
      paginator.page!(2).to_a.should eq [tag_3, tag_4]
      paginator.page!(3).to_a.should eq [tag_5]
    end

    it "returns an empty page if there are no records" do
      paginator = Tag.all.order(:name).paginator(2)
      paginator.page!(1).to_a.should be_empty
    end

    it "raises if the passed number is less than 0" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      expect_raises(
        Marten::DB::Query::Paginator::EmptyPageError,
        "Page numbers cannot be less than 1"
      ) do
        paginator.page!(-1)
      end
    end

    it "raises if the passed number is greater than the pages count" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)

      expect_raises(
        Marten::DB::Query::Paginator::EmptyPageError,
        "Page with number 5 contains no results"
      ) do
        paginator.page!(5)
      end
    end
  end

  describe "#page_size" do
    it "returns the paginator page size" do
      paginator = Tag.all.order(:name).paginator(2)
      paginator.page_size.should eq 2
    end
  end

  describe "#pages_count" do
    it "returns the expected pages count if there are no pages" do
      paginator = Tag.all.order(:name).paginator(2)
      paginator.pages_count.should eq 1
    end

    it "returns the expected pages count if there is only one page" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)
      paginator.pages_count.should eq 1
    end

    it "returns the expected pages count if there are multiple pages" do
      Tag.create!(name: "a_tag", is_active: true)
      Tag.create!(name: "b_tag", is_active: true)
      Tag.create!(name: "c_tag", is_active: true)
      Tag.create!(name: "d_tag", is_active: true)
      Tag.create!(name: "e_tag", is_active: true)

      paginator = Tag.all.order(:name).paginator(2)
      paginator.pages_count.should eq 3
    end
  end
end
