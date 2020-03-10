module Blog
  ROUTES = Marten::Routing::Map.draw do
    path "/test/xyx", Views::Home, name: "home"
  end
end
