module TextAlignment; end unless defined? TextAlignment

TextAlignment::CHAR_MAPPING = [
	["©", "(c)"],			#U+00A9 (Copyright Sign)

	["α", "alpha"],		#U+03B1 (greek small letter alpha)
	["β", "beta"],		#U+03B2 (greek small letter beta)
	["γ", "gamma"],		#U+03B3 (greek small letter gamma)
	["δ", "delta"],		#U+03B4 (greek small letter delta)
	["ε", "epsilon"],	#U+03B5 (greek small letter epsilon)
	["ζ", "zeta"],		#U+03B6 (greek small letter zeta)
	["η", "eta"],			#U+03B7 (greek small letter eta)
	["θ", "theta"],		#U+03B7 (greek small letter eta)
	["ι", "iota"],		#U+03B7 (greek small letter eta)
	["κ", "kappa"],		#U+03BA (greek small letter kappa)
	["λ", "lambda"],	#U+03BB (greek small letter lambda)
	["λ", "lamda"],		#U+03BB (greek small letter lambda)
	["μ", "mu"],			#U+03BC (greek small letter mu)
	["ν", "nu"],			#U+03BD (greek small letter nu)
	["ξ", "xi"],			#U+03BE (greek small letter xi)
	["ο", "omicron"],	#U+03BF (greek small letter omicron)
	["π", "pi"],			#U+03C0 (greek small letter pi)
	["ρ", "rho"],			#U+03C1 (greek small letter rho)
	["σ", "sigma"],		#U+03C3 (greek small letter sigma)
	["τ", "tau"],			#U+03C4 (greek small letter tau)
	["υ", "upsilon"],	#U+03C5 (greek small letter upsilon)
	["φ", "phi"],			#U+03C6 (greek small letter phi)
	["χ", "chi"],			#U+03C7 (greek small letter chi)
	["ψ", "psi"],			#U+03C8 (greek small letter psi)
	["ω", "omega"],		#U+03C9 (greek small letter omega)

	["Α", "Alpha"],		#U+0391 (greek capital letter alpha)
	["Β", "Beta"],		#U+0392 (greek capital letter beta)
	["Γ", "Gamma"],		#U+0393 (greek capital letter gamma)
	["Δ", "Delta"],		#U+0394 (greek capital letter delta)
	["Ε", "Epsilon"],	#U+0395 (greek capital letter epsilon)
	["Ζ", "Zeta"],		#U+0396 (greek capital letter zeta)
	["Η", "Eta"],			#U+0397 (greek capital letter eta)
	["Θ", "Theta"],		#U+0398 (greek capital letter theta)
	["Ι", "Iota"],		#U+0399 (greek capital letter iota)
	["Κ", "Kappa"],		#U+039A (greek capital letter kappa)
	["Λ", "Lambda"],	#U+039B (greek capital letter lambda)
	["Λ", "Lamda"],		#U+039B (greek capital letter lambda)
	["Μ", "Mu"],			#U+039C (greek capital letter mu)
	["Ν", "Nu"],			#U+039D (greek capital letter nu)
	["Ξ", "Xi"],			#U+039E (greek capital letter xi)
	["Ο", "Omicron"],	#U+039F (greek capital letter omicron)
	["Π", "Pi"],			#U+03A0 (greek capital letter pi)
	["Ρ", "Rho"],			#U+03A1 (greek capital letter rho)
	["Σ", "Sigma"],		#U+03A3 (greek capital letter sigma)
	["Τ", "Tau"],			#U+03A4 (greek capital letter tau)
	["Υ", "Upsilon"],	#U+03A5 (greek capital letter upsilon)
	["Φ", "Phi"],			#U+03A6 (greek capital letter phi)
	["Χ", "Chi"],			#U+03A7 (greek capital letter chi)
	["Ψ", "Psi"],			#U+03A8 (greek capital letter Psi)
	["Ω", "Omega"],		#U+03A9 (greek capital letter omega)

	["ϕ", "phi"],			#U+03D5 (greek phi symbol)

	["×", "x"],				#U+00D7 (multiplication sign)
	["•", "*"],				#U+2022 (bullet)
	[" ", " "],				#U+2009 (thin space)
	[" ", " "],				#U+200A (hair space)
	[" ", " "],				#U+00A0 (no-break space)
	["　", " "],				#U+3000 (ideographic space)
	["‑", "-"],				#U+2211 (Non-Breaking Hyphen)
	["−", "-"],				#U+2212 (minus sign)
	["–", "-"],				#U+2013 (en dash)
	["′", "'"],				#U+2032 (prime)
	["‘", "'"],				#U+2018 (left single quotation mark)
	["’", "'"],				#U+2019 (right single quotation mark)
	["“", '"'],				#U+201C (left double quotation mark)
	["”", '"'],				#U+201D (right double quotation mark)
	['"', "''"]
]


class TextAlignment::CharMapping
	attr_reader :str

	def initialize(_str, char_mapping = nil)
		char_mapping ||= TextAlignment::CHAR_MAPPING
		@str, offset_mapping = enmap_str(_str, char_mapping)
		@index_enmap = offset_mapping.to_h
		@index_demap = offset_mapping.map{|m| m.reverse}.to_h
	end

	def enmap_position(position)
		@index_enmap[position]
	end

	def demap_position(position)
		@index_demap[position]
	end

	def enmap_denotations(_denotations)
		denotations = _denotations.map do |d|
			d.dup.merge(span:{begin:enmap_position(d[:span][:begin]), end:enmap_position(d[:span][:end])})
		end
	end

	private

	def enmap_str(_str, char_mapping)
		str = _str.dup

		# To get the (location, length) index for replacements
		loc_len = []
		char_mapping.each do |one, long|
			next if long.length == 1

			init_next = 0
			while loc = str.index(long, init_next)
				loc_len << [loc, long.length]
				init_next = loc + 1
			end

			# a workaround to avoid messing-up due to embedding
			str.gsub!(long, one * long.length)
		end
		loc_len.sort!{|a, b| a[0] <=> b[0]}

		# To get the offset_mapping before and after replacement
		offset_mapping = []
		init_next = 0
		j = 0

		loc_len.each do |loc, len|
			offset_mapping += (init_next .. loc).map do |i|
				j += 1
				[i, j - 1]
			end
			init_next = loc + len
		end

		offset_mapping += (init_next .. str.length).map do |i|
			j += 1
			[i, j - 1]
		end

		# To get the string with the characters replaced
		char_mapping.each do |one, long|
			str.gsub!(one * long.length, one)
		end

		[str, offset_mapping]
	end
end

if __FILE__ == $0
	require 'json'

	unless ARGV.length == 1
		warn "#{$0} an_annotation_json_file.json" 
		exit
	end
	annotations = JSON.parse File.read(ARGV[0]).strip, symbolize_names: true
	denotations = annotations[:denotations]
	if denotations.nil? && annotations[:tracks]
		denotations = annotations[:tracks].first[:denotations]
	end

	str_mapping = TextAlignment::CharMapping.new(annotations[:text])
	str_mapped = str_mapping.str
	denotations_mapped = str_mapping.enmap_denotations(denotations)
	new_annotations = {text:str_mapped, denotations:denotations_mapped}

	puts new_annotations.to_json
end
