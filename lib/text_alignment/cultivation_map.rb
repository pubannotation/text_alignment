module TextAlignment; end unless defined? TextAlignment

class TextAlignment::CultivationMap
	attr_reader :map

	def initialize
		@map = []
	end

	def cultivate(regions)
		@map += regions
		@map.sort!{|a, b| a[0] <=> b[0]}
		new_map = []
		@map.each do |region|
			if new_map.empty?
				new_map << region
			elsif new_map.last[1] > region[0]
				raise "Overlapping regions: #{new_map.last} : #{region}"
			elsif new_map.last[1] == region[0]
				new_map.last[1] == region[1]
			else
				new_map << region
			end
		end
		@map = new_map
	end

	def search_again_position(position, end_position = nil)
		end_position ||= position
		region = @map.bsearch{|r| end_position < r[1]}
		if region.nil? || region[0] > position
			nil
		else
			region[1]
		end
	end

	def last_cultivated_position(position)
		ridx = @map.rindex{|r| r[1] <= position}
		ridx.nil? ? nil : @map[ridx][1]
	end

	def next_cultivated_position(position)
		region = @map.bsearch{|r| position < r[0]}
		region.nil? ? nil : region[0]
	end

	def in_regions(region)
		@map.select{|r| (r[1] > region[0] && r[1] <= region[1]) || (r[0] < region[1] && r[0] >= region[0])}
	end

	def region_state(region)
		closed_parts = in_regions(region)
		if closed_parts.empty?
			[:open, region]
		else
			if front_open?(region, closed_parts)
				if rear_open?(region, closed_parts)
					[:middle_closed, [closed_parts.first[1], closed_parts.last[0]]]
				else
					[:front_open, [region[0], closed_parts.first[0]]]
				end
			else
				if rear_open?(region, closed_parts)
					[:rear_open, [closed_parts.last[1], region[1]]]
				else
					[:closed, nil]
				end
			end
		end
	end

	def index(target, string, position)
		length = target.length
		loop do
			_begin = string.index(target, position)
			break if _begin.nil?
			position = search_again_position(_begin)
			next unless position.nil?
			break _begin if region_state([_begin, _begin + length])[0] == :open
			position = _begin + 1
		end
	end

	private

	def front_open?(region, closed_parts)
		closed_parts.first[0] > region[0]
	end

	def rear_open?(region, closed_parts)
		closed_parts.last[1] < region[1]
	end
end
