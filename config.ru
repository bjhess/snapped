require 'rubygems'
require 'bundler'

Bundler.require

set :run,           false
set :views,         File.join(File.dirname(__FILE__), 'views')
set :environment,   ENV['RACK_ENV']
set :raise_errors,  true

require 'main'
run Sinatra::Application
