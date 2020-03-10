module Blog
  ROUTES = Marten::Conf::Routing::Map.draw do
    path "/test/xyx", Views::Home, name: "home"
  end
end
