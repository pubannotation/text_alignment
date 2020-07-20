require 'spec_helper'
require 'json'

describe TextAlignment::TextAlignment do

	context "for oryza-10022841" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-10022841.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/10022841.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/10022841-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-10036778" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-10036778.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/10036778.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/10036778-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-10050312" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-10050312.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/10050312.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/10050312-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-10205906" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-10205906.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/10205906.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/10205906-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-10527423" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-10527423.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/10527423.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/10527423-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-10557360" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-10557360.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/10557360.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/10557360-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-11148291" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-11148291.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/11148291.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/11148291-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-12028574" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-12028574.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/12028574.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/12028574-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-22973062" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-22973062.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/22973062.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/22973062-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for oryza-28666113" do
		before do
			@source = JSON.parse File.read("spec/fixtures/oryza-28666113.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/28666113.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/28666113-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	context "for PMC-1310901-GE" do
		before do
			@source = JSON.parse File.read("spec/fixtures/PMC-1310901-GE.json"), symbolize_names: true
			@target = File.read("spec/fixtures/PMC-1310901.txt")
			@answer = JSON.parse File.read("spec/fixtures/PMC-1310901-align.json"), symbolize_names: true
		end

		it "should work" do
			result = align_mdoc(@source, {text:@target})
			expect(result[:denotations]).to eq(@answer[:denotations])
		end
	end

	context "for 00a0ab182dc01b6c2e737dfae585f050dcf9a7a5" do
		before do
			@source = JSON.parse File.read("spec/fixtures/00a0ab182dc01b6c2e737dfae585f050dcf9a7a5.json"), symbolize_names: true
			@target = JSON.parse File.read("spec/fixtures/00a0ab182dc01b6c2e737dfae585f050dcf9a7a5-PA.json"), symbolize_names: true
			@answer = JSON.parse File.read("spec/fixtures/00a0ab182dc01b6c2e737dfae585f050dcf9a7a5-align.json"), symbolize_names: true
		end

		it "should work" do
			alignment = TextAlignment::TextAlignment.new(@source[:text], @target[:text])
			denotations = alignment.transform_hdenotations(@source[:denotations])
			lost_annotations = alignment.lost_annotations
			expect(denotations).to eq(@answer[:denotations])
		end
	end

	def align_mdoc(source_annotations, target_annotations)
		idnum_denotations = 0
		idnum_relations = 0
		idnum_attributes = 0
		idnum_modifications = 0

		source_annotations.each do |annotations|
			alignment = TextAlignment::TextAlignment.new(annotations[:text], target_annotations[:text])

			if annotations.has_key?(:denotations) && !annotations[:denotations].empty?
				ididx = {}
				denotations = alignment.transform_hdenotations(annotations[:denotations])
				denotations.each do |d|
					reid = 'T' + (idnum_denotations += 1).to_s
					ididx[d[:id]] = reid
					d[:id] = reid
				end
				target_annotations[:denotations] = [] unless target_annotations.has_key? :denotations
				target_annotations[:denotations] += denotations

				if annotations.has_key?(:relations) && !annotations[:relations].empty?
					target_annotations[:relations] = [] unless target_annotations.has_key? :relations
					annotations[:relations].each do |r|
						reid = 'R' + (idnum_relations += 1).to_s
						ididx[r[:id]] = reid
						target_annotations[:relations] << r.dup.merge({id:reid, subj:ididx[r[:subj]], obj:ididx[r[:obj]]})
					end
				end

				if annotations.has_key?(:attributes) && !annotations[:attributes].empty?
					target_annotations[:attributes] = [] unless target_annotations.has_key? :attributes
					annotations[:attributes].each do |a|
						reid = 'A' + (idnum_attributes += 1).to_s
						ididx[a[:id]] = reid
						target_annotations[:attributes] << a.dup.merge({id:reid, subj:ididx[a[:subj]]})
					end
				end

				if annotations.has_key?(:modifications) && !annotations[:modifications].empty?
					target_annotations[:modifications] = [] unless target_annotations.has_key? :modifications
					annotations[:modifications].each do |m|
						reid = 'M' + (idnum_modifications += 1).to_s
						ididx[m[:id]] = reid
						target_annotations[:modifications] << m.dup.merge({id:reid, obj:ididx[m[:obj]]})
					end
				end
			end
		end
		target_annotations
	end

end