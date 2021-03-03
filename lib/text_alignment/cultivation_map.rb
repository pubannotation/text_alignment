module TextAlignment; end unless defined? TextAlignment

class TextAlignment::CultivationMap
	attr_reader :map

	def initialize
		@map = {}
	end

	def cultivate(regions)
		regions.each do |b, e|
			(b ... e).each{|p| @map[p] = e}
		end
	end

	def search_again_position(position)
		@map[position]
	end
end
