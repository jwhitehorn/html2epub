require 'gepub'
require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'securerandom'
require 'tempfile'
require 'json'
require 'args_parser'


def process_chapter book, all_contents, url, filename, login
  contents = nil
  if login.nil?
    contents = open(url)
  else
    a = Mechanize.new
    a.get(url) do |page|

      desired_page = page.form_with(:action => login["action"]) do |f|
        f.log = login["username"]
        f.pwd = login["password"]
      end.click_button

      contents = desired_page.content
    end
  end

  doc = Nokogiri::HTML(contents)
  xhtmlWrapper = File.open("template.xhtml").read

  f = Tempfile.new filename

  doc.css('h2').each do |headline|
    #force page break before sections
    headline.before '<div style="page-break-before:always;"></div>'
  end

  doc.css('script').each do |script|
    src = script.attribute 'src'
    unless src.nil?
      matches = src.to_s.match /https:\/\/gist.github.com\/([^\/]+)\/([^.]*)\.js/
      if matches != nil && matches.captures.length > 1
        #gist
        user = matches.captures[0]
        hash = matches.captures[1]

        url = "https://gist.githubusercontent.com/#{user}/#{hash}/raw"
        code = open(url) { |io| io.read }
        script.before "<pre><code>#{code}</code></pre>"
      end
    end
    script.remove
  end

  doc.css('img').each do |img|
    id = SecureRandom.uuid

    ext = img['src'].scan(/\.([^.]+)$/)[0][0]
    unless ext.nil?
      link = "#{id}.#{ext}"
      file = Tempfile.new link
      file.binmode

      file.write open(img['src']).read
      book.add_item "html/#{link}", file.path
      file.close
      file.unlink

      img['src'] = link
      unless img['srcset'].nil?
        img.remove_attribute 'srcset'
      end
    end
  end

  doc.css('a').each do |anchor|
    href = anchor['href']
    content = all_contents.detect { |c| c["url"] == href }
    unless content.nil?
      anchor[:href] = content["file"]
    end
  end

  doc.css('.wp-post-navigation').remove
  doc.css('.adsbygoogle').remove

  contents = xhtmlWrapper.gsub /PLACEHOLDER/, doc.search('article').to_xhtml

  f.write contents
  f.close
  {file: f, resource: filename}
end




args = ArgsParser.parse ARGV do
  arg :url, 'URL', :alias => :u
  arg :output, 'output file', :alias => :o, :default => 'book.epub'
  arg :toc, 'Table of Contents'
  arg :cover, 'Cover Image'
  arg :verbose, 'verbose mode'
  arg :help, 'show help', :alias => :h
  arg :lang, 'Language', :default => 'en'
  arg :title, 'Title', :alias => :t
  arg :subtitle, 'Sub Title'
  arg :author, 'Author', :alias => :a
  arg :contents, 'Contents File', :default => 'contents.json'
end

if args.has_option? :help
  STDERR.puts args.help
  exit 1
end

if !args.has_param?(:toc)
  puts "Please specify a table of contents file."
  exit 1
end

if !args.has_param?(:cover)
  puts "Please specify a cover image."
  exit 1
end

contents = JSON.parse(File.read(args[:contents]))

book = GEPUB::Book.new
book.primary_identifier args[:url], 'BookID', 'URL'
book.language args[:lang]
book.add_title(args[:title], nil, GEPUB::TITLE_TYPE::MAIN) if args.has_param?(:title)
book.add_title(args[:subtitle], nil, GEPUB::TITLE_TYPE::SUBTITLE) if args.has_param?(:subtitle)
book.add_creator(args[:author]) if args.has_param?(:author)

chapters = []
contents.each do |content|
  chapters << process_chapter(book, contents, content["url"], content["file"], content["login"])
end

book.ordered {
  chapters.each do |chapter|
    file = chapter[:file]
    book.add_item chapter[:resource], file.path
    file.unlink
  end

  book.add_item('html/toc.xhtml', args[:toc]).add_property('nav')
}
book.add_item('html/cover.png', args[:cover]).cover_image


epubname = File.join(File.dirname(__FILE__), args[:output])
book.generate_epub(epubname)
