require 'json'
require 'nokogiri'
require 'pp'

inputs = Dir.entries("inputs").select {|f| !File.directory? f}

def is_h_tag(link)
  link.name != "p"
end

def parse(file_path)
  results = {
    :sections => [],
    :paragraphs => []
  }

  base_h_tag = nil
  page = Nokogiri::HTML(open(file_path))
  page.css('h2, h3, h4, h5, h6, p').each do |link|
    # to add base or push to paragraphs
    if base_h_tag == nil and is_h_tag(link)
      base_h_tag = link
    elsif !is_h_tag(link) and results[:sections].length == 0
      results[:paragraphs].push(link.text)
      next
    end

    idx = results[:sections].length-1
    if link.name == base_h_tag.name
      # remove prev section with empty paragraphs
      if results[:sections].length > 0 and results[:sections][idx][:paragraphs].length == 0
        results[:sections].delete results[:sections][idx]
      end
      results[:sections].push({ :section => link.text, :paragraphs => [] })
    elsif !is_h_tag link and results[:sections][idx][:subsections].is_a?(Array)
      sub_idx = results[:sections][idx][:subsections].length-1
      results[:sections][idx][:subsections][sub_idx][:paragraphs].push link.text
    elsif is_h_tag(link)
      results[:sections][idx][:subsections] = [] if results[:sections][idx][:subsections] == nil
      results[:sections][idx][:subsections].push({ :subsection => link.text, :paragraphs => [] })
    else
      results[:sections][idx][:paragraphs].push link.text
    end
  end

  # remove last section if empty
  idx = results[:sections].length-1
  if results[:sections][idx][:paragraphs].length == 0
    results[:sections].delete results[:sections][idx]
  end

  # remove sections if It's empty
  if results[:sections].length == 0
    results.delete(:sections)
  else # remove paragraphs
    results.delete(:paragraphs)
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
