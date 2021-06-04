#!/usr/bin/env ruby
#
# txt2sgi.rb
#
# This script converts the translation text files(.txt) into (.sgi) files for the game to load. 
# Put translated txt files into ./sgi_txt/en/
# Whitespace and newlines between the items will get trimmed.
#
# Translation file format:
# #ITEM_NUM (don't ommit the '#' and don't use the '#' at the start of the other lines)
# ITEM_NAME
# ITEM_STATS (as comma-separated array of decimal values)
#
# Usage:
#   ./txt2sgi.rb


puts "Starting txt2sgi.rb..."


##################
# Monkey-patch for creating the byte arrays
# https://stackoverflow.com/questions/5608918/pad-an-array-to-be-a-certain-size
class Array
  def rjust(n, x); Array.new([0, n-length].max, x)+self end
  def ljust(n, x); dup.fill(x, length...n) end
  def rjust!(n, x); insert(0, *Array.new([0, n-length].max, x)) end
  def ljust!(n, x); fill(x, length...n) end
end
##################


SGI_DIR = "./sgi"
SGI_TXT_DIR = "./sgi_txt"

sgi_ko_files = Dir["#{SGI_DIR}/ko/0*.sgi"] # e.g. ['sgi/ko/0000.sgi']

sgi_ko_files.each do |ko_filepath|
  puts "Loading #{ko_filepath}..."
  sgi_filename = File.basename(ko_filepath)
  txt_filename = sgi_filename.sub('.sgi','.txt')
  ko_file_contents = File.open(ko_filepath,"r:ISO-8859-1", &:read)

#  puts "  Parsing ko sgi file..."
  first_1_bytes = ko_file_contents[0..3]
  item_count = first_1_bytes.unpack('V').first # Total count seems to exclude the first 3 items which have weird item numbers
  second_1_bytes = ko_file_contents[4..7]
  item_payload_size = second_1_bytes.unpack('V').first # This byte may be the size of the item payloads, but the math is not clear; we have no reason to change it though
  #ko_item_contents = ko_file_contents[8..-1].unpack('V*')

  translation_keycode = 'en' # TODO: Translate all languages in the sgi_txt directory
  translated_filepath = "#{SGI_TXT_DIR}/#{translation_keycode}/#{txt_filename}"
  puts "Loading #{ko_filepath}..."
  txt_file_contents = File.open(translated_filepath,"r:ISO-8859-1", &:read)

  items_strings = txt_file_contents.split(/^#/)[1..-1].map do |item_info|
    item_num, item_name, item_stats = item_info.strip.split("\n")
    #puts "Item name: [#{item_name}]"
    #puts "Item num: [#{item_num}]"
    #puts "Item stats: [#{item_stats}]"

    # Bytes 1: Item Number (starting with #5 up to #91 for 87 weapons total)
    # Bytes 2-26: Name (in original Korean, no names take up more than 5 bytes)(TODO: Test that the name can actually take up all 20+ bytes, and that it's not just that the stats start late)
    # Bytes 27-41: Stat modifiers (unconfirmed)

    item_string = "".force_encoding("ISO-8859-1")
    item_string += [item_num.to_i].pack('V*').force_encoding("ISO-8859-1")
    item_string += item_name.unpack('a*').pack("a#{25*4}").force_encoding("ISO-8859-1")
    item_string += item_stats.gsub('[','').gsub(']','').split(',').map(&:to_i).pack('V*').force_encoding("ISO-8859-1")

  raise "ERROR: Resulting item ##{item_num} string is not properly sized: #{item_string.length} instead of 264 32-bit bytes." if item_string.length != 264

    item_string
  end

  raise "ERROR: Incorrect number of item translations, found #{items_strings.length} instead of 87." if items_strings.length != 87


  header = [87,16].pack("V*").force_encoding("ISO-8759-1")
  body = "".force_encoding("ISO-8859-1")
  body += items_strings.join("")

  output_file_path = "#{SGI_DIR}/#{translation_keycode}/#{sgi_filename}" # e.g. ./sgi/en/0000.sgi

  puts "Writing #{output_file_path}..."
  File.open(output_file_path,"w:ISO-8859-1") do |f|
    f.write(header)
    f.write(body)
  end
end


puts "Finished txt2sgi.rb\n"

