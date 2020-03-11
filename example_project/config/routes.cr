Marten.routes.draw do
  path "/", Blog::Views::Home, name: "home"
  path "/home/bis", Blog::Views::Home, name: "home_bis"
  path "/included", Blog::ROUTES, name: "included"
end
