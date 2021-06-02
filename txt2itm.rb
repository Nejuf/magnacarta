#!/usr/bin/env ruby
#
# txt2itm.rb
#
# This script converts the translation text files(.txt) into (.itm) files for the game to load. 
# Put translated txt files into ./itm_txt/en/
# Whitespace and newlines between the items will get trimmed.
#
# Translation file format:
# #ITEM_NUM (don't ommit the '#' and don't use the '#' at the start of the other lines)
# ITEM_NAME
# ITEM_DESCRIPTION
# ITEM_STATS (as comma-separated array of 14 decimal values)
#
# Usage:
#   ./txt2itm.rb


puts "Starting txt2itm.rb..."


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


ITM_DIR = "./itm"
ITM_TXT_DIR = "./itm_txt"

itm_ko_files = Dir["#{ITM_DIR}/ko/0*.itm"] # e.g. ['itm/ko/0000.itm']

itm_ko_files.each do |ko_filepath|
  puts "Loading #{ko_filepath}..."
  itm_filename = File.basename(ko_filepath)
  txt_filename = itm_filename.sub('.itm','.txt')
  ko_file_contents = File.open(ko_filepath,"r:ISO-8859-1", &:read)

#  puts "  Parsing ko itm file..."
  first_1_bytes = ko_file_contents[0..3]
  item_count = first_1_bytes.unpack('V').first # Total count seems to exclude the first 3 items which have weird item numbers
  second_1_bytes = ko_file_contents[4..7]
  item_payload_size = second_1_bytes.unpack('V').first # This byte may be the size of the item payloads, but the math is not clear; we have no reason to change it though
  #ko_item_contents = ko_file_contents[8..-1].unpack('V*')

  translation_keycode = 'en' # TODO: Translate all languages in the itm_txt directory
  translated_filepath = "#{ITM_TXT_DIR}/#{translation_keycode}/#{txt_filename}"
  puts "Loading #{ko_filepath}..."
  txt_file_contents = File.open(translated_filepath,"r:ISO-8859-1", &:read)

  items_strings = txt_file_contents.split(/^#/)[1..-1].map do |item_info|
    item_num, item_name, item_desc, item_stats = item_info.strip.split("\n")
    #puts "Item name: [#{item_name}]"
    #puts "Item num: [#{item_num}]"
    #puts "Item desc: [#{item_desc}]"
    #puts "Item stats: [#{item_stats}]"

    # Bytes 1: Item Number (starting with 26, though 27 and 28 appear to be numbered incorrectly (x00 and x18, respectively)
    # Bytes 2-26: Name (in original Korean, no names take up more than 5 bytes)(TODO: Test that the name can actually take up all 20+ bytes, and that it's not just that the stats start late)
    # Bytes 27-41: Stat modifiers (unconfirmed)
    # Bytes 42-66: Stat descriptions
    item_string = "".force_encoding("ISO-8859-1")
    item_string += [item_num.to_i].pack('V*').force_encoding("ISO-8859-1")
    item_string += item_name.unpack('a*').pack("a#{25*4}").force_encoding("ISO-8859-1")
    item_string += item_stats.gsub('[','').gsub(']','').split(',').map(&:to_i).pack('V*').force_encoding("ISO-8859-1")
    item_string += item_desc.unpack('a*').pack("a#{25*4}").force_encoding("ISO-8859-1")

  raise "ERROR: Resulting item ##{item_num} string is not properly sized: #{item_string.length} instead of 264 32-bit bytes." if item_string.length != 264

    item_string
  end

  raise "ERROR: Incorrect number of item translations, found #{items_strings.length} instead of 88." if items_strings.length != 88


  header = [88,17].pack("V*").force_encoding("ISO-8859-1")
  body = "".force_encoding("ISO-8859-1")
  body += items_strings.join("")

  output_file_path = "#{ITM_DIR}/#{translation_keycode}/#{itm_filename}" # e.g. ./itm/en/0000.itm

  puts "Writing #{output_file_path}..."
  File.open(output_file_path,"w:ISO-8859-1") do |f|
    f.write(header)
    f.write(body)
  end
end


puts "Finished txt2itm.rb\n"

