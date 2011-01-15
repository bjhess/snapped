require File.dirname(__FILE__) + '/../vendor/maruku/maruku'
require 'flickraw'

class Photo
  include MongoMapper::Document
  
  key :title, String
  key :body, String
  key :original_url, String
  key :display_image_url, String
  key :slug, String
  key :taken_at, Time
  key :created_at, Time

	def url
		"/#{slug}"
	end

	def full_url
		Blog.url_base.gsub(/\/$/, '') + url
	end
	
	def previous_url
	 previous_photo = Photo.where(:created_at.lt => @created_at).sort(:created_at.desc).first
	 previous_photo ? previous_photo.url : nil
	end
	
	def next_url
 	 next_photo = Photo.where(:created_at.gt => @created_at).sort(:created_at).first
 	 next_photo ? next_photo.url : nil
	end

	def body_html
		to_html(body)
	end
	
	def body_feed_html
  	display_image_html + body_html
	end

	def summary
		@summary ||= body.match(/(.{200}.*?\n)/m)
		@summary || body
	end

	def summary_html
		display_image_html + to_html(summary.to_s)
	end
	
	def display_image_html
	 %{<img src="#{display_image_url}" />}
	end

	def generate_slug
	  slug = @title.downcase.gsub(/ /, '_').gsub(/[^a-z0-9_]/, '').squeeze('_')
	  same_slug_photo = Photo.where(:slug => slug).first
	  slug += '_' if same_slug_photo
	  @slug = slug
	end
	
	def slurp_flickr_information
	  return if original_url.blank?
	  FlickRaw.api_key = Blog.flickr_api_key
	  FlickRaw.shared_secret = Blog.flickr_shared_secret
	  photo_id = original_url.gsub(/\D/, '')
	  info = flickr.photos.getInfo(:photo_id => photo_id)

	  @display_image_url = FlickRaw.url_b(info)
	  @taken_at = Time.parse(info.dates.taken)
	  @title = info.title if @title.blank?
	  @body = info.description if @body.blank?
	end

	########

	def to_html(markdown)
		out = []
		noncode = []
		code_block = nil
		markdown.split("\n").each do |line|
			if !code_block and line.strip.downcase == '<code>'
				out << Maruku.new(noncode.join("\n")).to_html
				noncode = []
				code_block = []
			elsif code_block and line.strip.downcase == '</code>'
				convertor = Syntax::Convertors::HTML.for_syntax "ruby"
				highlighted = convertor.convert(code_block.join("\n"))
				out << "<code>#{highlighted}</code>"
				code_block = nil
			elsif code_block
				code_block << line
			else
				noncode << line
			end
		end
		out << Maruku.new(noncode.join("\n")).to_html
		out.join("\n")
	end

end
