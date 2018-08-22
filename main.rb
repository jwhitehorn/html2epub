#!/usr/bin/env ruby

require 'gepub'
require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'securerandom'
require 'tempfile'
require 'json'
require 'args_parser'

VERSION = "0.1"
LICENSE = <<EOL
Copyright (c) 2018, Jason Whitehorn
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

EOL


def process_chapter book, all_contents, url, filename, login, opts
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
  
  headlines = {
    "h1" => :h1break,
    "h2" => :h2break,
    "h3" => :h3break,
    "h4" => :h4break,
  }
  headlines.each do |tag, option|
    if opts[option] != "none"
      parts = opts[option].split ' '
      mode = parts.length > 1 ? parts[1] : "before"
      setting = parts.length > 0 ? parts[0] : "auto"
      doc.css(tag).each do |headline|
        headline.before "<div style='page-break-#{mode}:#{setting};'></div>"
      end
    end
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
  arg :version, 'Display html2epub version', :alias => :v
  arg :copyright, 'Display html2epub copyright information', :alias => :c
  arg :lang, 'Language', :default => 'en'
  arg :title, 'Title', :alias => :t
  arg :subtitle, 'Sub Title'
  arg :author, 'Author', :alias => :a
  arg :contents, 'Contents File', :default => 'contents.json'
  arg :stylesheet, "Optional stylesheet"
  arg :h1break, "Page break settings for h1 tags", :default => "right"
  arg :h2break, "Page break settings for h2 tags", :default => "avoid after"
  arg :h3break, "Page break settings for h3 tags", :default => "none"
  arg :h4break, "Page break settings for h4 tags", :default => "none"
end

if args.has_option? :help
  STDERR.puts args.help
  exit 1
end

if args.has_option? :version
  puts "html2epub #{VERSION}"
  exit 1
end

if args.has_option? :copyright
  puts "html2epub #{VERSION}"
  puts LICENSE
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
  chapters << process_chapter(book, contents, content["url"], content["file"], content["login"], args)
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

stylesheet_path = "empty.css"
if args.has_param? :stylesheet
  stylesheet_path = File.join(Dir.pwd, args[:stylesheet])
end
book.add_item('html/style.css', stylesheet_path)


epubname = File.join(Dir.pwd, args[:output])
book.generate_epub(epubname)
