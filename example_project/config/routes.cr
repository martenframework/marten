Marten.routes.draw do
  path "/", Blog::Views::Home, name: "home"
  path "/included", Blog::ROUTES, name: "included"
end
