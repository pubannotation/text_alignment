#!/usr/bin/env ruby
require 'diff-lcs'
require 'text_alignment/lcs_min'
require 'text_alignment/find_divisions'
require 'text_alignment/lcs_comparison'
require 'text_alignment/lcs_alignment'
require 'text_alignment/lcs_cdiff'
require 'text_alignment/glcs_alignment'
require 'text_alignment/char_mapping'

module TextAlignment; end unless defined? TextAlignment

class TextAlignment::MixedAlignment
	attr_reader :sdiff
	attr_reader :position_map_begin, :position_map_end
	attr_reader :common_elements, :mapped_elements
	attr_reader :similarity
	attr_reader :str1_match_initial, :str1_match_final, :str2_match_initial, :str2_match_final

	def initialize(_str1, _str2, _mappings = nil)
		raise ArgumentError, "nil string" if _str1.nil? || _str2.nil?

		mappings ||= TextAlignment::CHAR_MAPPING
		str1 = _str1.dup
		str2 = _str2.dup

		_compute_mixed_alignment(str1, str2, mappings)
	end

	def transform_begin_position(begin_position)
		@position_map_begin[begin_position]
	end

	def transform_end_position(end_position)
		@position_map_end[end_position]
	end

	def transform_a_span(span)
		{begin: @position_map_begin[span[:begin]], end: @position_map_end[span[:end]]}
	end

	def transform_spans(spans)
		spans.map{|span| transform_a_span(span)}
	end

	def transform_denotations!(denotations)
		denotations.map!{|d| d.begin = @position_map_begin[d.begin]; d.end = @position_map_end[d.end]; d} unless denotations.nil?
	end

	def transform_hdenotations(hdenotations)
		return nil if hdenotations.nil?
		hdenotations.collect{|d| d.dup.merge({span:transform_a_span(d[:span])})}
	end

	private

	def _compute_mixed_alignment(str1, str2, mappings = [])
		lcsmin = TextAlignment::LCSMin.new(str1, str2)
		lcs = lcsmin.lcs
		@sdiff = lcsmin.sdiff

		if @sdiff.nil?
			@similarity = 0
			return
		end

		cmp = TextAlignment::LCSComparison.new(str1, str2, lcs, @sdiff)
		@similarity         = compute_similarity(str1, str2, @sdiff)
		@str1_match_initial = cmp.str1_match_initial
		@str1_match_final   = cmp.str1_match_final
		@str2_match_initial = cmp.str2_match_initial
		@str2_match_final   = cmp.str2_match_final

		posmap_begin, posmap_end = {}, {}
		@common_elements, @mapped_elements = [], []

		addition, deletion = [], []

		@sdiff.each do |h|
			case h.action
			when '='
				p1, p2 = h.old_position, h.new_position

				@common_elements << [str1[p1], str2[p2]]
				posmap_begin[p1], posmap_end[p1] = p2, p2

				if !addition.empty? && deletion.empty?
					posmap_end[p1] = p2 - addition.length unless p1 == 0
				elsif addition.empty? && !deletion.empty?
					deletion.each{|p| posmap_begin[p], posmap_end[p] = p2, p2}
				elsif !addition.empty? && !deletion.empty?
					if addition.length > 1 || deletion.length > 1
						galign = TextAlignment::GLCSAlignment.new(str1[deletion[0] .. deletion[-1]], str2[addition[0] .. addition[-1]], mappings)
						galign.position_map_begin.each {|k, v| posmap_begin[k + deletion[0]] = v.nil? ? nil : v + addition[0]}
						galign.position_map_end.each   {|k, v|   posmap_end[k + deletion[0]] = v.nil? ? nil : v + addition[0]}
						posmap_begin[p1], posmap_end[p1] = p2, p2
						@common_elements += galign.common_elements
						@mapped_elements += galign.mapped_elements
					else
						posmap_begin[deletion[0]], posmap_end[deletion[0]] = addition[0], addition[0]
						deletion[1..-1].each{|p| posmap_begin[p], posmap_end[p] = nil, nil}
						@mapped_elements << [str1[deletion[0], deletion.length], str2[addition[0], addition.length]]
					end
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

		p1, p2 = str1.length, str2.length
		posmap_begin[p1], posmap_end[p1] = p2, p2

		if !addition.empty? && deletion.empty?
			posmap_end[p1] = p2 - addition.length unless p1 == 0
		elsif addition.empty? && !deletion.empty?
			deletion.each{|p| posmap_begin[p], posmap_end[p] = p2, p2}
		elsif !addition.empty? && !deletion.empty?
			if addition.length > 1 && deletion.length > 1
				galign = TextAlignment::GLCSAlignment.new(str1[deletion[0] .. deletion[-1]], str2[addition[0] .. addition[-1]], mappings)
				galign.position_map_begin.each {|k, v| posmap_begin[k + deletion[0]] = v.nil? ? nil : v + addition[0]}
				galign.position_map_end.each   {|k, v|   posmap_end[k + deletion[0]] = v.nil? ? nil : v + addition[0]}
				posmap_begin[p1], posmap_end[p1] = p2, p2
				@common_elements += galign.common_elements
				@mapped_elements += galign.mapped_elements
			else
				posmap_begin[deletion[0]], posmap_end[deletion[0]] = addition[0], addition[0]
				deletion[1..-1].each{|p| posmap_begin[p], posmap_end[p] = nil, nil}
				@mapped_elements << [str1[deletion[0], deletion.length], str2[addition[0], addition.length]]
			end
		end

		@position_map_begin = posmap_begin.sort.to_h
		@position_map_end = posmap_end.sort.to_h
	end

	def compute_similarity(s1, s2, sdiff)
		return 0 if sdiff.nil?

		# recoverbility
		count_nws =	sdiff.count{|d| d.old_element =~ /\S/}
		count_nws_match =	sdiff.count{|d| d.action == '=' && d.old_element =~ /\S/}
		coverage = count_nws_match.to_f / count_nws

		# fragmentation rate
		frag_str = sdiff.collect do |d|
			case d.action
			when '='
				'='
			when '-'
				''
			when '+'
				(d.new_element =~ /\S/) ? '+' : ''
			else
				''
			end
		end.join.sub(/^[^=]++/, '').sub(/[^=]+$/, '')

		count_frag = frag_str.scan(/=+/).count
		rate_frag = 1.0 / count_frag

		similarity = coverage * rate_frag
	end
end
