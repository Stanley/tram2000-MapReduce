$: << File.join(File.dirname(__FILE__), "/../lib")
require 'time'
require 'kanar'
require 'googlemaps_polyline/decoder'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each{|f| require f }
