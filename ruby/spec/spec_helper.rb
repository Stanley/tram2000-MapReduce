$: << File.join(File.dirname(__FILE__), "/../lib")
require 'kanar'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| p f; require f}
