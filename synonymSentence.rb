require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'cgi'

module SynonymSentence
  API_KEY = 'caede0c4435110228e1d1f0d09239f72'
  API_VERSION = 2
  WORDS_PER_LINE = 4
  RELATIONSHIP_TYPES = {
    'syn' => 'synonyms',
    'ant' => 'antonyms',
    'rel' => 'related',
    'sim' => 'similar',
    'usr' => 'user suggested'
    }
  def self.variants(search_term_array)

    synom = Array.new
    temp=Array.new
    synom_sentence = Array.new
    #search_term_array = gets.chomp.split
    search_term_array = search_term_array.split

    size_array = search_term_array.size
    #now = Time.now
    search_term_array.each do |search_term|
      search_term_url = CGI::escape(search_term)

      uri = URI.parse("http://words.bighugelabs.com/api/#{API_VERSION}/#{API_KEY}/#{search_term_url}/json")
      response = Net::HTTP.get(uri)

      if !response.empty?
        temp = []
        parts = JSON.parse(response) if response
        parts.each do |part, relationships|
          RELATIONSHIP_TYPES.sort.reverse.each do |abbrev, title|
            if relationships[abbrev]
              words = relationships[abbrev].sort
              words.each do |word|
                temp << word
              end
            end
          end
        end
        temp << search_term
        synom << temp
      else
        synom << [search_term]
      end
    end

    for n in 0...size_array
      actword=""
      if synom[n].size==1
        next
      elsif synom[n].size<5
        actword= synom[n][-1]
        synom[n].sort!{|x| x.length}
        synom[n] << actword
      else
        actword = synom[n][-1]
        synom[n] = synom[n][0,synom[n].size-1]
        synom[n].sort_by &:length
        synom[n] = synom[n][0,4]
        synom[n] << actword
      end
    end
    synom_sentence = [synom[0]] if synom.size==1
    synom_sentence = synom[0] if synom.size>0


    for n in 1...size_array
      synom_sentence = synom_sentence.product(synom[n])
    end
    sentence =[]

    if size_array ==1
      sentence = synom_sentence
    end

    if size_array>1
      for n in 0...synom_sentence.size
        sentence << synom_sentence[n].join(" ")
      end
    end
    #ending = Time.now
    #puts "#{(ending-now)*1000} milliseconds"
    #puts "[#{sentence.join(", ")}]"
    return sentence
  end


end
#puts SynonymSentence.variants("guy jazz")
