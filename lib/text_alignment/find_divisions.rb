#!/usr/bin/env ruby
require 'text_alignment/approximate_fit'
require 'text_alignment/lcs_comparison'

module TextAlignment; end unless defined? TextAlignment

# to work on the hash representation of denotations
# to assume that there is no bag representation to this method

TextAlignment::SIMILARITY_THRESHOLD = 0.7 unless defined? TextAlignment::SIMILARITY_THRESHOLD

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
    sources.each{|source| source[:text].tr!(characters_from, characters_to)}

    # to process smaller ones first
    sources.sort!{|s1, s2| s1[:text].size <=> s2[:text].size}

    TextAlignment._find_divisions(target, sources)
  end

  def _find_divisions(_target, _sources)
    indice = []
    history = []
    cache = {}
    target = _target.dup
    sources = _sources.dup
    until target.strip.empty? || sources.empty?
      mode, cmp = nil, nil
      candidates = []
      sources.each_with_index do |source, i|
        if target.size < source[:text].size
          mode = :t_in_s
          str1 = target
          str2 = source[:text]
        else
          mode = :s_in_t
          str1 = source[:text]
          str2 = target
        end

        len1 = str1.length
        len2 = str2.length

        offset_begin, offset_end = if (len2 - len1) > len1 * (1 - TextAlignment::SIMILARITY_THRESHOLD)
          approximate_fit(str1, str2)
        else
          # the whole target
          [0, -1]
        end

        unless offset_begin.nil?
          key = str1 + ' _:_ ' + str2[offset_begin .. offset_end]
          cmp = if cache.has_key? key
            cache[key]
          else
            cmp = TextAlignment::LCSComparison.new(str1, str2[offset_begin .. offset_end])
          end
          cache[key] = cmp

          if (cmp.similarity > TextAlignment::SIMILARITY_THRESHOLD) && ((len1 - (cmp.str1_match_final - cmp.str1_match_initial + 1)) < len1 * (1 - TextAlignment::SIMILARITY_THRESHOLD))
            candidates << {idx:i, offset:offset_begin, mode:mode, cmp:cmp}
          end
        end
      end

      # return remaining target and sources if m.nil?
      break if candidates.empty?

      choice = candidates.max{|a, b| a[:cmp].similarity <=> a[:cmp].similarity}
      m = choice[:idx]
      mode = choice[:mode]

      index = if mode == :t_in_s
        {divid:sources[m][:divid], region:[0, target.size]}
      else # :s_in_t
        cmp = choice[:cmp]
        offset = choice[:offset]
        {divid:sources[m][:divid], region:[cmp.str2_match_initial + offset, cmp.str2_match_final + offset + 1]}
      end

      target = target[0 ... index[:region][0]] + target[index[:region][1] .. -1]
      history << index[:region].dup

      before_begin = index[:region][0]
      before_end = index[:region][1]

      rhistory = history.reverse
      rhistory.shift
      rhistory.each do |h|
        gap = h[1] - h[0]
        index[:region][0] += gap if index[:region][0] >= h[0]
        index[:region][1] += gap if index[:region][1] >  h[0]
      end

      indice << index

      sources.delete_at(m)
    end

    unless target.strip.empty? && sources.empty?
      index = {divid:nil}
      index[:remaining_target] = target unless target.strip.empty?
      index[:remaining_sources] = sources.collect{|s| s[:divid]} unless sources.empty?
      indice << index
    end

    indice
  end

  def _find_divisions_old(target, sources)
    mode, m, c, offset_begin = nil, nil, nil, nil

    sources.each_with_index do |source, i|
      if target.size < source[:text].size
        mode = :t_in_s
        str1 = target
        str2 = source[:text]
      else
        mode = :s_in_t
        str1 = source[:text]
        str2 = target
      end

      len1 = str1.length
      len2 = str2.length

      offset_begin, offset_end = 0, -1
      offset_begin, offset_end = approximate_fit(str1, str2) if (len2 - len1) > len1 * (1 - TextAlignment::SIMILARITY_THRESHOLD)

      unless offset_begin.nil?
        c = TextAlignment::LCSComparison.new(str1, str2[offset_begin .. offset_end])
        if (c.similarity > TextAlignment::SIMILARITY_THRESHOLD) && ((len1 - (c.str1_match_final - c.str1_match_initial + 1)) < len1 * (1 - TextAlignment::SIMILARITY_THRESHOLD))
          m = i
          break
        end
      end
    end

    # return remaining target and sources if m.nil?
    return [[-1, [target, sources.collect{|s| s[:divid]}]]] if m.nil?

    index = if mode == :t_in_s
      [sources[m][:divid], [0, target.size]]
    else # :s_in_t
      [sources[m][:divid], [c.str2_match_initial + offset_begin, c.str2_match_final + offset_begin + 1]]
    end

    next_target = target[0 ... index[1][0]] + target[index[1][1] .. -1]
    sources.delete_at(m)

    if next_target.strip.empty? || sources.empty?
      return [index]
    else
      more_index = _find_divisions(next_target, sources)
      gap = index[1][1] - index[1][0]
      more_index.each do |i|
        if (i[0] > -1)
          i[1][0] += gap if i[1][0] >= index[1][0]
          i[1][1] += gap if i[1][1] >  index[1][0]
        end
      end
      return [index] + more_index
    end
  end

end

if __FILE__ == $0
  require 'json'
  if ARGV.length == 2
    target  = JSON.parse File.read(ARGV[0]), :symbolize_names => true
    target_text = target[:text].strip

    sources = JSON.parse File.read(ARGV[1]), :symbolize_names => true
    div_index = TextAlignment::find_divisions(target_text, sources)
    pp div_index

    # str1 = File.read(ARGV[0]).strip
    # str2 = File.read(ARGV[1]).strip
    # div_index = TextAlignment::find_divisions(str1, [str2])

    # puts "target length: #{target_text.length}"
    # div_index.each do |i|
    #   unless i[:divid].nil?
    #     puts "[Div: #{i[:divid]}] (#{i[:region][0]}, #{i[:region][1]})"
    #     puts target_text[i[:region][0] ... i[:region][1]]
    #     puts "=========="
    #   else
    #     p i
    #   end

    #   # if i[0] >= 0
    #   #   puts "[Div: #{i[0]}] (#{i[1][0]}, #{i[1][1]})"
    #   #   puts target_text[i[1][0] ... i[1][1]]
    #   #   puts "=========="
    #   # else
    #   #   p i
    #   # end
    # end
  end
end
