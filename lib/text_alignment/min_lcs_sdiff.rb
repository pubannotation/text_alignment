#!/usr/bin/env ruby
require 'diff-lcs'

class Diff::LCS::ContextChange
  attr_accessor :old_position, :new_position
end

module TextAlignment; end unless defined? TextAlignment

class << TextAlignment

  # It finds minimal lcs and sdiff of the given strings, str1 and str2
  # It relies on the diff-lcs gem for the computation of lcs table
  # It assumes str1 is smaller than str2
  def min_lcs_sdiff(str1, str2, clcs = 0)
    raise ArgumentError, "nil string" if str1 == nil || str2 == nil

    sdiff = Diff::LCS.sdiff(str1, str2)
    lcs = sdiff.count{|d| d.action == '='}
    return nil if lcs < clcs

    match_first = sdiff.index{|d| d.action == '='}
    m1_initial  = sdiff[match_first].old_position
    m2_initial  = sdiff[match_first].new_position

    match_last  = sdiff.rindex{|d| d.action == '='}
    m1_final    = sdiff[match_last].old_position
    m2_final    = sdiff[match_last].new_position

    rlcs, rsdiff = min_lcs_sdiff(str1[m1_initial + 1 .. m1_final], str2[m2_initial .. m2_final], lcs)
    unless rlcs.nil?
      rsdiff.each {|h| h.old_position += m1_initial + 1; h.new_position += m2_initial}
      return rlcs, rsdiff
    end

    rlcs, rsdiff = min_lcs_sdiff(str1[m1_initial .. m1_final - 1], str2[m2_initial .. m2_final], lcs)
    unless rlcs.nil?
      rsdiff.each {|h| h.old_position += m1_initial; h.new_position += m2_initial}
      return rlcs, rsdiff
    end

    rlcs, rsdiff = min_lcs_sdiff(str1[m1_initial .. m1_final], str2[m2_initial + 1 .. m2_final], lcs)
    unless rlcs.nil?
      rsdiff.each {|h| h.old_position += m1_initial; h.new_position += m2_initial + 1}
      return rlcs, rsdiff
    end

    rlcs, rsdiff = min_lcs_sdiff(str1[m1_initial .. m1_final], str2[m2_initial .. m2_final - 1], lcs)
    unless rlcs.nil?
      rsdiff.each {|h| h.old_position += m1_initial; h.new_position += m2_initial}
      return rlcs, rsdiff
    end

    return lcs, sdiff
  end
end


if __FILE__ == $0
  require 'text_alignment/lcs_cdiff'

  str2 = 'naxbyzabcdexydzem'
  str1 = 'abcde'

  if ARGV.length == 2
    str1 = File.read(ARGV[0]).strip
    str2 = File.read(ARGV[1]).strip
  end

  lcs, sdiff =TextAlignment.min_lcs_sdiff(str1, str2)
  puts lcs
  p sdiff
  puts TextAlignment.sdiff2cdiff(sdiff)
end
