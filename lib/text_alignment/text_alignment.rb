#!/usr/bin/env ruby
require 'text_alignment/constants'
require 'text_alignment/anchor_finder'
require 'text_alignment/mixed_alignment'

module TextAlignment; end unless defined? TextAlignment

TextAlignment::PADDING_LETTERS = ['@', '^', '|', '#', '$', '%', '&', '_'] unless defined? TextAlignment::PADDING_LETTERS

class TextAlignment::TextAlignment
	attr_reader :block_alignment
	attr_reader :similarity
	attr_reader :lost_annotations

	def initialize(_str1, _str2, _size_ngram = nil, _size_window = nil, _text_similiarity_threshold = nil)
		raise ArgumentError, "nil string" if _str1.nil? || _str2.nil?

		@block_alignment = {source_text:_str1, target_text:_str2}

		str1, str2, mappings = string_preprocessing(_str1, _str2)

		# try exact match
		block_begin = str2.index(str1)
		unless block_begin.nil?
			@block_alignment[:blocks] = [{source:{begin:0, end:str1.length}, target:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin, alignment: :block}]
			return @block_alignment
		end

		# try exact match
		block_begin = str2.downcase.index(str1.downcase)
		unless block_begin.nil?
			@block_alignment[:blocks] = [{source:{begin:0, end:str1.length}, target:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin, alignment: :block}]
			return @block_alignment
		end

		anchor_finder = TextAlignment::AnchorFinder.new(str1, str2, _size_ngram, _size_window, _text_similiarity_threshold)

		# To collect matched blocks
		mblocks = []
		while anchor = anchor_finder.get_next_anchor
			last = mblocks.last
			if last && (anchor[:source][:begin] == last[:source][:end] + 1) && (anchor[:target][:begin] == last[:target][:end] + 1)
				last[:source][:end] = anchor[:source][:end]
				last[:target][:end] = anchor[:target][:end]
			else
				mblocks << anchor
			end
		end

		# pp mblocks
		# puts "-----"
		# puts
		# mblocks.each do |b|
		# 	p [b[:source], b[:target]]
		# 	puts "---"
		# 	puts str1[b[:source][:begin] ... b[:source][:end]]
		# 	puts "---"
		# 	puts str2[b[:target][:begin] ... b[:target][:end]]
		# 	puts "====="
		# 	puts
		# end
		# puts "-=-=-=-=-"
		# puts

		## To find block alignments
		@block_alignment[:blocks] = []
		return if mblocks.empty?

		# Initial step
		if mblocks[0][:source][:begin] > 0
			e1 = mblocks[0][:source][:begin]
			e2 = mblocks[0][:target][:begin]

			if mblocks[0][:target][:begin] == 0
				@block_alignment[:blocks] << {source:{begin:0, end:e1}, target:{begin:0, end:0}, alignment: :empty}
			else
				_str1 = str1[0 ... e1]
				_str2 = str2[0 ... e2]

				unless _str1.strip.empty?
					if _str2.strip.empty?
						@block_alignment[:blocks] << {source:{begin:0, end:e1}, target:{begin:0, end:e2}, alignment: :empty}
					else
						len_min = [_str1.length, _str2.length].min
						len_buffer = (len_min * (1 + TextAlignment::BUFFER_RATE)).to_i + TextAlignment::BUFFER_MIN
						b1 = _str1.length < len_buffer ? 0 : e1 - len_buffer
						b2 = _str2.length < len_buffer ? 0 : e2 - len_buffer

						@block_alignment[:blocks] << {source:{begin:0, end:b1}, target:{begin:0, end:b2}, alignment: :empty} if b1 > 0

						_str1 = str1[b1 ... e1]
						_str2 = str2[b2 ... e2]
						alignment = TextAlignment::MixedAlignment.new(_str1.downcase, _str2.downcase, mappings)
						similarity = alignment_similarity(_str1, _str2, alignment)
						if similarity < 0.6
							@block_alignment[:blocks] << {source:{begin:b1, end:e1}, target:{begin:0, end:e2}, alignment: :empty, similarity: similarity}
						else
							@block_alignment[:blocks] << {source:{begin:b1, end:e1}, target:{begin:0, end:e2}, alignment:alignment}
						end
					end
				end
			end
		end
		@block_alignment[:blocks] << mblocks[0].merge(alignment: :block)

		(1 ... mblocks.length).each do |i|
			b1 = mblocks[i - 1][:source][:end]
			b2 = mblocks[i - 1][:target][:end]
			e1 = mblocks[i][:source][:begin]
			e2 = mblocks[i][:target][:begin]
			_str1 = str1[b1 ... e1]
			_str2 = str2[b2 ... e2]
			unless _str1.strip.empty?
				if _str2.strip.empty?
					@block_alignment[:blocks] << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty}
				else
					alignment = TextAlignment::MixedAlignment.new(_str1.downcase, _str2.downcase, mappings)
					similarity = alignment_similarity(_str1, _str2, alignment)
					if similarity < 0.6
						@block_alignment[:blocks] << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty, similarity: similarity}
					else
						@block_alignment[:blocks] << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment:alignment}
					end
				end
			end
			@block_alignment[:blocks] << mblocks[i].merge(alignment: :block)
		end

		# Final step
		if  mblocks[-1][:source][:end] < str1.length && mblocks[-1][:target][:end] < str2.length
			b1 = mblocks[-1][:source][:end]
			b2 = mblocks[-1][:target][:end]
			_str1 = str1[b1 ... str1.length]
			_str2 = str2[b2 ... str2.length]

			unless _str1.strip.empty?
				if _str2.strip.empty?
					@block_alignment[:blocks] << {source:{begin:b1, end:str1.length}, target:{begin:b2, end:str2.length}, alignment: :empty}
				else
					len_min = [_str1.length, _str2.length].min
					len_buffer = (len_min * (1 + TextAlignment::BUFFER_RATE)).to_i + TextAlignment::BUFFER_MIN
					e1 = _str1.length < len_buffer ? str1.length : b1 + len_buffer
					e2 = _str2.length < len_buffer ? str2.length : b2 + len_buffer
					_str1 = str1[b1 ... e1]
					_str2 = str2[b2 ... e2]

					alignment = TextAlignment::MixedAlignment.new(_str1.downcase, _str2.downcase, mappings)
					similarity = alignment_similarity(_str1, _str2, alignment)
					if similarity < 0.6
						@block_alignment[:blocks] << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty, similarity: similarity}
					else
						@block_alignment[:blocks] << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment:alignment}
					end

					@block_alignment[:blocks] << {source:{begin:e1, end:-1}, target:{begin:e2, end:-1}, alignment: :empty} if e1 < str1.length
				end
			end
		end

		@block_alignment[:blocks].each do |a|
			a[:delta] = a[:target][:begin] - a[:source][:begin]
		end
	end

	def transform_begin_position(begin_position)
		i = @block_alignment[:blocks].index{|b| b[:source][:end] > begin_position}
		block = @block_alignment[:blocks][i]

		b = if block[:alignment] == :block
			begin_position + block[:delta]
		elsif block[:alignment] == :empty
			if begin_position == block[:source][:begin]
				block[:target][:begin]
			else
				# raise "lost annotation"
				nil
			end
		else
			r = block[:alignment].transform_begin_position(begin_position - block[:source][:begin])
			r.nil? ? nil : r + block[:target][:begin]
		end
	end

	def transform_end_position(end_position)
		i = @block_alignment[:blocks].index{|b| b[:source][:end] >= end_position}
		block = @block_alignment[:blocks][i]

		e = if block[:alignment] == :block
			end_position + block[:delta]
		elsif block[:alignment] == :empty
			if end_position == block[:source][:end]
				block[:target][:end]
			else
				# raise "lost annotation"
				nil
			end
		else
			r = block[:alignment].transform_end_position(end_position - block[:source][:begin])
			r.nil? ? nil : r + block[:target][:begin]
		end
	end

	def transform_a_span(span)
		{begin: transform_begin_position(span[:begin]), end: transform_end_position(span[:end])}
	end

	def transform_spans(spans)
		spans.map{|span| transform_a_span(span)}
	end

	def transform_denotations!(denotations)
		return nil if denotations.nil?
		@lost_annotations = []

		denotations.each do |d|
			begin
				d.begin = transform_begin_position(d.begin);
				d.end = transform_end_position(d.end);
			rescue
				@lost_annotations << d
				d.begin = nil
				d.end = nil
			end
		end

		@lost_annotations
	end

	def transform_hdenotations(hdenotations)
		return nil if hdenotations.nil?
		@lost_annotations = []

		r = hdenotations.collect do |d|
			new_d = begin
				d.dup.merge({span:transform_a_span(d[:span])})
			rescue
				@lost_annotations << d
				nil
			end
		end.compact

		r
	end

	def alignment_show
		stext = @block_alignment[:source_text]
		ttext = @block_alignment[:target_text]

		show = ''
		@block_alignment[:blocks].each do |a|
			show += case a[:alignment]
			when :block
				"===== common =====\n" +
				stext[a[:source][:begin] ... a[:source][:end]] + "\n\n"
			when :empty
				"xxxxx disparate texts (similarity: #{a[:similarity]})\n" +
				"<<<<< string 1\n" +
				stext[a[:source][:begin] ... a[:source][:end]] + "\n\n" +
				">>>>> string 2\n" +
				ttext[a[:target][:begin] ... a[:target][:end]] + "\n\n"
			else
				astr1 = ''
				astr2 = ''

				base = a[:source][:begin]
				astr1 = a[:alignment].sdiff.map do |c|
					case c.action
					when '='
						stext[c.old_position + base]
					when '+'
						'_'
					when '-'
						stext[c.old_position + base]
					when '!'
						stext[c.old_position + base] + '_'
					end
				end.join('')

				base = a[:target][:begin]
				astr2 = a[:alignment].sdiff.map do |c|
					case c.action
					when '='
						ttext[c.new_position + base]
					when '+'
						ttext[c.new_position + base]
					when '-'
						'_'
					when '!'
						'_' + ttext[c.new_position + base]
					end
				end.join('')

				"***** local mismatch\n" +
				"[#{astr1}]\n" +
				"[#{astr2}]\n\n"
			end
		end
		show
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

	def alignment_similarity(_s1, _s2, alignment)
		return 0 if alignment.sdiff.nil?

		# compute the lcs only with non-whitespace letters
		lcs = alignment.sdiff.count{|d| d.action == '=' && d.old_element =~ /\S/ && d.new_element =~ /\S/}

		s1 = _s1.tr(@padding_letter1, ' ')
		s2 = _s2.tr(@padding_letter2, ' ')

		similarity = 2 * lcs / (s1.scan(/\S/).count + s2.scan(/\S/).count).to_f
	end

end
