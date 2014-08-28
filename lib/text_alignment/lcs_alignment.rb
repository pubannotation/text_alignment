#!/usr/bin/env ruby
require 'diff-lcs'

class SequenceAlignment::LCSComparision
  # The similarity ratio of the given two strings after stripping unmatched prefixes and suffixes
  attr_reader :similarity
  attr_reader :match_str1_begin, :match_str1_end, :match_str2_begin, :match_str2_end

  # It initializes the GLCS table for the given two strings, str1 and str2.
  # When the array, mappings, is given, general suffix comparision is performed based on the mappings.
  # Exception is raised when nil given passed to either str1, str2 or dictionary
  def initialize(str1, str2)
    raise ArgumentError, "nil string" if str1 == nil || str2 == nil
    @str1, @str2 = str1, str2
    @sdiff = Diff::LCS.sdiff(str1, str2)
    _lcs_comparison
  end
  

  def position_map
    posmap_begin, posmap_end = {}, {}
    addition, deletion = [], []

    @sdiff.each do |d|
      case h.action
      when '='
        p1 = d.old_position, p2 = d.new_position

        posmap[p1] = p2

        if !addition.empty? && deletion.empty?
          # correct the position for end
          posmap_end[p1] = p2 - addition.length
        elsif addition.empty? && !deletion.empty?
          deletion.each{|p| posmap_begin[p], posmap_end[p] = p2, p2}
        elsif !addition.empty? && !deletion.empty?
          @mapped_elements << [@str1[deletion[0], dl], @str2[addition[0], al]]

          posmap_begin[deletion[0]], posmap_end[deletion[0]] = addition[0], addition[0]
          deletion[1..-1].each{|p| posmap_begin[p], posmap_end[p] = nil, nil}
        end

        addition.clear; deletion.clear

      when '!'
        deletion << h.old_position
        addition << h.new_position
      when '-'
        deletion << h.old_position
      when '+'
        addition << h.new_position
      end
    end

    if !addition.empty? && deletion.empty?

      if p1 == @len1
        # retract from the end
        posmap_begin[p1] = p2 - addition.length
        posmap_end[p1] = posmap_begin[p1]
      else



    last = from_text.length
    # p posmap
    # p last
    posmap[last] = posmap[last - 1] + 1

  end

  private

  def _lcs_comparison
    match_first = @sdiff.index{|d| d.action == '='}
    match_last  = @sdiff.rindex{|d| d.action == '='}
    @match_str1_begin = @sdiff[match_first].old_position
    @match_str2_begin = @sdiff[match_first].new_position
    @match_str1_end   = @sdiff[match_last].old_position
    @match_str2_end   = @sdiff[match_last].new_position
    match_num   = @sdiff.count{|d| d.action == '='}
    @similarity  = 2 * match_num / ((@match_str1_end - @match_str1_begin) + (@match_str2_end - @match_str2_begin)).to_f
  end



  def self.find_divisions(source, targets, mappings = [])
    raise ArgumentError, "nil source"           if source == nil
    raise ArgumentError, "nil or empty targets" if targets == nil || targets.empty?
    raise ArgumentError, "nil mappings"         if mappings == nil

    character_mappings = mappings.select{|m| m[0].length == 1 && m[1].length == 1}
    mappings.delete_if{|m| m[0].length == 1 && m[1].length == 1}
    characters_from = character_mappings.collect{|m| m[0]}.join
    characters_to   = character_mappings.collect{|m| m[1]}.join
    characters_to.gsub!(/-/, '\-')

    source.tr!(characters_from, characters_to)
    targets.each{|target| target.tr!(characters_from, characters_to)}

    self._find_divisions(source, targets)
  end

  def self._find_divisions(source, targets)
    m, sa = nil, nil
    (0..targets.size).each do |i|
      sa = self._sequence_comparisionequenceSequenceAlignment.new(source, targets[i])
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

  # def temp
  #   posmap = Hash.new

  #   # adhoc: need to be improved
  #   from_text = string1.tr(" −–", " -")
  #   to_text   = string2.tr(" −–", " -")

  #   sdiff = Diff::LCS.sdiff(from_text, to_text)

  #   puts
  #   sdiff.each_with_index do |h, i|
  #     # p h
  #     break if i > 1100
  #   end

  #   addition = []
  #   deletion = []

  #   sdiff.each do |h|
  #     case h.action
  #     when '='

  #       case deletion.length
  #       when 0
  #       when 1
  #         posmap[deletion[0]] = addition[0]
  #       else
  #         gdiff = GLCS.new(from_text[deletion[0]..deletion[-1]], to_text[addition[0]..addition[-1]], dictionary).sdiff

  #         # gdiff.each do |gg|
  #         #   p gg
  #         # end
  #         # puts "-------------"

  #         new_position = 0
  #         state = '='
  #         gdiff.each_with_index do |g, i|
  #           if g[:action] ==  '+'
  #             new_position = g[:new_position] unless state == '+'
  #             state = '+'
  #           end

  #           if g[:action] == '-'
  #             posmap[g[:old_position] + deletion[0]] = new_position + addition[0]
  #             state = '-'
  #           end
  #         end
  #       end

  #       addition.clear
  #       deletion.clear

  #       posmap[h.old_position] = h.new_position
  #     when '!'
  #       deletion << h.old_position
  #       addition << h.new_position
  #     when '-'
  #       deletion << h.old_position
  #     when '+'
  #       addition << h.new_position
  #     end
  #   end

  #   last = from_text.length
  #   # p posmap
  #   # p last
  #   posmap[last] = posmap[last - 1] + 1

  #   # p posmap
  #   # puts '-=-=-=-=-=-=-'

  #   @posmap = posmap
  # end

  # def mapping
  #   @posmap
  # end

  # def show_mapping
  #   (0...@posmap.size).each {|i| puts "#{i}\t#{@posmap[i]}"}
  # end

  # def transform_denotations(denotations)
  #   return nil if denotations == nil

  #   denotations_new = Array.new(denotations)

  #   (0...denotations.length).each do |i|
  #     denotations_new[i][:span][:begin] = @posmap[denotations[i][:span][:begin]]
  #     denotations_new[i][:span][:end]   = @posmap[denotations[i][:span][:end]]
  #   end

  #   denotations_new
  # end

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

  # aligner = SequenceAlignment.new(anns1[:text], anns2[:text], [["Δ", "delta"], [" ", " "], ["–", "-"], ["′", "'"]])
  # denotations = aligner.transform_denotations(anns1[:denotations])

  denotations_s = <<-'ANN'
  [{"id":"T0", "span":{"begin":1,"end":2}, "category":"Protein"}]
  ANN

  # denotations = JSON.parse denotations_s, :symbolize_names => true

  SequenceAlignment.find_divisions(from_text, [to_text], [["Δ", "delta"], [" ", " "], ["–", "-"], ["′", "'"], ["’", "'"]])
  # aligner = SequenceAlignment.new(from_text, to_text, [["Δ", "delta"], [" ", " "], ["–", "-"], ["′", "'"], ["β", "beta"]])

  # p denotations
end
