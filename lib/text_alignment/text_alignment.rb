#!/usr/bin/env ruby
require 'text_alignment/constants'
require 'text_alignment/anchor_finder'
require 'text_alignment/mixed_alignment'
require 'text_alignment/cultivation_map'

module TextAlignment; end unless defined? TextAlignment

class TextAlignment::TextAlignment
	attr_reader :block_alignment
	attr_reader :similarity
	attr_reader :lost_annotations

	# Initialize with a reference text, against which texts will be aligned
	def initialize(reference_text, options = {})
		raise ArgumentError, "nil text" if reference_text.nil?

		options ||= {}
		@to_prevent_overlap = options[:to_prevent_overlap] || false
		@squeeze_ws_to = options[:squeeze_ws_to] || 0

		@original_reference_text = reference_text
		@rtext_mapping = TextAlignment::CharMapping.new(reference_text, nil, @squeeze_ws_to)
		@mapped_reference_text = @rtext_mapping.mapped_text

		@original_text = nil
		@blocks = nil
		@cultivation_map = TextAlignment::CultivationMap.new
	end

	def align(text, denotations = nil)
		# To maintain the cultivation map
		update_cultivation_map if @to_prevent_overlap

		# In case the input text is the same as the previous one, reuse the previous text mapping
		unless @original_text && @original_text == text
			@original_text = text
			@text_mapping = TextAlignment::CharMapping.new(text, nil, @squeeze_ws_to)
		end

		@mapped_text = @text_mapping.mapped_text
		denotations_mapped = @text_mapping.enmap_denotations(denotations)

		## To generate the block_alignment of the input text against the reference text
		@blocks = if r = whole_block_alignment(@mapped_text, @mapped_reference_text, @cultivation_map)
			r
		else
			find_block_alignment(@mapped_text, @mapped_reference_text, denotations_mapped, @cultivation_map)
		end

		@block_alignment = {text: @original_text, reference_text: @original_reference_text, denotations: denotations, blocks: demap_blocks(@blocks)}
	end

	def transform_begin_position(_begin_position)
		begin_position = @text_mapping.enmap_position(_begin_position)

		i = @blocks.index{|b| b[:source][:end] > begin_position}
		block = @blocks[i]

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

		@rtext_mapping.demap_position(b)
	end

	def transform_end_position(_end_position)
		end_position = @text_mapping.enmap_position(_end_position)

		i = @blocks.index{|b| b[:source][:end] >= end_position}
		block = @blocks[i]

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

		@rtext_mapping.demap_position(e)
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
			raise "invalid transform" unless !d.begin.nil? && !d.end.nil? && d.begin >= 0 && d.end > d.begin && d.end <= @original_reference_text.length
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
			raise "invalid transform" unless !t[:begin].nil? && !t[:end].nil? && t[:begin] >= 0 && t[:end] > t[:begin] && t[:end] <= @original_reference_text.length
			new_d = d.dup.merge({span:t})
		rescue
			@lost_annotations << {source: d[:span], target:t}
			nil
		end.compact

		r
	end

	def alignment_show
		stext = @block_alignment[:text]
		ttext = @block_alignment[:reference_text]

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
				">>>>> string 2 " +
				if a[:target]
					"[#{a[:target][:begin]} - #{a[:target][:end]}]\n" +
					ttext[a[:target][:begin] ... a[:target][:end]] + "\n\n"
				else
					"[-]\n\n"
				end
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
				"[#{astr2.gsub("\n", " ")}]\n\n"
			end
		end
		show
	end

	private

	def find_block_alignment(str1, str2, denotations, cultivation_map)
		## to find block alignments
		anchor_finder = TextAlignment::AnchorFinder.new(str1, str2, cultivation_map, @squeeze_ws_to == 1)

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

		## To fill the gaps
		## lblock: last block, cblock: current block
		lblock = nil
		blocks2 = (blocks + [nil]).inject([]) do |sum, cblock|
			b1 = lblock.nil? ? 0 : lblock[:source][:end]
			e1 = cblock.nil? ? str1.length : cblock[:source][:begin]

			if b1 < e1
				b2 = lblock.nil? ? 0 : lblock[:target][:end]
				e2 = cblock.nil? ? str2.length : cblock[:target][:begin]
				_str1 = str1[b1 ... e1]
				_str2 = str2[b2 ... e2]

				sum += if _str1.strip.empty? || _str2.strip.empty?
					[{source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty}]
				else
					len_buffer = ((e1 - b1) * (1 + TextAlignment::BUFFER_RATE)).to_i + TextAlignment::BUFFER_MIN
					region_state, state_region = cultivation_map.region_state([b2, e2])
					case region_state
					when :closed
						[{source:{begin:b1, end:e1}, alignment: :empty}]
					when :front_open
						if sum.empty? # when there is no preceding matched block
							[{source:{begin:b1, end:e1}, alignment: :empty}]
						else
							oe2 = state_region[1]
							me2 = (oe2 - b2) > len_buffer ? b2 + len_buffer : oe2
							local_alignment(str1, b1, e1, str2, b2, me2, denotations, cultivation_map)
						end
					when :rear_open
						if cblock.nil? # when there is no following matched block
							[{source:{begin:b1, end:e1}, alignment: :empty}]
						else
							ob2 = state_region[0]
							mb2 = (e2 - ob2) > len_buffer ? e2 - len_buffer : ob2
							local_alignment(str1, b1, e1, str2, mb2, e2, denotations, cultivation_map)
						end
					when :middle_closed
						attempt1 = if sum.empty?
							[{source:{begin:b1, end:e1}, alignment: :empty}]
						else
							oe2 = state_region[0]
							me2 = (oe2 - b2) > len_buffer ? b2 + len_buffer : oe2
							local_alignment(str1, b1, e1, str2, b2, me2, denotations, cultivation_map)
						end
						if (attempt1.empty? || attempt1.first[:alignment] == :empty) && !cblock.nil?
							ob2 = state_region[1]
							mb2 = (e2 - ob2) > len_buffer ? e2 - len_buffer : ob2
							local_alignment(str1, b1, e1, str2, mb2, e2, denotations, cultivation_map)
						else
							attempt1
						end
					else # :open
						if (e2 - b2) > len_buffer
							attempt1 = if sum.empty?
								[{source:{begin:b1, end:e1}, alignment: :empty}]
							else
								local_alignment(str1, b1, e1, str2, b2, b2 + len_buffer, denotations, cultivation_map)
							end
							if (attempt1.empty? || attempt1.first[:alignment] == :empty) && !cblock.nil?
								local_alignment(str1, b1, e1, str2, e2 - len_buffer, e2, denotations, cultivation_map)
							else
								attempt1
							end
						else
							local_alignment(str1, b1, e1, str2, b2, e2, denotations, cultivation_map)
						end
					end
				end
			end

			lblock = cblock
			cblock.nil? ? sum : sum << cblock
		end

	end

	def whole_block_alignment(str1, str2, cultivation_map)
		block_begin = cultivation_map.index(str1, str2)
		return [{source:{begin:0, end:str1.length}, target:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin, alignment: :block}] unless block_begin.nil?

		block_begin = cultivation_map.index(str1.downcase, str2.downcase)
		return [{source:{begin:0, end:str1.length}, target:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin, alignment: :block}] unless block_begin.nil?

		nil
	end

	def local_alignment(str1, b1, e1, str2, b2, e2, denotations = nil, cultivation_map)
		tblocks = term_based_alignment(str1, b1, e1, str2, b2, e2, denotations, cultivation_map)
		if tblocks.empty? || tblocks.first[:alignment] == :empty
			lcs_alignment(str1, b1, e1, str2, b2, e2, cultivation_map)
		else
			tblocks
		end
	end

	def term_based_alignment(str1, b1, e1, str2, b2, e2, denotations = nil, cultivation_map)
		str2_block = str2[0 ... e2]

		## term-based alignment
		tblocks = if denotations
			denotations_in_scope = denotations.select{|d| d[:span][:begin] >= b1 && d[:span][:end] <= e1}.
							sort{|d1, d2| d1[:span][:begin] <=> d2[:span][:begin] || d2[:span][:end] <=> d1[:span][:end] }.
							map{|d| d.merge(lex:str1[d[:span][:begin] ... d[:span][:end]])}

			search_position = b2
			_tblocks = denotations_in_scope.map do |denotation|
				lex = denotation[:lex]
				term_begin = cultivation_map.index(lex, str2_block, search_position)
				break [] if term_begin.nil? # break the loop if a missing term is found
				search_position = term_begin + lex.length
				{source:denotation[:span], target:{begin:term_begin, end:term_begin + lex.length}, alignment: :term, similarity: 0.9, delta: term_begin - denotation[:span][:begin]}
			end

			# redundant matching found
			unless _tblocks.empty?
				search_position = _tblocks.last[:target][:end]
				denotations_in_scope.each do |term|
					look_forward = cultivation_map.index(term[:lex], str2_block, search_position)
					unless look_forward.nil?
						_tblocks = []
						break
					end
				end
			end

			_tblocks
		else
			[]
		end

		ltblock = nil
		tblocks2 = (tblocks + [nil]).inject([]) do |sum, ctblock|
			tb1 = ltblock.nil? ? b1 : ltblock[:source][:end]
			te1 = ctblock.nil? ? e1 : ctblock[:source][:begin]

			if te1 > tb1
				tb2 = ltblock.nil? ? b2 : ltblock[:target][:end]
				te2 = ctblock.nil? ? e2 : ctblock[:target][:begin]
				sum << {source:{begin:tb1, end:te1}, target:{begin:tb2, end:te2}, alignment: :empty}
			end

			ltblock = ctblock
			ctblock.nil? ? sum : sum << ctblock
		end

		tblocks2
	end

	def lcs_alignment(str1, b1, e1, str2, b2, e2, cultivation_map)
		source = {begin:b1, end:e1}
		target = {begin:b2, end:e2}

		if (e1 - b1) > 2000
			[{source:source, target:target, alignment: :empty}]
		else
			alignment = TextAlignment::MixedAlignment.new(str1[b1 ... e1].downcase, str2[b2 ... e2].downcase)
			if alignment.similarity < 0.5
				[{source:source, target:target, alignment: :empty}]
			else
				[{source:source, target:target, alignment: alignment, similarity: alignment.similarity}]
			end
		end
	end

	def update_cultivation_map
		return if @blocks.nil?

		## To update the cultivation map
		newly_cultivated_regions = @blocks.collect do |b|
			if b[:alignment] == :block || b[:alignment] == :term
				[b[:target][:begin], b[:target][:end]]
			else
				nil
			end
		end.compact.inject([]) do |condensed, region|
			if condensed.empty? || (condensed.last.last + 1 < region.first)
				condensed.push region
			else
				condensed.last[1] = region.last
			end
			condensed
		end

		@cultivation_map.cultivate(newly_cultivated_regions)
	end

	def demap_blocks(_blocks)
		return nil if _blocks.nil?

		blocks = _blocks.map{|b| b.dup}
		blocks.each do |b|
			b[:source] = {begin:@text_mapping.demap_position(b[:source][:begin]), end:@text_mapping.demap_position(b[:source][:end])} if b[:source]
			b[:target] = {begin:@rtext_mapping.demap_position(b[:target][:begin]), end:@rtext_mapping.demap_position(b[:target][:end])} if b[:target]
		end

		blocks
	end

end
