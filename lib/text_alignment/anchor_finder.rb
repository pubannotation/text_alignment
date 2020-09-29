#!/usr/bin/env ruby
require 'text_alignment/constants'
require 'string-similarity'

module TextAlignment; end unless defined? TextAlignment

class TextAlignment::AnchorFinder

	def initialize(source_str, target_str, _size_ngram = nil, _size_window = nil, _text_similiarity_threshold = nil)
		@size_ngram  = _size_ngram  || TextAlignment::SIZE_NGRAM
		@size_window = _size_window || TextAlignment::SIZE_WINDOW
		@sim_threshold = _text_similiarity_threshold || TextAlignment::TEXT_SIMILARITY_THRESHOLD

		@reverse = (target_str.length < source_str.length)

		@s1, @s2 = if @reverse
			[target_str.downcase, source_str.downcase]
		else
			[source_str.downcase, target_str.downcase]
		end

		# current position in s1
		@beg_s1 = 0
		@end_s1_prev = 0
		@end_s2_prev = 0
	end

	def get_next_anchor
		# find the position of an anchor ngram in s1 and s2
		while @beg_s1 < (@s1.length - @size_ngram)
			if [' ', "\n", "\t"].include? @s1[@beg_s1]
				@beg_s1 += 1
				next
			end
			anchor = @s1[@beg_s1, @size_ngram]

			# search_position = 0
			search_position = @end_s2_prev
			while @beg_s2 = @s2.index(anchor, search_position)
				# if both the begining points are sufficiantly close to the end points of the last match
				break if @beg_s1 > 0 && @beg_s2 > 0 && (@beg_s1 - @end_s1_prev < 5) && (@beg_s2 >= @end_s2_prev) && (@beg_s2 - @end_s2_prev < 5)

				left_window_s1, left_window_s2 = get_left_windows
				break if left_window_s1 && (text_similarity(left_window_s1, left_window_s2) > @sim_threshold)

				right_window_s1, right_window_s2 = get_right_windows
				break if right_window_s2 && (text_similarity(right_window_s1, right_window_s2) > @sim_threshold)

				search_position = @beg_s2 + 1
			end

			break unless @beg_s2.nil?

			@beg_s1 += 1
		end

		return nil if @beg_s1 >= (@s1.length - @size_ngram)

		# extend the block
		b1 = @beg_s1
		b2 = @beg_s2
		while b1 >= @end_s1_prev && b2 >= @end_s2_prev && @s1[b1] == @s2[b2]
			b1 -= 1; b2 -= 1
		end

		b1 += 1; b2 += 1

		e1 = @beg_s1 + @size_ngram
		e2 = @beg_s2 + @size_ngram
		while @s1[e1] && @s1[e1] == @s2[e2]
			e1 += 1; e2 += 1
		end

		@end_s1_prev = e1
		@end_s2_prev = e2
		@beg_s1 = e1

		if @reverse
			{source:{begin:b2 , end:e2}, target:{begin:b1, end:e1}}
		else
			{source:{begin:b1 , end:e1}, target:{begin:b2, end:e2}}
		end
	end

	private

	def get_left_windows
		# commend below with the assumption that the beginning of a document gives a significant locational information
		# return if @beg_s1 < @size_window || @beg_s2 < @size_window

		window_s1 = ''
		loc = @beg_s1 - 1
		count = 0
		while count < @size_window && loc >= 0
			if @s1[loc] =~ /[0-9a-zA-Z]/
				window_s1 += @s1[loc]
				count += 1
			end
			loc -= 1
		end

		window_s2 = ''
		loc = @beg_s2 - 1
		count = 0
		while count < @size_window && loc >= 0
			if @s2[loc] =~ /[0-9a-zA-Z]/
				window_s2 += @s2[loc]
				count += 1
			end
			loc -= 1
		end

		[window_s1, window_s2]
	end

	def get_right_windows
		# commend below with the assumption that the end of a document gives a significant locational
		# return if (@beg_s1 + @size_ngram > (@s1.length - @size_window)) || (@beg_s2 + @size_ngram > (@s2.length - @size_window))

		window_s1 = ''
		loc = @beg_s1 + @size_ngram
		len_s1 = @s1.length
		count = 0
		while count < @size_window && loc < len_s1
			if @s1[loc] =~ /[0-9a-zA-Z]/
				window_s1 += @s1[loc]
				count += 1
			end
			loc += 1
		end

		window_s2 = ''
		loc = @beg_s2 + @size_ngram
		len_s2 = @s2.length
		count = 0
		while count < @size_window && loc < len_s2
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