require "./test_project/**"

Marten.routes.draw do
  path "/dummy", DummyView, name: "dummy"
  path "/dummy/<id:int>", DummyView, name: "dummy_with_id"
end
