require "./spec_helper"

describe Marten::Handlers::RecordListing do
  describe "::model(model)" do
    it "allows to configure the model used to retrieve the record" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "",
        headers: HTTP::Headers{"Host" => "example.com"}
      )

      Marten::Handlers::RecordListingSpec::TestHandler.new(request).model.should eq TestUser
    end
  end

  describe "::page_number_param" do
    it "returns the configured page number param" do
      Marten::Handlers::RecordListingSpec::TestHandler.page_number_param.should eq "p"
    end

    it "returns the expected default value if no other value is set" do
      Marten::Handlers::RecordListingSpec::TestHandlerWithoutConfiguration.page_number_param.should eq "page"
    end
  end

  describe "::page_number_param(param)" do
    it "allows to configure the page number param" do
      Marten::Handlers::RecordListingSpec::TestHandler.page_number_param.should eq "p"
    end
  end

  describe "::page_size" do
    it "returns the configured page size" do
      Marten::Handlers::RecordListingSpec::TestHandler.page_size.should eq 2
    end

    it "returns the expected default value if no other value is set" do
      Marten::Handlers::RecordListingSpec::TestHandlerWithoutConfiguration.page_size.should be_nil
    end
  end

  describe "::page_size(size)" do
    it "allows to configure the page size" do
      Marten::Handlers::RecordListingSpec::TestHandler.page_size.should eq 2
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

      params_1 = Marten::Routing::MatchParameters{"p" => 1}
      handler_1 = Marten::Handlers::RecordListingSpec::TestHandler.new(request, params_1)
      page_1 = handler_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      params_2 = Marten::Routing::MatchParameters{"p" => 2}
      handler_2 = Marten::Handlers::RecordListingSpec::TestHandler.new(request, params_2)
      page_2 = handler_2.paginate_queryset
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

      params_1 = Marten::Routing::MatchParameters{"p" => "1"}
      handler_1 = Marten::Handlers::RecordListingSpec::TestHandler.new(request, params_1)
      page_1 = handler_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      params_2 = Marten::Routing::MatchParameters{"p" => "2"}
      handler_2 = Marten::Handlers::RecordListingSpec::TestHandler.new(request, params_2)
      page_2 = handler_2.paginate_queryset
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
      handler_1 = Marten::Handlers::RecordListingSpec::TestHandler.new(request_1)
      page_1 = handler_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test?p=2",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler_2 = Marten::Handlers::RecordListingSpec::TestHandler.new(request_2)
      page_2 = handler_2.paginate_queryset
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

      handler = Marten::Handlers::RecordListingSpec::TestHandler.new(request)

      page = handler.paginate_queryset
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
      handler_1 = Marten::Handlers::RecordListingSpec::TestHandler.new(request_1)
      page_1 = handler_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      request_2 = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "/test?p=bar",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler_2 = Marten::Handlers::RecordListingSpec::TestHandler.new(request_2)
      page_2 = handler_2.paginate_queryset
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

      handler = Marten::Handlers::RecordListingSpec::TestHandler.new(request)

      page = handler.paginate_queryset
      page.number.should eq 2
      page.to_a.should eq [user_3, user_4]
    end

    it "paginates as expected when a the #queryset macro was used" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "foo@example.com", first_name: "Foo", last_name: "Test")
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

      params_1 = Marten::Routing::MatchParameters{"p" => 1}
      handler_1 = Marten::Handlers::RecordListingSpec::TestHandlerWithQueryset.new(request, params_1)
      page_1 = handler_1.paginate_queryset
      page_1.number.should eq 1
      page_1.to_a.should eq [user_1, user_2]

      params_2 = Marten::Routing::MatchParameters{"p" => 2}
      handler_2 = Marten::Handlers::RecordListingSpec::TestHandlerWithQueryset.new(request, params_2)
      page_2 = handler_2.paginate_queryset
      page_2.number.should eq 2
      page_2.to_a.should eq [user_3, user_4]
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
      handler = Marten::Handlers::RecordListingSpec::TestHandler.new(request)

      handler.queryset.to_a.should eq [user_1, user_2]
    end

    it "returns the expected queryset when the #queryset macro was used" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "foo@example.com", first_name: "Foo", last_name: "Test")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordListingSpec::TestHandlerWithQueryset.new(request)

      handler.queryset.to_a.should eq [user_1, user_2]
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
      handler = Marten::Handlers::RecordListingSpec::TestHandlerWithOrdering.new(request)

      handler.queryset.to_a.should eq [user_2, user_1]
    end

    it "uses the configured ordering when the #queryset macro was used" do
      user_1 = TestUser.create!(username: "jd1", email: "jd1@example.com", first_name: "John", last_name: "Doe")
      user_2 = TestUser.create!(username: "jd2", email: "jd2@example.com", first_name: "John", last_name: "Doe")
      TestUser.create!(username: "foo", email: "foo@example.com", first_name: "Foo", last_name: "Test")

      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordListingSpec::TestHandlerWithQuerysetAndOrdering.new(request)

      handler.queryset.to_a.should eq [user_2, user_1]
    end

    it "raises as expected if the model is not configured" do
      request = Marten::HTTP::Request.new(
        ::HTTP::Request.new(
          method: "GET",
          resource: "",
          headers: HTTP::Headers{"Host" => "example.com"}
        )
      )
      handler = Marten::Handlers::RecordListingSpec::TestHandlerWithoutConfiguration.new(request)

      expect_raises(Marten::Handlers::Errors::ImproperlyConfigured) { handler.queryset }
    end
  end
end

module Marten::Handlers::RecordListingSpec
  class TestHandler < Marten::Handler
    include Marten::Handlers::RecordListing

    model TestUser
    page_number_param "p"
    page_size 2
  end

  class TestHandlerWithOrdering < Marten::Handler
    include Marten::Handlers::RecordListing

    model TestUser
    ordering "-username"
  end

  class TestHandlerWithQueryset < Marten::Handler
    include Marten::Handlers::RecordListing

    queryset TestUser.filter(username__startswith: "jd")
    page_number_param "p"
    page_size 2
  end

  class TestHandlerWithQuerysetAndOrdering < Marten::Handler
    include Marten::Handlers::RecordListing

    queryset TestUser.filter(username__startswith: "jd")
    ordering "-username"
  end

  class TestHandlerWithoutConfiguration < Marten::Handler
    include Marten::Handlers::RecordListing
  end
end
