#!/usr/bin/env ruby
require 'diff-lcs'
require 'text_alignment/lcs_min'
require 'text_alignment/find_divisions'
require 'text_alignment/lcs_comparison'
require 'text_alignment/lcs_alignment'
require 'text_alignment/lcs_cdiff'
require 'text_alignment/glcs_alignment'
require 'text_alignment/mappings'

module TextAlignment; end unless defined? TextAlignment

class TextAlignment::MixedAlignment
	attr_reader :sdiff
	attr_reader :position_map_begin, :position_map_end
	attr_reader :common_elements, :mapped_elements
	attr_reader :similarity
	attr_reader :str1_match_initial, :str1_match_final, :str2_match_initial, :str2_match_final

	def initialize(_str1, _str2)
		raise ArgumentError, "nil string" if _str1.nil? || _str2.nil?

		str1, str2, mappings = string_preprocessing(_str1, _str2)

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

	private

	def string_preprocessing(_str1, _str2)
		str1 = _str1.dup
		str2 = _str2.dup
		mappings = TextAlignment::MAPPINGS.dup

		## single character mappings
		character_mappings = mappings.select{|m| m[0].length == 1 && m[1].length == 1}
		characters_from = character_mappings.collect{|m| m[0]}.join
		characters_to   = character_mappings.collect{|m| m[1]}.join
		characters_to.gsub!(/-/, '\-')

		str1.tr!(characters_from, characters_to)
		str2.tr!(characters_from, characters_to)

		mappings.delete_if{|m| m[0].length == 1 && m[1].length == 1}

		## long to one character mappings
		pletters = TextAlignment::PADDING_LETTERS

		# find the padding letter for str1
		@padding_letter1 = begin
			i = pletters.index{|l| str2.index(l).nil?}
			raise RuntimeError, "Could not find a padding letter for str1" if i.nil?
			TextAlignment::PADDING_LETTERS[i]
		end

		# find the padding letter for str2
		@padding_letter2 = begin
			i = pletters.index{|l| l != @padding_letter1 && str1.index(l).nil?}
			raise RuntimeError, "Could not find a padding letter for str2" if i.nil?
			TextAlignment::PADDING_LETTERS[i]
		end

		# ASCII foldings
		ascii_foldings = mappings.select{|m| m[0].length == 1 && m[1].length > 1}
		ascii_foldings.each do |f|
			from = f[1]

			if str2.index(f[0])
				to   = f[0] + (@padding_letter1 * (f[1].length - 1))
				str1.gsub!(from, to)
			end

			if str1.index(f[0])
				to   = f[0] + (@padding_letter2 * (f[1].length - 1))
				str2.gsub!(from, to)
			end
		end
		mappings.delete_if{|m| m[0].length == 1 && m[1].length > 1}

		[str1, str2, mappings]
	end

	def compute_similarity(_s1, _s2, sdiff)
		return 0 if sdiff.nil?

		# compute the lcs only with non-whitespace letters
		lcs = sdiff.count{|d| d.action == '=' && d.old_element =~ /\S/ && d.new_element =~ /\S/}
		return 0 if lcs == 0

		s1 = _s1.tr(@padding_letter1, ' ')
		s2 = _s2.tr(@padding_letter2, ' ')

		similarity = lcs / [s1.scan(/\S/).count, s2.scan(/\S/).count].min.to_f
	end

end
