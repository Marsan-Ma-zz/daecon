#!/usr/bin/env ruby
# encoding: utf-8

require 'zhconv'

#==========================================
#   Use TW Char Dictionary
#==========================================
chars = []
f = File.open("./chars/chars_tw.dic", "r")
puts "Reading ./chars/chars_tw.dic ..."
f.each_line do |line|
  c = line.split(" ")
  chars << [c[0], c[1]]
end

open("chars.dic", 'w') do |f|
  puts "Writing chars.dic ..."
  chars.each do |c|
    f.puts c[1] + " " + c[0]
  end
end

def str2dic(filename, zhtype, str)
  if zhtype
    raw = ZhConv.convert(zhtype, str) #, false)
  else
    raw = str
  end
  words = raw.split(' ').uniq
  
  open(filename, 'w') do |f|
    puts "Writing to " + filename + " ..."
    words.each do |i|
      f.puts i.size.to_s + " " + i
    end
  end
end

#==========================================
#   Merge Words Dictionary
#==========================================
raw = ""
Dir.glob("./words/*").each do |filename|
  puts "Include File : " + filename
  raw += File.open(filename, "rb").read
end
raw = raw.force_encoding('UTF-8')

puts "Converting to zh-mix dic ..." 
str2dic("words_mix.dic", nil, raw)

puts "Converting to zh-tw dic ..." 
str2dic("words_tw.dic", 'zh-tw', raw)

puts "Converting to zh-cn dic ..." 
str2dic("words_cn.dic", 'zh-cn', raw)


