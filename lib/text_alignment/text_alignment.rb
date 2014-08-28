#!/usr/bin/env ruby
require 'diff-lcs'
require 'text_alignment/glcs_alignment'

module TextAlignment; end unless defined? TextAlignment

class << TextAlignment

  # It finds, among the sources, the right divisions for the taraget text to fit in.
  def find_divisions(target, sources, mappings = [])
    raise ArgumentError, "nil target"           if target == nil
    raise ArgumentError, "nil or empty sources" if sources == nil || sources.empty?
    raise ArgumentError, "nil mappings"         if mappings == nil

    character_mappings = mappings.select{|m| m[0].length == 1 && m[1].length == 1}
    mappings.delete_if{|m| m[0].length == 1 && m[1].length == 1}
    characters_from = character_mappings.collect{|m| m[0]}.join
    characters_to   = character_mappings.collect{|m| m[1]}.join
    characters_to.gsub!(/-/, '\-')

    target.tr!(characters_from, characters_to)
    sources.each{|source| source.tr!(characters_from, characters_to)}

    self._find_divisions(target, sources)
  end

  def find_divisions(target, sources)
    m, sa = nil, nil
    (0..sources.size).each do |i|
      mode, str1, str2 = (target.size < sources[i]) ? :t_in_s, target.size, sources[i] : :s_in_t, sources[i], target
      if (str2 - str1) / str1.to_f > 

      sa = self._sequence_comparisoneSequenceAlignment.new(source, targets[i])
      if sa.front_overflow < PTHRESHOLD && sa.similarity(true) > STHRESHOLD
        m = i
        break
      end
    end

    raise "cannot find" if m.nil?

    index = [i, [sa.front_overflow, targets.size - sa.rear_overflow]]
    logger.debug "matched to div-#{i}' <-----"

    targets.delete_at(i)
    if targets.empty?
      return index
    else
      return index + distribute_annotations(source[-sa.rear_overflow..-1], targets)
    end
  end

end

if __FILE__ == $0

  # from_text = "TGF-β mRNA"
  # to_text = "TGF-beta mRNA"

  # from_text = "TGF-beta mRNA"
  # to_text = "TGF-β mRNA"

  # from_text = "TGF-beta mRNA"
  # to_text = "TGF- mRNA"

  from_text = "TGF-β–induced"
  to_text = "TGF-beta-induced"

  # from_text = "TGF-beta-induced"
  # to_text = "TGF-β–induced"

  # from_text = "beta-induced"
  # to_text = "TGF-beta-induced"

  # from_text = "TGF-beta-induced"
  # to_text = "beta-induced"

  # from_text = "TGF-β–β induced"
  # to_text = "TGF-beta-beta induced"

  # from_text = "-βκ-"
  # to_text = "-betakappa-"

  # from_text = "-betakappa-beta-z"
  # to_text = "-βκ-β–z"

  # from_text = "affect C/EBP-β’s ability"
  # to_text = "affect C/EBP-beta's ability"

  # from_text = "12 ± 34"
  # to_text = "12 +/- 34"

  # from_text = "TGF-β–treated"
  # to_text = "TGF-beta-treated"

  # from_text = "in TGF-β–treated cells"
  # to_text   = "in TGF-beta-treated cells"

  # from_text = "TGF-β–induced"
  # to_text = "TGF-beta-induced"

  # anns1 = JSON.parse File.read(ARGV[0]), :symbolize_names => true
  # anns2 = JSON.parse File.read(ARGV[1]), :symbolize_names => true

  # aligner = TextAlignment.new(anns1[:text], anns2[:text], [["Δ", "delta"], [" ", " "], ["–", "-"], ["′", "'"]])
  # denotations = aligner.transform_denotations(anns1[:denotations])

  denotations_s = <<-'ANN'
  [{"id":"T0", "span":{"begin":1,"end":2}, "category":"Protein"}]
  ANN

  # denotations = JSON.parse denotations_s, :symbolize_names => true

  TextAlignment.find_divisions(from_text, [to_text], [["Δ", "delta"], [" ", " "], ["–", "-"], ["′", "'"], ["’", "'"]])
  # aligner = TextAlignment.new(from_text, to_text, [["Δ", "delta"], [" ", " "], ["–", "-"], ["′", "'"], ["β", "beta"]])

  # p denotations
end
