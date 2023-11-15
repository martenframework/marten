# The main routes map associates routes to handlers.
# For more information please see: https://martenframework.com/docs/handlers-and-http/routing
Marten.routes.draw do
  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>",
      Marten::Handlers::Defaults::Development::ServeMediaFile,
      name: "media_file"
  end
end
