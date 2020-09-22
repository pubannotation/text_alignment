#!/usr/bin/env ruby
require 'text_alignment/anchor_finder'
require 'text_alignment/mixed_alignment'

module TextAlignment; end unless defined? TextAlignment

TextAlignment::SIGNATURE_NGRAM = 7 unless defined? TextAlignment::SIGNATURE_NGRAM
TextAlignment::BUFFER_RATE = 0.1 unless defined? TextAlignment::BUFFER_RATE
TextAlignment::BUFFER_MIN = 10 unless defined? TextAlignment::BUFFER_MIN


class TextAlignment::TextAlignment
	attr_reader :block_alignments
	attr_reader :similarity
	attr_reader :lost_annotations

	def initialize(str1, str2, mappings = nil)
		raise ArgumentError, "nil string" if str1.nil? || str2.nil?

		mappings ||= TextAlignment::MAPPINGS

		# try exact match
		block_begin = str2.index(str1)
		unless block_begin.nil?
			@block_alignments = [{source:{begin:0, end:str1.length}, target:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin}]
			return @block_alignments
		end

		anchor_finder = TextAlignment::AnchorFinder.new(str1, str2)

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
		@block_alignments = []
		return if mblocks.empty?

		# Initial step
		if mblocks[0][:source][:begin] > 0
			e1 = mblocks[0][:source][:begin]
			e2 = mblocks[0][:target][:begin]

			if mblocks[0][:target][:begin] == 0
				@block_alignments << {source:{begin:0, end:e1}, target:{begin:0, end:0}, alignment: :empty}
			else
				_str1 = str1[0 ... e1]
				_str2 = str2[0 ... e2]

				unless _str1.strip.empty?
					if _str2.strip.empty?
						@block_alignments << {source:{begin:0, end:e1}, target:{begin:0, end:e2}, alignment: :empty}
					else
						len_min = [_str1.length, _str2.length].min
						len_buffer = (len_min * (1 + TextAlignment::BUFFER_RATE)).to_i + TextAlignment::BUFFER_MIN
						b1 = _str1.length < len_buffer ? 0 : e1 - len_buffer
						b2 = _str2.length < len_buffer ? 0 : e2 - len_buffer

						@block_alignments << {source:{begin:0, end:b1}, target:{begin:0, end:b2}, alignment: :empty} if b1 > 0

						_str1 = str1[b1 ... e1]
						_str2 = str2[b2 ... e2]
						alignment = TextAlignment::MixedAlignment.new(_str1.downcase, _str2.downcase, mappings)
						if alignment.similarity < 0.6
							@block_alignments << {source:{begin:b1, end:e1}, target:{begin:0, end:e2}, alignment: :empty}
						else
							@block_alignments << {source:{begin:b1, end:e1}, target:{begin:0, end:e2}, alignment:alignment}
						end
					end
				end
			end
		end
		@block_alignments << mblocks[0]

		(1 ... mblocks.length).each do |i|
			b1 = mblocks[i - 1][:source][:end]
			b2 = mblocks[i - 1][:target][:end]
			e1 = mblocks[i][:source][:begin]
			e2 = mblocks[i][:target][:begin]
			_str1 = str1[b1 ... e1]
			_str2 = str2[b2 ... e2]
			unless _str1.strip.empty?
				if _str2.strip.empty?
					@block_alignments << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty}
				else
					alignment = TextAlignment::MixedAlignment.new(_str1.downcase, _str2.downcase, mappings)
					if alignment.similarity < 0.6
						@block_alignments << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty}
					else
						@block_alignments << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment:alignment}
					end
				end
			end
			@block_alignments << mblocks[i]
		end

		# Final step
		if  mblocks[-1][:source][:end] < str1.length && mblocks[-1][:target][:end] < str2.length
			b1 = mblocks[-1][:source][:end]
			b2 = mblocks[-1][:target][:end]
			_str1 = str1[b1 ... str1.length]
			_str2 = str2[b2 ... str2.length]

			unless _str1.strip.empty?
				if _str2.strip.empty?
					@block_alignments << {source:{begin:b1, end:str1.length}, target:{begin:b2, end:str2.length}, alignment: :empty}
				else
					len_min = [_str1.length, _str2.length].min
					len_buffer = (len_min * (1 + TextAlignment::BUFFER_RATE)).to_i + TextAlignment::BUFFER_MIN
					e1 = _str1.length < len_buffer ? str1.length : b1 + len_buffer
					e2 = _str2.length < len_buffer ? str2.length : b2 + len_buffer
					_str1 = str1[b1 ... e1]
					_str2 = str2[b2 ... e2]

					alignment = TextAlignment::MixedAlignment.new(_str1.downcase, _str2.downcase, mappings)
					if alignment.similarity < 0.6
						@block_alignments << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment: :empty}
					else
						@block_alignments << {source:{begin:b1, end:e1}, target:{begin:b2, end:e2}, alignment:alignment}
					end

					@block_alignments << {source:{begin:e1, end:-1}, target:{begin:e2, end:-1}, alignment: :empty} if e1 < str1.length
				end
			end
		end

		@block_alignments.each do |a|
			a[:delta] = a[:target][:begin] - a[:source][:begin]
		end
	end

	def transform_begin_position(begin_position)
		i = @block_alignments.index{|b| b[:source][:end] > begin_position}
		block_alignment = @block_alignments[i]

		b = if block_alignment[:alignment].nil?
			begin_position + block_alignment[:delta]
		elsif block_alignment[:alignment] == :empty
			if begin_position == block_alignment[:source][:begin]
				block_alignment[:target][:begin]
			else
				# raise "lost annotation"
				nil
			end
		else
			r = block_alignment[:alignment].transform_begin_position(begin_position - block_alignment[:source][:begin])
			r.nil? ? nil : r + block_alignment[:target][:begin]
		end
	end

	def transform_end_position(end_position)
		i = @block_alignments.index{|b| b[:source][:end] >= end_position}
		block_alignment = @block_alignments[i]

		e = if block_alignment[:alignment].nil?
			end_position + block_alignment[:delta]
		elsif block_alignment[:alignment] == :empty
			if end_position == block_alignment[:source][:end]
				block_alignment[:target][:end]
			else
				# raise "lost annotation"
				nil
			end
		else
			r = block_alignment[:alignment].transform_end_position(end_position - block_alignment[:source][:begin])
			r.nil? ? nil : r + block_alignment[:target][:begin]
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

end
