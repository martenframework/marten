require "./spec_helper"

describe Marten::DB::Model::AppConfig do
  describe "::inherited" do
    it "registers the model to the app registry and the associated app config" do
      config = Tag.app_config
      config.models.includes?(Tag).should be_true
    end

    it "does not register the model if it is abstract" do
      config = Tag.app_config
      config.models.includes?(AbstractArticle).should be_false
    end
  end

  describe "::app_config" do
    it "gives access to the associated app config" do
      Tag.app_config.should be_a TestApp
    end
  end
end
