Marten.routes.draw do
  path "/", Blog::Views::Home, name: "home"
  path "/home/bis", Blog::Views::Home, name: "home_bis"
  path "/home/string/<id:str>/test", Blog::Views::Home, name: "home_with_string_arg"
  path "/home/int/<id:int>/test", Blog::Views::Home, name: "home_with_int_arg"
  path "/included", Blog::ROUTES, name: "included"
  path "/included/<id:str>/test", Blog::ROUTES, name: "included_with_arg"
end
