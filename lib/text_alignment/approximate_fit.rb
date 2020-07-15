#!/usr/bin/env ruby
require 'string-similarity'

module TextAlignment; end unless defined? TextAlignment

# approximate the location of str1 in str2
TextAlignment::SIGNATURE_NGRAM = 7 unless defined? TextAlignment::SIGNATURE_NGRAM
TextAlignment::MIN_LENGTH_FOR_APPROXIMATION = 50 unless defined? TextAlignment::MIN_LENGTH_FOR_APPROXIMATION
TextAlignment::BUFFER_RATE = 0.1 unless defined? TextAlignment::BUFFER_RATE
TextAlignment::TEXT_SIMILARITY_TRESHOLD = 0.7 unless defined? TextAlignment::TEXT_SIMILARITY_TRESHOLD

class << TextAlignment

  # If finds an approximate region of str2 that contains str1
  def approximate_fit(str1, str2)
    raise ArgumentError, 'nil string' if str1.nil? || str2.nil?
    return 0, str2.length if str2.length < TextAlignment::MIN_LENGTH_FOR_APPROXIMATION

    ngram1 = (0 .. str1.length - TextAlignment::SIGNATURE_NGRAM).collect{|i| str1[i, TextAlignment::SIGNATURE_NGRAM]}
    ngram2 = (0 .. str2.length - TextAlignment::SIGNATURE_NGRAM).collect{|i| str2[i, TextAlignment::SIGNATURE_NGRAM]}
    ngram_shared = ngram1 & ngram2

    # If there is no shared n-gram found, it may mean there is no serious overlap between the two strings
    return nil, nil if ngram_shared.empty?

    signature_ngrams = ngram_shared.select{|g| ngram2.count(g) == 1}
    return nil, nil if signature_ngrams.empty? #raise "no signature ngram"

    cache = {}
    fit_begin, fit_end = nil, nil
    signature_ngrams.each do |signature_ngram|
      loc_signature_ngram_in_str1 = str1.index(signature_ngram)
      loc_signature_ngram_in_str2 = str2.index(signature_ngram)

      # approximate the beginning of the fit
      fit_begin = loc_signature_ngram_in_str2 - loc_signature_ngram_in_str1 - (loc_signature_ngram_in_str1 * TextAlignment::BUFFER_RATE).to_i
      fit_begin = 0 if fit_begin < 0

      # approximate the end of the fit
      offset_end = str1.length - loc_signature_ngram_in_str1
      fit_end = loc_signature_ngram_in_str2 + offset_end + (offset_end * TextAlignment::BUFFER_RATE).to_i
      fit_end = str2.length if fit_end > str2.length

      next if cache.has_key?("#{fit_begin}-#{fit_end}")
      text_similarity = text_similarity(str1, str2[fit_begin ... fit_end])
      cache["#{fit_begin}-#{fit_end}"] = text_similarity

      break if text_similarity > TextAlignment::TEXT_SIMILARITY_TRESHOLD
      fit_begin, fit_end = nil, nil
    end
    return fit_begin, fit_end if fit_begin && fit_end && fit_begin < fit_end
    return nil, nil
  end

  private

  def text_similarity(str1, str2, ngram_order = 3)
    _str1 = str1.delete(" \t\r\n")
    _str2 = str2.delete(" \t\r\n")
    String::Similarity.cosine(_str1, _str2, ngram:2)
  end

end

if __FILE__ == $0
  require 'json'

  if ARGV.length == 2
    str1 = JSON.parse(File.read(ARGV[0]).strip)["text"]
    str2 = JSON.parse(File.read(ARGV[1]).strip)["text"]

    loc = TextAlignment::approximate_fit(str1, str2)
    p loc
    puts str2[loc[0]...loc[1]]
  end
end
