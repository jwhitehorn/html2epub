class Foo < Formula
  desc "html2epub"
  homepage "https://github.com/jwhitehorn/html2epub"
  url "https://github.com/jwhitehorn/html2epub/archive/9d3c4ab9db0a0cb21660076b9b250ed57a5dd091.tar.gz"
  sha256 "fe897255d32ae99e8770b0c0f93da50e77ef75f8dae73b48955f812e14445769"

  depends_on 'bundler' => :ruby

  def install
    libexec.install Dir["*"]

    system "bundle", "install"
    bin.install "main.rb" => "html2epub"
  end

end
