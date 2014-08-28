#!/usr/bin/env ruby
require 'diff-lcs'

module TextAlignment; end unless defined? TextAlignment

class << TextAlignment

  def find_min_lcs(str1, str2, clcs = 0)
    sdiff = Diff::LCS.sdiff(str1, str2)
    lcs = sdiff.count{|d| d.action == '='}
    return nil if lcs < clcs

    match_first    = sdiff.index{|d| d.action == '='}
    match_last     = sdiff.rindex{|d| d.action == '='}
    m_str1_initial = sdiff[match_first].old_position
    m_str2_initial = sdiff[match_first].new_position
    m_str1_final   = sdiff[match_last].old_position
    m_str2_final   = sdiff[match_last].new_position

    rlcs, b1, e1, b2, e2 = _find_min_lcs(str1[m_str1_initial .. m_str1_final], str2[m_str2_initial + 1 .. m_str2_final], lcs)
    return rlcs, b1 + m_str1_initial, e1 + m_str1_initial, b2 + m_str2_initial + 1, e2 + m_str2_initial + 1 unless rlcs.nil?

    rlcs, b1, e1, b2, e2 = _find_min_lcs(str1[m_str1_initial .. m_str1_final], str2[m_str2_initial .. m_str2_final - 1], lcs)
    return rlcs, b1 + m_str1_initial, e1 + m_str1_initial, b2 + m_str2_initial, e2 + m_str2_initial unless rlcs.nil?

    return lcs, m_str1_initial, m_str1_final, m_str2_initial, m_str2_final
  end
end


if __FILE__ == $0
  if ARGV.length == 2
    # str1 = File.read(ARGV[0]).strip
    # str2 = File.read(ARGV[1]).strip
    str2 = 'naxbyzabcdexydzem'
    str1 = 'abcde'
    sc = TextAlignment::LCSComparison.new(str1, str2)
    puts sc.cdiff_str1
    puts sc.cdiff_str2
    puts "-----"
    puts "Similarity: #{sc.similarity}"
    puts "Match str1: (#{sc.match_str1_begin}, #{sc.match_str1_end})"
    puts "Match str2: (#{sc.match_str2_begin}, #{sc.match_str2_end})"
  end
end
