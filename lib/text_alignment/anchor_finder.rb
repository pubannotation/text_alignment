#!/usr/bin/env ruby
require 'text_alignment/constants'
require 'string-similarity'

module TextAlignment; end unless defined? TextAlignment

class TextAlignment::AnchorFinder

	def initialize(source_str, target_str, cultivation_map)
		@s1 = source_str.downcase
		@s2 = target_str.downcase

		@cultivation_map = cultivation_map

		@size_ngram  = TextAlignment::SIZE_NGRAM
		@size_window = TextAlignment::SIZE_WINDOW
		@sim_threshold = TextAlignment::TEXT_SIMILARITY_THRESHOLD
		@pos_s1_final_possible_begin = @s1.length - @size_ngram - 1
		@pos_s2_final_possible_end = @s2.length

		# positions of last match
		@pos_s1_last_match = 0
		@pos_s2_last_match = 0
	end

	def get_next_anchor
		# To find the beginning positions of an anchor ngram in s1 and s2, beginning from the last positions matched
		beg_s2 = for beg_s1 in @pos_s1_last_match .. @pos_s1_final_possible_begin

			# To skip whitespace letters
			next if [' ', "\n", "\t"].include? @s1[beg_s1]

			_beg_s2 = get_beg_s2(beg_s1)
			break _beg_s2 unless _beg_s2.nil?
		end

		# To return nil when it fails to find an anchor
		return nil if beg_s2.class == Range

		# To extend the block to the left
		b1 = beg_s1
		b2 = beg_s2
		left_boundary_b2 = [@pos_s2_last_match, (@cultivation_map.last_cultivated_position(b2) || 0)].max
		while b1 > @pos_s1_last_match && b2 > left_boundary_b2 && @s1[b1 - 1] == @s2[b2 - 1]
			b1 -= 1; b2 -= 1
		end

		# To extend the block to the right
		e1 = beg_s1 + @size_ngram
		e2 = beg_s2 + @size_ngram
		right_boundary_b2 = @cultivation_map.next_cultivated_position(e2) || @pos_s2_final_possible_end
		while @s1[e1] && e2 < right_boundary_b2 && @s1[e1] == @s2[e2]
			e1 += 1; e2 += 1
		end

		@pos_s1_last_match = e1
		@pos_s2_last_match = e2

		{source:{begin:b1 , end:e1}, target:{begin:b2, end:e2}}
	end

	private

	def get_beg_s2(beg_s1)
		# to get the anchor to search for in s2
		anchor = @s1[beg_s1, @size_ngram]

		# comment out below with the assumption that texts are in the same order
		# search_position = 0
		search_position = @pos_s2_last_match

		beg_s2_candidates = find_beg_s2_candidates(anchor, search_position)
		return nil if beg_s2_candidates.empty?

		find_valid_beg_s2(beg_s1, beg_s2_candidates)
	end

	# To find beg_s2 which match to the anchor
	# return nil if the anchor is too much frequent
	def find_beg_s2_candidates(anchor, search_position)
		candidates = []
		while _beg_s2 = @cultivation_map.index(anchor, @s2, search_position)
			candidates << _beg_s2

			# for speed, skip anchor of high frequency
			if candidates.length > 5
				candidates.clear
				break
			end

			search_position = _beg_s2 + 1
		end
		candidates
	end

	def find_valid_beg_s2(beg_s1, beg_s2_candidates)
		valid_beg_s2 = nil

		(10 .. 30).step(10).each do |size_window|
			valid_beg_s2 = nil

			r = beg_s2_candidates.each do |beg_s2|
				# if both the begining points are sufficiantly close to the end points of the last match
				# break if beg_s1 > 0 && beg_s2 > 0 && (beg_s1 - @pos_s1_last_match < 5) && (beg_s2 >= @pos_s2_last_match) && (beg_s2 - @pos_s2_last_match < 5)
				if beg_s1 > 0 && beg_s2 > 0 && (beg_s1 - @pos_s1_last_match < 5) && (beg_s2 - @pos_s2_last_match < 5)
					break unless valid_beg_s2.nil?
					valid_beg_s2 = beg_s2
					next
				end

				left_window_s1, left_window_s2 = get_left_windows(beg_s1, beg_s2)
				if left_window_s1 && (text_similarity(left_window_s1, left_window_s2) > @sim_threshold)
					break unless valid_beg_s2.nil?
					valid_beg_s2 = beg_s2
					next
				end

				right_window_s1, right_window_s2 = get_right_windows(beg_s1, beg_s2)
				if right_window_s2 && (text_similarity(right_window_s1, right_window_s2) > @sim_threshold)
					break unless valid_beg_s2.nil?
					valid_beg_s2 = beg_s2
					next
				end
			end

			# r == nil means that the inner loop was broken (multiple candidates had passed the tests)
			# r != nil means that the inner loop was completed (with or w/o a valid beg_s2 found)
			break unless r.nil?
		end

		valid_beg_s2
	end

	def get_left_windows(beg_s1, beg_s2, size_window = nil)
		size_window ||= @size_window

		# comment out below with the assumption that the beginning of a document gives a significant locational information
		# return if @beg_s1 < size_window || @beg_s2 < size_window

		window_s1 = ''
		loc = beg_s1 - 1
		count = 0
		while count < size_window && loc >= 0
			if @s1[loc] =~ /[0-9a-zA-Z]/
				window_s1 += @s1[loc]
				count += 1
			end
			loc -= 1
		end

		window_s2 = ''
		loc = beg_s2 - 1
		count = 0
		while count < size_window && loc >= 0
			if @s2[loc] =~ /[0-9a-zA-Z]/
				window_s2 += @s2[loc]
				count += 1
			end
			loc -= 1
		end

		[window_s1, window_s2]
	end

	def get_right_windows(beg_s1, beg_s2, size_window = nil)
		size_window ||= @size_window

		# commend below with the assumption that the end of a document gives a significant locational
		# return if (@beg_s1 + @size_ngram > (@s1.length - size_window)) || (@beg_s2 + @size_ngram > (@s2.length - size_window))

		window_s1 = ''
		loc = beg_s1 + @size_ngram
		len_s1 = @s1.length
		count = 0
		while count < size_window && loc < len_s1
			if @s1[loc] =~ /[0-9a-zA-Z]/
				window_s1 += @s1[loc]
				count += 1
			end
			loc += 1
		end

		window_s2 = ''
		loc = beg_s2 + @size_ngram
		len_s2 = @s2.length
		count = 0
		while count < size_window && loc < len_s2
			if @s2[loc] =~ /[0-9a-zA-Z]/
				window_s2 += @s2[loc]
				count += 1
			end
			loc += 1
		end

		[window_s1, window_s2]
	end

	def text_similarity(str1, str2, ngram_order = 2)
		return 0 if str1.nil? || str2.nil?
		String::Similarity.cosine(str1, str2, ngram:ngram_order)
	end
end
