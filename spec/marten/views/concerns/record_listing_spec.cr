require "./spec_helper"

describe Marten::Views::RecordListing do
  describe "::model" do
    it "returns the configured model" do
      Marten::Views::RecordListingSpec::TestView.model.should eq TestUser
    end

    it "returns nil by default" do
      Marten::Views::RecordListingSpec::TestViewWithoutConfiguration.model.should be_nil
    end
  end

  describe "::model(model)" do
    it "allows to configure the model used to retrieve the record" do
      Marten::Views::RecordListingSpec::TestView.model.should eq TestUser
    end
  end

  describe "::page_number_param" do
    it "returns the configured page number param" do
      Marten::Views::RecordListingSpec::TestView.page_number_param.should eq "p"
    end

    it "returns the expected default value if no other value is set" do
      Marten::Views::RecordListingSpec::TestViewWithoutConfiguration.page_number_param.should eq "page"
    end
  end

  describe "::page_number_param(param)" do
    it "allows to configure the page number param" do
      Marten::Views::RecordListingSpec::TestView.page_number_param.should eq "p"
    end
  end

  describe "::page_size" do
    it "returns the configured page size" do
      Marten::Views::RecordListingSpec::TestView.page_size.should eq 2
    end

    it "returns the expected default value if no other value is set" do
      Marten::Views::RecordListingSpec::TestViewWithoutConfiguration.page_size.should be_nil
    end
  end

  describe "::page_size(size)" do
    it "allows to configure the page size" do
      Marten::Views::RecordListingSpec::TestView.page_size.should eq 2
    end
  end

  describe "#paginate_queryset" do
    it "is able to paginate using a page parameter embedded in the route parameters" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      user_4 = TestUser.create!(username: "jd4", email: "jd4@example.com", first_name: "John", last_name: "Doe")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      params_1 = Hash(String, Marten::Routing::Parameter::Types){"p" => 1}
      view_1 = Marten::Views::RecordListingSpec::TestView.new(request, params_1)
      page_1 = view_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      params_2 = Hash(String, Marten::Routing::Parameter::Types){"p" => 2}
      view_2 = Marten::Views::RecordListingSpec::TestView.new(request, params_2)
      page_2 = view_2.paginate_queryset
      page_2.number.should eq 2
      page_2.to_a.should eq [user_3, user_4]
    end

    it "is able to paginate using a page string parameter embedded in the route parameters" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      user_4 = TestUser.create!(username: "jd4", email: "jd4@example.com", first_name: "John", last_name: "Doe")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      params_1 = Hash(String, Marten::Routing::Parameter::Types){"p" => "1"}
      view_1 = Marten::Views::RecordListingSpec::TestView.new(request, params_1)
      page_1 = view_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      params_2 = Hash(String, Marten::Routing::Parameter::Types){"p" => "2"}
      view_2 = Marten::Views::RecordListingSpec::TestView.new(request, params_2)
      page_2 = view_2.paginate_queryset
      page_2.number.should eq 2
      page_2.to_a.should eq [user_3, user_4]
    end

    it "is able to paginate using a page parameter embedded in the query parameters" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      user_4 = TestUser.create!(username: "jd4", email: "jd4@example.com", first_name: "John", last_name: "Doe")

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test?p=1",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view_1 = Marten::Views::RecordListingSpec::TestView.new(request_1)
      page_1 = view_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test?p=2",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view_2 = Marten::Views::RecordListingSpec::TestView.new(request_2)
      page_2 = view_2.paginate_queryset
      page_2.number.should eq 2
      page_2.to_a.should eq [user_3, user_4]
    end

    it "defaults to the first page if no page parameter is specified" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd4", email: "jd4@example.com", first_name: "John", last_name: "Doe")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::RecordListingSpec::TestView.new(request)

      page = view.paginate_queryset
      page.number.should eq 1
      page.to_a.should eq [user_1, user_2]
    end

    it "fallbacks to the first page if the page parameter value is not a valid number" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd4", email: "jd4@example.com", first_name: "John", last_name: "Doe")

      request_1 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test?p=foo",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view_1 = Marten::Views::RecordListingSpec::TestView.new(request_1)
      page_1 = view_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test?p=bar",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view_2 = Marten::Views::RecordListingSpec::TestView.new(request_2)
      page_2 = view_2.paginate_queryset
      page_2.number.should eq 1
      page_2.to_a.should eq [user_1, user_2]
    end

    it "fallbacks to the last page if the page parameter value is greater than the number of pages" do
      TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      user_3 = TestUser.create!(username: "jd3", email: "jd3@example.com", first_name: "John", last_name: "Doe")
      user_4 = TestUser.create!(username: "jd4", email: "jd4@example.com", first_name: "John", last_name: "Doe")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test?p=42",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )

      view = Marten::Views::RecordListingSpec::TestView.new(request)

      page = view.paginate_queryset
      page.number.should eq 2
      page.to_a.should eq [user_3, user_4]
    end
  end

  describe "#queryset" do
    it "returns all the records for the configured model by default" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RecordListingSpec::TestView.new(request)

      view.queryset.to_a.should eq [user_1, user_2]
    end

    it "uses the configured ordering" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RecordListingSpec::TestViewWithOrdering.new(request)

      view.queryset.to_a.should eq [user_2, user_1]
    end

    it "raises as expected if the model is not configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      view = Marten::Views::RecordListingSpec::TestViewWithoutConfiguration.new(request)

      expect_raises(Marten::Views::Errors::ImproperlyConfigured) { view.queryset }
    end
  end
end

module Marten::Views::RecordListingSpec
  class TestView < Marten::View
    include Marten::Views::RecordListing

    model TestUser
    page_number_param "p"
    page_size 2
  end

  class TestViewWithOrdering < Marten::View
    include Marten::Views::RecordListing

    model TestUser
    ordering "-created_at"
  end

  class TestViewWithoutConfiguration < Marten::View
    include Marten::Views::RecordListing
  end
end
