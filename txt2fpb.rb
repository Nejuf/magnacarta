#!/usr/bin/env ruby

puts "Starting txt2fpb.rb..."

SCRIPT_DIR = "./script/en"
FPB_DIR = "./fpb/en"
KOREAN_FPB_DIR = "./fpb/ko"

puts "SCRIPT_DIR #{SCRIPT_DIR}"
puts "FPB_DIR #{FPB_DIR}"
puts "KOREAN_FPB_DIR #{KOREAN_FPB_DIR}"

script_files = Dir["#{SCRIPT_DIR}/0*.txt"] # e.g. ['script/en/0092.txt']

script_files.each do |script_filepath|
  puts "Loading #{script_filepath}..."
  script_filename = File.basename(script_filepath)
  fpb_filename = script_filename.sub('.txt','.fpb')
  script_file_contents = File.open(script_filepath,"r:ISO-8859-1", &:read)
  ko_file_contents = File.open("#{KOREAN_FPB_DIR}/#{fpb_filename}","r:ISO-8859-1", &:read)

  puts "  Parsing source files..."
  first_4_bytes = ko_file_contents[0..3]
  kor_count = first_4_bytes.unpack('V').first
  header_length = 4 * 3 * kor_count
  lele = ko_file_contents[4..(header_length+4)].unpack('V*')
  i = 0
  line_count = lele.count
  string_tags = []

  puts "  Harvesting string IDs..."
  while i < line_count
    string_tags.push(lele[i])
    i += 3
  end

  puts "  Converting text to FPB string library..."
  line_array = script_file_contents.strip.split('<>')

  puts "  Sanitizing..."
  line_array.map!{|line|line.strip}
  header = [line_array.count].pack("V*").force_encoding("ISO-8859-1")
  sub_off = 0

  if line_array.count != string_tags.count
    raise StandardError.new("FATAL ERROR: The number of lines in the Korean and English files (#{script_filename}) does not match! (KO='#{string_tags.count}' EN='#{line_array.count}')")
  end

  line_array.each_with_index do |line,i|
    header += [string_tags[i]].pack("V*").force_encoding("ISO-8859-1")
    header += [sub_off].pack("V*").force_encoding("ISO-8859-1")
    header += [line.gsub("\r\n","$n").length+1].pack("V*").force_encoding("ISO-8859-1")
    sub_off += line.length+1
  end
  header += [sub_off].pack("V*").force_encoding("ISO-8859-1")
  body = "".force_encoding("ISO-8859-1")
  line_array.each do |line|
    body += (line.gsub("\r\n","$n") + 0.chr).force_encoding("ISO-8859-1")
  end
  output_file_path = "#{FPB_DIR}/#{fpb_filename}" # e.g. ./fpb/en/0134.fpb

  puts "Writing #{output_file_path}..."
  File.open(output_file_path,"w:ISO-8859-1") do |f|
    f.write(header)
    f.write(body)
  end
end


puts "Finished txt2fpb.rb\n"

