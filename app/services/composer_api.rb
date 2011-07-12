class ComposerApi < ActionWebService::API::Base
  api_method :compose_exact_match, :expects => [SmartServiceGraph], :returns => [SmartServiceGraph]
  api_method :compose_plugin_math, :expects => [SmartServiceGraph], :returns => [SmartServiceGraph]
end
