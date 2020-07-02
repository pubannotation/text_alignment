#!/usr/bin/env ruby
require 'string-similarity'

module TextAlignment; end unless defined? TextAlignment

# approximate the location of str1 in str2
module TextAlignment
  SIGNATURE_NGRAM = 5
  MIN_LENGTH_FOR_APPROXIMATION = 50
  BUFFER_RATE = 0.1
  TEXT_SIMILARITY_TRESHOLD = 0.8
end

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

      text_similarity = text_similarity(str1, str2[fit_begin ... fit_end])
      break if text_similarity > TextAlignment::TEXT_SIMILARITY_TRESHOLD
      fit_begin, fit_end = nil, nil
    end

    return nil, nil if fit_begin >= fit_end
    return fit_begin, fit_end
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
