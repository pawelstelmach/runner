class Service < ActiveResource::Base
	self.site = "http://#{APP_CONFIG['services_url']}/"
	self.timeout = 1.hour
end