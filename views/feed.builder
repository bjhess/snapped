xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
	xml.title Blog.title
	xml.id Blog.url_base
	xml.updated @photos.first[:created_at].iso8601 if @photos.any?
	xml.author { xml.name Blog.author }

	@photos.each do |photo|
		xml.entry do
			xml.title photo[:title]
			xml.link "rel" => "alternate", "href" => photo.full_url
			xml.id photo.full_url
			xml.published photo[:created_at].iso8601
			xml.updated photo[:created_at].iso8601
			xml.author { xml.name Blog.author }
			xml.summary photo.summary_html, "type" => "html"
			xml.content photo.body_feed_html, "type" => "html"
		end
	end
end
