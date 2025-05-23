require "./spec_helper"

describe Marten::DB::Query::Paginator do
  describe "#resolve_template_attribute" do
    it "returns the expected result when requesting the 'page_size' attribute" do
      6.times { |i| Tag.create!(name: "tag_#{i}", is_active: true) }
      paginator = Tag.all.order(:name).paginator(2)

      paginator.resolve_template_attribute("page_size").should eq 2
    end

    it "returns the expected result when requesting the 'pages_count' attribute" do
      6.times { |i| Tag.create!(name: "tag_#{i}", is_active: true) }
      paginator = Tag.all.order(:name).paginator(2)

      paginator.resolve_template_attribute("pages_count").should eq 3
    end

    it "returns the expected result when requesting the 'total_count' attribute" do
      6.times { |i| Tag.create!(name: "tag_#{i}", is_active: true) }
      paginator = Tag.all.order(:name).paginator(2)

      paginator.resolve_template_attribute("total_count").should eq 6
    end

    it "raises as expected if the specified attribute is not supported" do
      paginator = Tag.all.order(:name).paginator(2)

      expect_raises(Marten::Template::Errors::UnknownVariable) do
        paginator.resolve_template_attribute("unknown_attribute")
      end
    end
  end
end
