#!/usr/bin/env ruby
#
# abi2txt.rb
#
# This script converts the skills files(.abi) into (.txt) files for translation or value editing.
# Put txt files into ./abi_txt/ko/
# Separate items in the translation files by using "<>".  Whitespace between the items will get trimmed.
#
# Usage:
#   ./abi2txt.rb


puts "Starting abi2txt.rb..."

ABI_DIR = "./abi"
ABI_TXT_DIR = "./abi_txt"

abi_ko_files = Dir["#{ABI_DIR}/ko/0*.abi"] # e.g. ['abi/ko/0000.abi']

abi_ko_files.each do |ko_filepath|
  puts "Loading #{ko_filepath}..."
  ko_filename = File.basename(ko_filepath)
  txt_filename = ko_filename.sub('.abi','.txt')
  ko_file_contents = File.open(ko_filepath,"r:ISO-8859-1", &:read)

#  puts "  Parsing ko abi file..."
  first_1_bytes = ko_file_contents[0..3]
  item_count = first_1_bytes.unpack('V').first # Total count seems to exclude the first 3 items which have weird item numbers
  second_1_bytes = ko_file_contents[4..7]
  item_payload_size = second_1_bytes.unpack('V').first # This byte may be the size of the item payloads, but the math is not clear; we have no reason to change it though
  ko_item_contents = ko_file_contents[8..-1].unpack('V*')

  items_strings = ko_item_contents.each_slice(86).map do |item_bytes|
    # Bytes 1: Item Number (starting with #0)
    # Bytes 2-16: Name (in original Korean, no names take up more than 9 bytes)(TODO: Test that the name can actually take up all 20+ bytes, and that it's not just that the stats start late)
    # Bytes 17-86: Stat modifiers (unconfirmed)

    item_num = item_bytes[0]
    name = item_bytes[1..15].inject([]){|name_bytes,byte| break name_bytes if byte == 0; name_bytes << byte}.pack('V*').strip
    stats_bytes = item_bytes[16..-1]

    # For debug
    #first_zero_index = item_bytes[1..41].find_index{|byte|byte == 0}
    #first_stat_byte = item_bytes[(first_zero_index+1)..41].find_index{|byte|byte != 0} + first_zero_index + 1
    #"#(#{item_bytes[0]})\n ALL:[#{item_bytes}]\n First zero byte: [#{first_zero_index}]\n First stat byte: [#{first_stat_byte}]\n Name: [#{name.strip}]\n Desc:[#{desc.strip}]".force_encoding("ISO-8859-1")

    "##{item_num}\n#{name}\n#{stats_bytes}\n".force_encoding("ISO-8859-1")
  end

  body = "".force_encoding("ISO-8859-1")
  body += items_strings.join("\n\n")

  output_file_path = "#{ABI_TXT_DIR}/ko/#{txt_filename}" # e.g. ./abi/ko/0000.abi

  puts "Writing #{output_file_path}..."
  File.open(output_file_path,"w:ISO-8859-1") do |f|
    f.write(body)
  end
end


puts "Finished abi2txt.rb\n"

