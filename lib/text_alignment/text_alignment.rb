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

	def initialize(str1, str2, denotations = nil, _size_ngram = nil, _size_window = nil, _text_similiarity_threshold = nil)
		raise ArgumentError, "nil string" if str1.nil? || str2.nil?

		@block_alignment = {source_text:str1, target_text:str2}
		@str1 = str1
		@str2 = str2

		## Block exact match
		block_begin = str2.index(str1)
		unless block_begin.nil?
			@block_alignment[:blocks] = [{source:{begin:0, end:str1.length}, target:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin, alignment: :block}]
			return
		end

		block_begin = str2.downcase.index(str1.downcase)
		unless block_begin.nil?
			@block_alignment[:blocks] = [{source:{begin:0, end:str1.length}, target:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin, alignment: :block}]
			return
		end


		## to find block alignments
		anchor_finder = TextAlignment::AnchorFinder.new(str1, str2, _size_ngram, _size_window, _text_similiarity_threshold)

		blocks = []
		while block = anchor_finder.get_next_anchor
			last = blocks.last
			if last && (block[:source][:begin] == last[:source][:end] + 1) && (block[:target][:begin] == last[:target][:end] + 1)
				last[:source][:end] = block[:source][:end]
				last[:target][:end] = block[:target][:end]
			else
				blocks << block.merge(alignment: :block, delta: block[:target][:begin] - block[:source][:begin])
			end
		end

		# pp blocks
		# puts "-----"
		# puts
		# exit
		# blocks.each do |b|
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

		## to fill the gaps
		last_block = nil
		blocks2 = blocks.inject([]) do |sum, block|
			b1 = last_block ? last_block[:source][:end] : 0
			e1 = block[:source][:begin]

			sum += if b1 == e1
				[block]
			else
				b2 = last_block ? last_block[:target][:end] : 0
				e2 = block[:target][:begin]

				if b2 == e2
					[
						{source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty},
						block
					]
				else
					if b1 == 0 && b2 == 0
						len_buffer = (e1 * (1 + TextAlignment::BUFFER_RATE)).to_i + TextAlignment::BUFFER_MIN
						b2 = e2 - len_buffer if e2 > len_buffer
					end

					_str1 = str1[b1 ... e1]
					_str2 = str2[b2 ... e2]

					if _str1.strip.empty? || _str2.strip.empty?
						[
							{source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty},
							block
						]
					else
						local_alignment_blocks(str1, b1, e1, str2, b2, e2, denotations) << block
					end
				end
			end

			last_block = block
			sum
		end

		# the last step
		blocks2 += if last_block.nil?
			local_alignment_blocks(str1, 0, str1.length, str2, 0, str2.length, denotations)
		else
			b1 = last_block[:source][:end]
			if b1 < str1.length
				e1 = str1.length

				b2 = last_block[:target][:end]
				if b2 < str2.length
					len_buffer = ((e1 - b1) * (1 + TextAlignment::BUFFER_RATE)).to_i + TextAlignment::BUFFER_MIN
					e2 = (str2.length - b2) > len_buffer ? b2 + len_buffer : str2.length
					local_alignment_blocks(str1, b1, e1, str2, b2, e2, denotations)
				else
					[{source:{begin:last_block[:source][:end], end:str1.length}, alignment: :empty}]
				end
			else
				[]
			end
		end

		@block_alignment[:blocks] = blocks2
	end

	def local_alignment_blocks(str1, b1, e1, str2, b2, e2, denotations = nil)
		block2 = str2[b2 ... e2]

		## term-based alignment
		tblocks = if denotations
			ds_in_scope = denotations.select{|d| d[:span][:begin] >= b1 && d[:span][:end] <= e1}.
							sort{|d1, d2| d1[:span][:begin] <=> d2[:span][:begin] || d2[:span][:end] <=> d1[:span][:end] }.
							map{|d| d.merge(lex:str1[d[:span][:begin] ... d[:span][:end]])}

			position = 0
			tblocks = ds_in_scope.map do |term|
				lex = term[:lex]
				r = block2.index(lex, position)
				if r.nil?
					position = nil
					break
				end
				position = r + lex.length
				{source:term[:span], target:{begin:r + b2, end:r + b2 + lex.length}, alignment: :term, delta: r - term[:span][:begin]}
			end

			# missing term found
			tblocks = [] if position.nil?

			# redundant matching found
			unless position.nil?
				ds_in_scope.each do |term|
					lex = term[:lex]
					look_forward = block2.index(lex, position)
					unless look_forward.nil?
						puts lex
						tblocks = []
						break
					end
				end
			end

			tblocks
		end

		if tblocks.empty?
			if b1 == 0 && e1 == str1.length
				block1 = str1[b1 ... e1]
				block2 = str2[b2 ... e2]

				## character-based alignment
				alignment = TextAlignment::MixedAlignment.new(block1.downcase, block2.downcase)
				if alignment.sdiff.nil?
					[{source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty}]
				else
					[{source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: alignment, similarity: alignment.similarity}]
				end
			else
				block1 = str1[b1 ... e1]
				block2 = str2[b2 ... e2]

				## character-based alignment
				alignment = TextAlignment::MixedAlignment.new(block1.downcase, block2.downcase)
				if alignment.sdiff.nil?
					[{source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty}]
				else
					[{source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: alignment, similarity: alignment.similarity}]
				end
			end
		else
			last_tblock = nil
			lblocks = tblocks.inject([]) do |sum, tblock|
				tb1 = last_tblock ? last_tblock[:source][:end] : b1
				te1 = tblock[:source][:begin]

				sum += if te1 == tb1
					[tblock]
				else
					tb2 = last_tblock ? last_tblock[:target][:end] : b2
					te2 = tblock[:target][:begin]

					if b2 == e2
						[
							{source:{begin:tb1, end:te1}, alignment: :empty},
							tblock
						]
					else
						[
							{source:{begin:tb1, end:te1}, target:{begin:tb2, end:te2}, alignment: :empty},
							tblock
						]
					end
				end

				last_tblock = tblock
				sum
			end

			if last_tblock[:source][:end] < e1
				if last_tblock[:target][:end] < e2
					lblocks << {source:{begin:last_tblock[:source][:end], end:e1}, target:{begin:last_tblock[:target][:end], end:e2}, alignment: :empty}
				else
					lblocks << {source:{begin:last_tblock[:source][:end], end:e1}, alignment: :empty}
				end
			end

			lblocks
		end
	end


	def indices(str, target)
	  position = 0
	  len = target.len
	  Enumerator.new do |yielder|
	    while idx = str.index(target, position)
	      yielder << idx
	      position = idx + len
	    end
	  end
	end

	def transform_begin_position(begin_position)
		i = @block_alignment[:blocks].index{|b| b[:source][:end] > begin_position}
		block = @block_alignment[:blocks][i]

		b = if block[:alignment] == :block || block[:alignment] == :term
			begin_position + block[:delta]
		elsif block[:alignment] == :empty
			if begin_position == block[:source][:begin]
				block[:target][:begin]
			else
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

		e = if block[:alignment] == :block || block[:alignment] == :term
			end_position + block[:delta]
		elsif block[:alignment] == :empty
			if end_position == block[:source][:end]
				block[:target][:end]
			else
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
			source = {begin:d.begin, end:d.end}
			d.begin = transform_begin_position(d.begin);
			d.end = transform_end_position(d.end);
			raise "invalid transform" unless !d.begin.nil? && !d.end.nil? && d.begin >= 0 && d.end > d.begin && d.end <= @str2.length
		rescue
			@lost_annotations << {source: source, target:{begin:d.begin, end:d.end}}
			d.begin = nil
			d.end = nil
		end

		@lost_annotations
	end

	def transform_hdenotations(hdenotations)
		return nil if hdenotations.nil?
		@lost_annotations = []

		r = hdenotations.collect do |d|
			t = transform_a_span(d[:span])
			raise "invalid transform" unless !t[:begin].nil? && !t[:end].nil? && t[:begin] >= 0 && t[:end] > t[:begin] && t[:end] <= @str2.length
			new_d = d.dup.merge({span:t})
		rescue
			@lost_annotations << {source: d[:span], target:t}
			nil
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
				"===== common (block) ===== [#{a[:source][:begin]} - #{a[:source][:end]}] [#{a[:target][:begin]} - #{a[:target][:end]}]\n" +
				stext[a[:source][:begin] ... a[:source][:end]] + "\n\n"
			when :term
				"===== common (term) ===== [#{a[:source][:begin]} - #{a[:source][:end]}] [#{a[:target][:begin]} - #{a[:target][:end]}]\n" +
				stext[a[:source][:begin] ... a[:source][:end]] + "\n\n"
			when :empty
				"xxxxx disparate texts (similarity: #{a[:similarity]})\n" +
				"<<<<< string 1 [#{a[:source][:begin]} - #{a[:source][:end]}]\n" +
				stext[a[:source][:begin] ... a[:source][:end]] + "\n\n" +
				">>>>> string 2 [#{a[:target][:begin]} - #{a[:target][:end]}]\n" +
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

				"***** local mismatch [#{a[:source][:begin]} - #{a[:source][:end]}] [#{a[:target][:begin]} - #{a[:target][:end]}] (similarity: #{a[:similarity]})\n" +
				"[#{astr1}]\n" +
				"[#{astr2}]\n\n"
			end
		end
		show
	end

end
