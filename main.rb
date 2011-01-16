require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require 'builder'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'photo'

configure do
  if ENV['MONGOHQ_URL']
    MongoMapper.config = {ENV => {'uri' => ENV['MONGOHQ_URL']}}
  else
    MongoMapper.config = {ENV => {'uri' => 'mongodb://localhost/snapped'}}
  end
  MongoMapper.connect(ENV)
  
	require 'ostruct'
	Blog = OpenStruct.new(
		:title => 'a snapped photoblog',
		:author => 'Basil Fawlty',
		:url_base => 'http://example.com/',
		:admin_password => 'CHANGEME',
		:admin_cookie_key => 'snapped_admin',
		:admin_cookie_value => 'jsfgip5899u8rgu9490',
		:flickr_api_key => 'get_this_from_your_flickr_account',
		:flickr_shared_secret => 'get_this_from_your_flickr_account'
	)
end

error do
	e = request.env['sinatra.error']
	puts e.to_s
	puts e.backtrace.join("\n")
	"Application error"
end

helpers do
	def admin?
		request.cookies[Blog.admin_cookie_key] == Blog.admin_cookie_value
	end

	def auth
		halt(401, 'Not authorized') unless admin?
	end
	
	def link_nav_if_url(text, url, klass="")
	  url ?
	    "<a href='#{url}' class='enabled #{klass}'>#{text}</a>" :
      "<a href='#' class='disabled #{klass}' onclick='return false;'>#{text}</a>"
	end
end

layout 'layout'

### Auth

get '/auth' do
	erb :auth
end

post '/auth' do
	response.set_cookie(Blog.admin_cookie_key, Blog.admin_cookie_value) if params[:password] == Blog.admin_password
	redirect '/'
end

### Feed

get '/feed' do
	@photos = Photo.sort(:created_at.desc).limit(20)
	content_type 'application/atom+xml', :charset => 'utf-8'
	builder :feed
end

get '/rss' do
	redirect '/feed', 301
end

### Public

get '/' do
  photo = Photo.sort(:created_at.desc).limit(1).first
  if photo
	  erb :photo, :locals => { :photo => photo }
  else
    erb :no_photo
  end
end

get '/:slug' do
	photo = Photo.where(:slug => params[:slug]).first
	halt(404, "Page not found") unless photo
	@title = photo.title
	erb :photo, :locals => { :photo => photo }
end

### Admin

get '/photos/new' do
	auth
	erb :edit, :locals => { :photo => Photo.new, :url => '/photos' }
end

post '/photos' do
	auth
	photo = Photo.new :title => params[:title], :original_url => params[:original_url], :body => params[:body], :created_at => Time.now
  photo.slurp_flickr_information
  photo.generate_slug
	photo.save
	redirect photo.url
end

get '/:slug/edit' do
	auth
	photo = Photo.where(:slug => params[:slug]).first
	halt(404, "Page not found") unless photo
	erb :edit, :locals => { :photo => photo, :url => photo.url }
end

post '/:slug' do
	auth
	photo = Photo.where(:slug => params[:slug]).first
	halt(404, "Page not found") unless photo
	photo.title = params[:title]
	photo.body = params[:body]
	photo.original_url = params[:original_url]
  photo.slurp_flickr_information
	photo.save
	redirect photo.url
end

delete '/:slug' do
  auth
  photo = Photo.where(:slug => params[:slug]).first
	halt(404, "Page not found") unless photo
	photo.destroy
	redirect '/'
end

