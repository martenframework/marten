require "./spec_helper"

describe Marten::Routing::Match do
  describe "#path" do
    it "raises if the inserted rule is an empty string" do
      map = Marten::Routing::Map.new
      expect_raises(
        Marten::Routing::Errors::InvalidRuleName,
        "Route names cannot be empty"
      ) do
        map.path("/", Marten::Handlers::Base, name: "")
      end
    end

    it "raises if the inserted rule contains ':'" do
      map = Marten::Routing::Map.new
      expect_raises(
        Marten::Routing::Errors::InvalidRuleName,
        "Cannot use 'foo:bar' as a valid route name: route names cannot contain ':'"
      ) do
        map.path("/", Marten::Handlers::Base, name: "foo:bar")
      end
    end

    it "raises if the inserted rule name is already taken" do
      map = Marten::Routing::Map.new
      map.path("/", Marten::Handlers::Base, name: "home")
      expect_raises(Marten::Routing::Errors::InvalidRuleName) do
        map.path("/bis", Marten::Handlers::Base, name: "home")
      end
    end

    it "raises if the inserted rule is a path that contains duplicated parameter names" do
      map = Marten::Routing::Map.new
      expect_raises(Marten::Routing::Errors::InvalidRulePath) do
        map.path("/path/xyz/<id:int>/test<id:slug>/bad", Marten::Handlers::Base, name: "home")
      end
    end

    it "raises if the inserted rule is a map that contains duplicated parameter names" do
      map = Marten::Routing::Map.new
      expect_raises(Marten::Routing::Errors::InvalidRulePath) do
        sub_map = Marten::Routing::Map.draw do
          path("/bad/<id:int>/foobar", Marten::Handlers::Base, name: "home")
        end
        map.path("/path/xyz/<id:int>", sub_map, name: "included")
      end
    end
  end

  describe "#resolve" do
    it "is able to resolve a path that does not contain any parameter" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/xyz", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home", sub_map, name: "inc")

      match = map.resolve("/home/xyz")
      match.should be_a Marten::Routing::Match
      match = match.as(Marten::Routing::Match)
      match.handler.should eq Marten::Handlers::Base
      match.kwargs.should be_empty
    end

    it "is able to resolve a path that contains parameters" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home/xyz/<sid:slug>", sub_map, name: "inc")

      match = map.resolve("/home/xyz/my-slug/count/42/display")
      match.should be_a Marten::Routing::Match
      match = match.as(Marten::Routing::Match)
      match.handler.should eq Marten::Handlers::Base
      match.kwargs.should eq({"sid" => "my-slug", "number" => 42})
    end

    it "raises if the path does not match any registered route rule" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home/xyz/<sid:slug>", sub_map, name: "inc")

      expect_raises(Marten::Routing::Errors::NoResolveMatch) do
        map.resolve("/home")
      end
    end
  end

  describe "#reverse(name, **kwargs)" do
    it "returns the interpolated path for a top-level given route name without parameters" do
      map = Marten::Routing::Map.new
      map.path("/home/test", Marten::Handlers::Base, name: "home")

      map.reverse("home").should eq "/home/test"
    end

    it "can be used with a route name symbol" do
      map = Marten::Routing::Map.new
      map.path("/home/test", Marten::Handlers::Base, name: "home")

      map.reverse(:home).should eq "/home/test"
    end

    it "returns the interpolated path for a top-level given route name with parameters" do
      map = Marten::Routing::Map.new
      map.path("/home/<sid:slug>/test/<number:int>", Marten::Handlers::Base, name: "home")

      map.reverse("home", sid: "hello-world", number: 42).should eq "/home/hello-world/test/42"
    end

    it "returns the interpolated path for a sub given route name without parameters" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/xyz", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home", sub_map, name: "inc")

      map.reverse("inc:xyz").should eq "/home/xyz"
    end

    it "returns the interpolated path for a given sub route name with parameters" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home/xyz/<sid:slug>", sub_map, name: "inc")

      map.reverse("inc:xyz", sid: "hello-world", number: 42).should eq "/home/xyz/hello-world/count/42/display"
    end

    it "raises an error if the route name does not match any registered name" do
      map = Marten::Routing::Map.new
      map.path("/home/<sid:slug>/test/<number:int>", Marten::Handlers::Base, name: "home")

      expect_raises(Marten::Routing::Errors::NoReverseMatch) do
        map.reverse("name:inc", sid: "hello-world", number: 42)
      end
    end

    it "raises an error if the matched route name does not receive all the expected paramter" do
      map = Marten::Routing::Map.new
      map.path("/home/<sid:slug>/test/<number:int>", Marten::Handlers::Base, name: "home")

      expect_raises(Marten::Routing::Errors::NoReverseMatch) do
        map.reverse("home", sid: "hello-world")
      end
    end
  end

  describe "#reverse(name, params)" do
    it "returns the interpolated path for a top-level given route name without parameters" do
      map = Marten::Routing::Map.new
      map.path("/home/test", Marten::Handlers::Base, name: "home")

      map.reverse("home", {} of String => String).should eq "/home/test"
    end

    it "returns the interpolated path for a top-level given route name with parameters" do
      map = Marten::Routing::Map.new
      map.path("/home/<sid:slug>/test/<number:int>", Marten::Handlers::Base, name: "home")

      map.reverse("home", {"sid" => "hello-world", "number" => 42}).should eq "/home/hello-world/test/42"
    end

    it "can be used with a route name symbol" do
      map = Marten::Routing::Map.new
      map.path("/home/<sid:slug>/test/<number:int>", Marten::Handlers::Base, name: "home")

      map.reverse(:home, {"sid" => "hello-world", "number" => 42}).should eq "/home/hello-world/test/42"
    end

    it "returns the interpolated path for a sub given route name without parameters" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/xyz", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home", sub_map, name: "inc")

      map.reverse("inc:xyz", {} of String => String).should eq "/home/xyz"
    end

    it "returns the interpolated path for a given sub route name with parameters" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/count/<number:int>/display", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home/xyz/<sid:slug>", sub_map, name: "inc")

      map.reverse("inc:xyz", {"sid" => "hello-world", "number" => 42}).should(
        eq("/home/xyz/hello-world/count/42/display")
      )
    end

    it "raises an error if the route name does not match any registered name" do
      map = Marten::Routing::Map.new
      map.path("/home/<sid:slug>/test/<number:int>", Marten::Handlers::Base, name: "home")

      expect_raises(Marten::Routing::Errors::NoReverseMatch) do
        map.reverse("name:inc", {"sid" => "hello-world", "number" => 42})
      end
    end

    it "raises an error if the matched route name does not receive all the expected paramter" do
      map = Marten::Routing::Map.new
      map.path("/home/<sid:slug>/test/<number:int>", Marten::Handlers::Base, name: "home")

      expect_raises(Marten::Routing::Errors::NoReverseMatch) do
        map.reverse("home", {"sid" => "hello-world"})
      end
    end
  end
end
