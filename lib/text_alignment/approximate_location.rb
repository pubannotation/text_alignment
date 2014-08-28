#!/usr/bin/env ruby
module TextAlignment; end unless defined? TextAlignment

# approximate the location of str1 in str2
module TextAlignment
  SIGNATURE_NGRAM = 5
  MIN_LENGTH_FOR_APPROXIMATION = 100
end

class << TextAlignment
  def approximate_location(str1, str2)
    raise ArgumentError, 'nil string' if str1.nil? || str2.nil?
    return 0 if str2.length < TextAlignment::MIN_LENGTH_FOR_APPROXIMATION

    ngram1 = (0 .. str1.length - TextAlignment::SIGNATURE_NGRAM).collect{|i| str1[i, TextAlignment::SIGNATURE_NGRAM]}
    ngram2 = (0 .. str2.length - TextAlignment::SIGNATURE_NGRAM).collect{|i| str2[i, TextAlignment::SIGNATURE_NGRAM]}
    ngram_shared = ngram1 & ngram2
    raise "no shared ngrams" if ngram_shared.empty?

    signature_ngram = ngram_shared.detect{|g| ngram2.count(g) == 1}
    raise "no signature ngram" if signature_ngram.nil?
    offset = str1.index(signature_ngram)
    str2.index(signature_ngram) - offset
  end
end

if __FILE__ == $0
  if ARGV.length == 2
    str1 = File.read(ARGV[0]).strip
    str2 = File.read(ARGV[1]).strip

    loc = TextAlignment::approximate_location(str1, str2)
    p loc
  end
end
