
puts
puts ARGV.inspect
puts

ARGV.each do |x|
  if x =~ /^[-]{1,2}([\w-]+)=(.*)$/
    puts "#$1 => #$2"
  end
end
