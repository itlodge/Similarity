require 'rmmseg'
require 'pathname'

class Document
  attr_reader :content, :id

  def initialize(hash_args)
    content = hash_args[:content]
    if content && !content.empty?
      @content = content
      @term_frequency = nil
      @terms = nil
    else
      raise ArgumentError, "text cannot be nil or blank"
    end

    @chinese = hash_args[:chinese]
    if @chinese
      current_path = Pathname.new(File.dirname(__FILE__)).realpath
      @stop_set = Set.new
      File.foreach("#{current_path}/stopwords.txt") do |line|
        @stop_set.add(line.strip)
      end
    end

    id = hash_args[:id]
    if id && !id.nil?
      @id = id
    else
      @id = self.object_id
    end
  end

  def terms
    if @chinese
      return chinese_terms
    else
      @terms ||=
        @content.gsub(/(\d|\s|\W)+/, ' ').
        split(/\s/).map { |term| term.downcase }
    end
  end

  def chinese_terms
    algorithm = RMMSeg::Algorithm.new(content)
    @terms = []
    loop do
      token = algorithm.next_token
      break if token.nil?

      token.text.force_encoding('utf-8')
      if not @stop_set.include?(token.text)
        @terms.push(token.text)
      end
    end
    return @terms
  end

  def term_frequencies
    @term_frequencies ||= calculate_term_frequencies
  end

  def calculate_term_frequencies
    tf = Hash.new(0)

    terms.each { |term| tf[term] += 1 }

    total_number_of_terms = terms.size.to_f
    tf.each_pair { |k,v| tf[k] = (tf[k] / total_number_of_terms) }
  end

  def term_frequency(term)
    term_frequencies[term]
  end

  def has_term?(term)
    terms.include? term
  end
end
