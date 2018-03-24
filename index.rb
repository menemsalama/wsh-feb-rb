require 'json'
require 'nokogiri'
require 'pp'

inputs = Dir.entries("inputs").select {|f| !File.directory? f}

def get_tag_num(elm)
  elm[0][/\d/].to_i
end

def is_h_tag(e)
  num = get_tag_num(e)
  num.is_a?(Integer) and num != 0
end

def parse(file_path)
  results = {
    :sections => [],
    :paragraphs => []
  }

  tags = []
  page = Nokogiri::HTML(open(file_path))
  page.css('h2, h3, h4, h5, h6, p').each do |link|
    tags.push [link.name, link.text]
  end

  base_h_tag = nil

  tags.each do |e|
    if base_h_tag == nil and is_h_tag(e)
      base_h_tag = e
    elsif !is_h_tag(e) and results[:sections].length == 0
      results[:paragraphs].push(e[1])
      next
    end

    idx = results[:sections].length-1
    if e[0] == base_h_tag[0]
      results[:sections].push({ :section => e[1], :paragraphs => [] })
    elsif !is_h_tag(e) and results[:sections][idx][:subsections].is_a?(Array)
      sub_idx = results[:sections][idx][:subsections].length-1
      results[:sections][idx][:subsections][sub_idx][:paragraphs].push e[1]
    elsif is_h_tag(e)
      results[:sections][idx][:subsections] = [] if results[:sections][idx][:subsections] == nil
      results[:sections][idx][:subsections].push({ :subsection => e[1], :paragraphs => [] })
    else
      results[:sections][idx][:paragraphs].push e[1]
    end
  end

  results
end

inputs.each do |path|
  results = parse "inputs/#{path}"
  File.open("outputs/#{path}.json","w") do |f|
    f.write(JSON.pretty_generate(results))
  end
end

puts "Parsed inputs: "
pp inputs
