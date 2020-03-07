Marten.routes.draw do |map|
  map.path("/", Blog::Views::Home, name: "home")
end
