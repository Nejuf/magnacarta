#!/usr/bin/env ruby
#
# txt2fpb.rb
#
# This script converts the translation text files(.txt) into the (.fpb) files loaded by the game.
# Put translation files into ./script/en/
# Separate dialogues(a.k.a. "lines") in the translation files by using "<>".  Whitespace between the dialogues will get trimmed.
# Use newlines (\r\n) or "$n" to tell the game to split the dialogue onto a new line in the dialogue box.
#
# Usage:
#   ./txt2fpb.rb


puts "Starting txt2fpb.rb..."

# TODO: Translate for every language folder in ./script/
SCRIPT_DIR = "./script/en"
FPB_DIR = "./fpb/en"
KOREAN_FPB_DIR = "./fpb/ko"

#puts "SCRIPT_DIR #{SCRIPT_DIR}"
#puts "FPB_DIR #{FPB_DIR}"
#puts "KOREAN_FPB_DIR #{KOREAN_FPB_DIR}"

translation_files = Dir["#{SCRIPT_DIR}/0*.txt"] # e.g. ['script/en/0092.txt']

translation_files.each do |translation_filepath|
  puts "Loading #{translation_filepath}..."
  translation_filename = File.basename(translation_filepath)
  fpb_filename = translation_filename.sub('.txt','.fpb')
  translation_contents = File.open(translation_filepath,"r:ISO-8859-1", &:read)
  ko_file_contents = File.open("#{KOREAN_FPB_DIR}/#{fpb_filename}","r:ISO-8859-1", &:read)

#  puts "  Parsing source files..."
  first_4_bytes = ko_file_contents[0..3]
  dialogue_count = first_4_bytes.unpack('V').first
  total_header_length = 3 * 4 * dialogue_count # 3x 32-bit header bytes, each being 4x 8-bit bytes
  ko_line_headers = ko_file_contents[4..(total_header_length+4)].unpack('V*')
  string_tags = []

#  puts "  Harvesting string IDs..."
  i = 0
  while i < ko_line_headers.count
    string_tags.push(ko_line_headers[i]) # The string tags always end up being 0,1,2..etc, but we'll parse them from the korean FPB file just in case.
    i += 3
  end

#  puts "  Converting text to FPB string library..."
  line_array = translation_contents.strip.split('<>')

#  puts "  Sanitizing..."
  line_array.map!{|line|line.strip}
  header = [line_array.count].pack("V*").force_encoding("ISO-8859-1")
  sub_off = 0

  if line_array.count != string_tags.count
    raise StandardError.new("FATAL ERROR: The number of translation lines in the Korean (#{KOREAN_FPB_DIR}/#{fpb_filename}) and translation file (#{SCRIPT_DIR}/#{translation_filename}) does not match! (KO='#{string_tags.count}' EN='#{line_array.count}')")
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

