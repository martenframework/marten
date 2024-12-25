require "./spec_helper"

describe Marten::Routing::Match do
  describe "#localized" do
    it "raises if the map is not the root one" do
      map = Marten::Routing::Map.new

      expect_raises(Marten::Routing::Errors::InvalidRouteMap, "Cannot define localized routes in a non-root map") do
        map.localized do
          path t("routes.blog"), Marten::Handlers::Base, name: "blog"
        end
      end
    end

    it "allows to define localized routes" do
      map = Marten::Routing::Map.new
      map.exposed_root = true

      map.localized do
        path t("routes.foo_bar"), Marten::Handlers::Base, name: "foo_bar"
      end

      map.rules.size.should eq 1
      map.rules.first.should be_a Marten::Routing::Rule::Localized

      map.reverse("foo_bar").should eq "/en/foo/bar"

      I18n.with_locale(:fr) do
        map.reverse("foo_bar").should eq "/fr/foo-french/bar-french"
      end
    end

    it "allows to define localized routes without the default locale prefix" do
      map = Marten::Routing::Map.new
      map.exposed_root = true

      map.localized(prefix_default_locale: false) do
        path t("routes.foo_bar"), Marten::Handlers::Base, name: "foo_bar"
      end

      map.rules.size.should eq 1
      map.rules.first.should be_a Marten::Routing::Rule::Localized

      map.reverse("foo_bar").should eq "/foo/bar"

      I18n.with_locale(:fr) do
        map.reverse("foo_bar").should eq "/fr/foo-french/bar-french"
      end
    end

    it "raises when defining nested localized rules" do
      map = Marten::Routing::Map.new
      map.exposed_root = true

      expect_raises(Marten::Routing::Errors::InvalidRouteMap, "Cannot define nested localized routes") do
        map.localized do
          path t("routes.foo_bar"), Marten::Handlers::Base, name: "foo_bar"

          map.localized do
            path t("routes.foo_bar"), Marten::Handlers::Base, name: "other_foo_bar"
          end
        end
      end
    end

    it "raises when defining multiple localized rules" do
      map = Marten::Routing::Map.new
      map.exposed_root = true

      map.localized do
        path t("routes.foo_bar"), Marten::Handlers::Base, name: "foo_bar"
      end

      expect_raises(Marten::Routing::Errors::InvalidRouteMap, "Cannot define multiple localized rules") do
        map.localized do
          path t("routes.foo_bar"), Marten::Handlers::Base, name: "other_foo_bar"
        end
      end
    end
  end

  describe "#path" do
    it "can be used with a translated path" do
      map = Marten::Routing::Map.new
      map.path(Marten::Routing::TranslatedPath.new("routes.foo_bar"), Marten::Handlers::Base, name: "foo_bar")

      map.reverse("foo_bar").should eq "/foo/bar"
    end

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

    context "while localizing" do
      it "allows to define localized routes" do
        map = Marten::Routing::Map.new
        map.exposed_root = true

        map.localized do
          path t("routes.foo_bar"), Marten::Handlers::Base, name: "foo_bar"
          path t("routes.foo_bar_with_args"), Marten::Handlers::Base, name: "foo_bar_with_args"
        end

        map.reverse("foo_bar").should eq "/en/foo/bar"
        map.reverse("foo_bar_with_args", param1: 42, param2: "hello-world").should eq "/en/foo/42/bar/hello-world"

        I18n.with_locale(:fr) do
          map.reverse("foo_bar").should eq "/fr/foo-french/bar-french"
          map.reverse("foo_bar_with_args", param1: 42, param2: "hello-world").should eq "/fr/foo/42/bar/hello-world"
        end
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

    it "raises if the inserted rule is a path that contains duplicated parameter names" do
      map = Marten::Routing::Map.new
      map.path("/path/xyz/<id:int>/test<id:slug>/bad", Marten::Handlers::Base, name: "home")

      expect_raises(Marten::Routing::Errors::InvalidRulePath) do
        map.reverse("home", id: 42)
      end
    end

    it "raises if the inserted rule is a map that contains duplicated parameter names" do
      map = Marten::Routing::Map.new
      sub_map = Marten::Routing::Map.draw do
        path("/bad/<id:int>/foobar", Marten::Handlers::Base, name: "home")
      end
      map.path("/path/xyz/<id:int>", sub_map, name: "included")

      expect_raises(Marten::Routing::Errors::InvalidRulePath) do
        map.reverse("included:home", id: 42)
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

    it "returns the interpolated path for a sub given route name mounted without name parameters" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/xyz", Marten::Handlers::Base, name: "inc_xyz")

      map = Marten::Routing::Map.new
      map.path("/home", sub_map)

      map.reverse("inc_xyz", {} of String => String).should eq "/home/xyz"
    end

    it "returns the interpolated path for a sub given route name mounted with namespace" do
      sub_map = Marten::Routing::Map.new(:inc)
      sub_map.path("/xyz", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home", sub_map)

      map.reverse("inc:xyz", {} of String => String).should eq "/home/xyz"
    end

    it "returns the interpolated path for a sub with the name instead of the namespace" do
      sub_map = Marten::Routing::Map.new
      sub_map.path("/xyz", Marten::Handlers::Base, name: "xyz")

      map = Marten::Routing::Map.new
      map.path("/home", sub_map, :not_inc)

      map.reverse("not_inc:xyz", {} of String => String).should eq "/home/xyz"
    end

    it "returns the interpolated path for a sub sub map" do
      article_map = Marten::Routing::Map.new :article
      article_map.path("/list", Marten::Handlers::Base, name: "list")

      admin_map = Marten::Routing::Map.new
      admin_map.path("/articles", article_map)

      map = Marten::Routing::Map.new
      map.path("/articles", article_map)
      map.path("/admin", admin_map, name: :admin)

      map.reverse("article:list", {} of String => String).should eq "/articles/list"
      map.reverse("admin:article:list", {} of String => String).should eq "/admin/articles/list"
    end

    it "returns the interpolated path for a sub with the name instead of the namespace" do
      article_map = Marten::Routing::Map.new :article
      article_map.path("/list", Marten::Handlers::Base, name: "list")

      map = Marten::Routing::Map.new
      map.path("/articles", article_map, name: :not_article)

      map.reverse("not_article:list", {} of String => String).should eq "/articles/list"
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

  describe "#t" do
    it "returns a translated path" do
      map = Marten::Routing::Map.new
      map.t("simple.translation").should eq Marten::Routing::TranslatedPath.new("simple.translation")
    end
  end
end
