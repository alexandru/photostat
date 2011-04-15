require 'all_your_base'

module FileHash

  def self.file_md5(file)
      out = `md5sum #{file}`
      out =~ /^(\S+)/
      $1.strip
  end

  def self.calculate(file)
    base16charset = ('0'..'9').to_a + ('a'..'f').to_a
    base16 = AllYourBase::Are.new({:charset => base16charset})
    base62 = AllYourBase::Are.new({:charset => AllYourBase::Are::BASE_62_CHARSET})

    md5 = file_md5(file).to_s.strip
    ret = base16.convert_to_base_10(md5)
    base62.convert_from_base_10(ret)
  end
end


if __FILE__ == $0 and ARGV.length
  puts FileHash.calculate(ARGV[0])
end
