#!/usr/bin/env ruby
require 'text_alignment/mixed_alignment'

module TextAlignment; end unless defined? TextAlignment

TextAlignment::SIGNATURE_NGRAM = 7 unless defined? TextAlignment::SIGNATURE_NGRAM

class TextAlignment::TextAlignment
	attr_reader :block_alignment
	attr_reader :similarity

	def initialize(str1, str2)
		raise ArgumentError, "nil string" if str1.nil? || str2.nil?

		# try exact match
		block_begin = str2.index(str1)
		unless block_begin.nil?
			@block_alignment = [{target:{begin:0, end:str1.length}, source:{begin:block_begin, end:block_begin + str1.length}, delta:block_begin}]
			return @block_alignment
		end

		# divide and align
		ngram1 = (0 .. str1.length - TextAlignment::SIGNATURE_NGRAM).collect{|i| str1[i, TextAlignment::SIGNATURE_NGRAM]}
		ngram2 = (0 .. str2.length - TextAlignment::SIGNATURE_NGRAM).collect{|i| str2[i, TextAlignment::SIGNATURE_NGRAM]}

		str1_ngrams_index = {}
		(0 .. str1.length - TextAlignment::SIGNATURE_NGRAM).each do |i|
			ngram = str1[i, TextAlignment::SIGNATURE_NGRAM]
			if str1_ngrams_index.has_key?(ngram)
				str1_ngrams_index[ngram] = nil
			else
				str1_ngrams_index[ngram] = i
			end
		end
		str1_ngrams_index.compact!

		str2_ngrams_index = {}
		(0 .. str2.length - TextAlignment::SIGNATURE_NGRAM).each do |i|
			ngram = str2[i, TextAlignment::SIGNATURE_NGRAM]
			if str2_ngrams_index.has_key?(ngram)
				str2_ngrams_index[ngram] = nil
			else
				str2_ngrams_index[ngram] = i
			end
		end
		str2_ngrams_index.compact!

		shared_ngrams = str1_ngrams_index.keys & str2_ngrams_index.keys

		if shared_ngrams.empty?
			@block_alignment = []
			return @block_alignment
		end

		mblocks = []
		len_shared_ngrams = shared_ngrams.length
		i = 0
		while i < len_shared_ngrams
			b1 = str1_ngrams_index[shared_ngrams[i]]
			b2 = str2_ngrams_index[shared_ngrams[i]]
			e1 = b1 + TextAlignment::SIGNATURE_NGRAM
			e2 = b2 + TextAlignment::SIGNATURE_NGRAM
			mblock = {target:{begin:b1, end:e1}, source:{begin:b2, end:e2}}

			j = i + 1
			while j < len_shared_ngrams
				e1 = str1_ngrams_index[shared_ngrams[j]] + TextAlignment::SIGNATURE_NGRAM
				e2 = str2_ngrams_index[shared_ngrams[j]] + TextAlignment::SIGNATURE_NGRAM
				if str1[b1 ... e1] == str2[b2 ... e2]
					mblock = {target:{begin:b1, end:e1}, source:{begin:b2, end:e2}}
				else
					break
				end
				j += 1
			end

			mblocks << mblock

			i = j
			i += 1 while (i < len_shared_ngrams) && (str1_ngrams_index[shared_ngrams[i]] < mblock[:target][:end])
		end

		# extend the blocks
		mblocks.each do |mblock|
			b1 = mblock[:target][:begin]
			b2 = mblock[:source][:begin]
			while b1 > -1 && b2 > -1 && str1[b1] == str2[b2]
				b1 -= 1
				b2 -= 1
			end
			b1 += 1
			b2 += 1

			e1 = mblock[:target][:end]
			e2 = mblock[:source][:end]
			while str1[e1] == str2[e2]
				e1 += 1
				e2 += 1
			end

			mblock[:target] = {begin:b1, end:e1}
			mblock[:source] = {begin:b2, end:e2}
		end

		@block_alignment = []

		unless mblocks[0][:target][:begin] == 0 || mblocks[0][:source][:begin] == 0
			e1 = mblocks[0][:target][:begin]
			e2 = mblocks[0][:source][:begin]
			_str1 = str1[0 ... e1]
			_str2 = str2[0 ... e2]
			unless _str1.strip.empty?
				if _str2.strip.empty?
					@block_alignment << {target:{begin:0, end:e1}, source:{begin:0, end:e2}, alignment: :empty}
				else
					@block_alignment << {target:{begin:0, end:e1}, source:{begin:0, end:e2}, alignment:TextAlignment::MixedAlignment.new(_str1, _str2, TextAlignment::MAPPINGS)}
				end
			end
		end
		@block_alignment << mblocks[0]

		(1 ... mblocks.length).each do |i|
			b1 = mblocks[i - 1][:target][:end] + 1
			b2 = mblocks[i - 1][:source][:end] + 1
			e1 = mblocks[i][:target][:begin]
			e2 = mblocks[i][:source][:begin]
			_str1 = str1[b1 ... e1]
			_str2 = str2[b2 ... e2]
			unless _str1.strip.empty?
				if _str2.strip.empty?
					@block_alignment << {target:{begin:b1, end:e1}, source:{begin:b2, end:e2}, alignment: :empty}
				else
					@block_alignment << {target:{begin:b1, end:e1}, source:{begin:b2, end:e2}, alignment:TextAlignment::MixedAlignment.new(_str1, _str2, TextAlignment::MAPPINGS)}
				end
			end
			@block_alignment << mblocks[i]
		end

		unless mblocks[-1][:target][:end] == str1.length || mblocks[-1][:source][:end] == str2.length
			b1 = mblocks[-1][:target][:end]
			b2 = mblocks[-1][:source][:end]
			_str1 = str1[b1 ... -1]
			_str2 = str2[b2 ... -1]
			unless _str1.strip.empty?
				if _str2.strip.empty?
					@block_alignment << {target:{begin:b1, end:str1.length}, source:{begin:b2, end:str2.length}, alignment: :empty}
				else
					@block_alignment << {target:{begin:b1, end:str1.length}, source:{begin:b2, end:str2.length}, alignment:TextAlignment::MixedAlignment.new(_str1, _str2, TextAlignment::MAPPINGS)}
				end
			end
		end

		@block_alignment.each do |a|
			a[:delta] = a[:source][:begin] - a[:target][:begin]
		end

	end

	def transform_begin_position(begin_position)
		i = @block_alignment.index{|b| b[:target][:end] > begin_position}
		b = if @block_alignment[i][:alignment].nil?
			begin_position + @block_alignment[i][:delta]
		elsif @block_alignment[i][:alignment] == :empty
			raise "lost annotation"
		else
			@block_alignment[i][:alignment].transform_begin_position(begin_position) + @block_alignment[i][:delta]
		end
	end

	def transform_end_position(end_position)
		i = @block_alignment.index{|b| b[:target][:end] > end_position}
		e = if @block_alignment[i][:alignment].nil?
			end_position + @block_alignment[i][:delta]
		elsif @block_alignment[i][:alignment] == :empty
			raise "lost annotation"
		else
			@block_alignment[i][:alignment].transform_end_position(end_position) + @block_alignment[i][:delta]
		end
	end

	def transform_a_span(span)
		{begin: transform_begin_position(span[:begin]), end: transform_end_position(span[:end])}
	end

	def transform_spans(spans)
		spans.map{|span| transform_a_span(span)}
	end

	def transform_denotations!(denotations)
		return nil unless denotations.nil?
		denotations.map!{|d| d.begin = transform_begin_position(d.begin); d.end = transform_end_position(d.end); d}
	end

	def transform_hdenotations(hdenotations)
		return nil if hdenotations.nil?
		hdenotations.collect{|d| d.dup.merge({span:transform_a_span(d[:span])})}
	end

end
