require "./spec_helper"

describe Marten::DB::Router do
  describe "::db_for_read" do
    it "returns nil when no routers are configured" do
      Marten::DB::Router.db_for_read(Tag).should be_nil
    end

    it "returns the first non-nil opinion from configured routers" do
      routers = [
        Marten::DB::RouterSpec::AbstainingRouter,
        Marten::DB::RouterSpec::OtherDBRouter,
      ] of Marten::DB::Router::Base.class
      with_overridden_setting(:database_routers, routers) do
        Marten::DB::Router.db_for_read(Tag).should eq "other"
      end
    end
  end

  describe "::db_for_write" do
    it "returns nil when no routers are configured" do
      Marten::DB::Router.db_for_write(Tag).should be_nil
    end

    it "returns the first non-nil opinion from configured routers" do
      routers = [Marten::DB::RouterSpec::PrimaryReplicaRouter] of Marten::DB::Router::Base.class
      with_overridden_setting(:database_routers, routers) do
        Marten::DB::Router.db_for_write(Tag).should eq "default"
      end
    end
  end

  describe "::allow_relation?" do
    it "returns true when no routers are configured" do
      tag_1 = Tag.new(name: "coding", is_active: true)
      tag_2 = Tag.new(name: "crystal", is_active: true)

      Marten::DB::Router.allow_relation?(tag_1, tag_2).should be_true
    end

    it "returns the first non-nil opinion from configured routers" do
      routers = [Marten::DB::RouterSpec::DenyRelationRouter] of Marten::DB::Router::Base.class
      with_overridden_setting(:database_routers, routers) do
        tag_1 = Tag.new(name: "coding", is_active: true)
        tag_2 = Tag.new(name: "crystal", is_active: true)

        Marten::DB::Router.allow_relation?(tag_1, tag_2).should be_false
      end
    end
  end

  describe "::allow_migrate?" do
    it "returns true when no routers are configured" do
      Marten::DB::Router.allow_migrate?("default", "app").should be_true
    end

    it "returns the first non-nil opinion from configured routers" do
      routers = [Marten::DB::RouterSpec::AppMigrateRouter] of Marten::DB::Router::Base.class
      with_overridden_setting(:database_routers, routers) do
        Marten::DB::Router.allow_migrate?("other", "app").should be_true
        Marten::DB::Router.allow_migrate?("other", "other_app").should be_false
        Marten::DB::Router.allow_migrate?("default", "app").should be_false
      end
    end
  end
end

module Marten::DB::RouterSpec
  class AbstainingRouter < Marten::DB::Router::Base
  end

  class OtherDBRouter < Marten::DB::Router::Base
    def db_for_read(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "other"
    end
  end

  class PrimaryReplicaRouter < Marten::DB::Router::Base
    def db_for_write(
      model : Marten::DB::Model.class,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : String?
      "default"
    end
  end

  class DenyRelationRouter < Marten::DB::Router::Base
    def allow_relation?(
      obj1 : Marten::DB::Model,
      obj2 : Marten::DB::Model,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : Bool?
      false
    end
  end

  class AppMigrateRouter < Marten::DB::Router::Base
    def allow_migrate?(
      db : String,
      app_label : String,
      model_name : String? = nil,
      hints : Marten::DB::Router::Hints = Marten::DB::Router::Hints.new,
    ) : Bool?
      return app_label == "app" if db == "other"
      return app_label != "app" if db == "default"
      nil
    end
  end
end
