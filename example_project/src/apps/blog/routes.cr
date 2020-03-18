module Blog
  ROUTES = Marten::Routing::Map.draw do
    path "/test/xyx", Views::Home, name: "home"
    path "/test/xyx/<number:int>", Views::Home, name: "home_with_int"
  end
end
