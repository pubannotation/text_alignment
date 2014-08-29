require 'spec_helper'

describe TextAlignment::LCSAlignment do
  context 'for exception handling' do
    it 'should raise error for passing of nil strings' do
      expect {TextAlignment::LCSAlignment.new('abc', nil)}.to raise_error
      expect {TextAlignment::LCSAlignment.new(nil, 'abc')}.to raise_error
      expect {TextAlignment::LCSAlignment.new(nil, nil)}.to raise_error
    end
  end

  context 'in the middle of a string' do
    it 'should detect a deletion' do
                      #0123456    0123
      sa = TextAlignment::LCSAlignment.new('abxyzcd', 'abcd')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>2, 4=>2, 5=>2, 6=>3, 7=>4})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>2, 4=>2, 5=>2, 6=>3, 7=>4})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c'], ['d', 'd']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect an addition' do
                      #0123    0123456
      sa = TextAlignment::LCSAlignment.new('abcd', 'abxyzcd')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>6, 4=>7})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>6, 4=>7})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c'], ['d', 'd']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect a variation' do
                      #0123456    012345
      sa = TextAlignment::LCSAlignment.new('abijkcd', 'abxycd')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>nil, 4=>nil, 5=>4, 6=>5, 7=>6})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>nil, 4=>nil, 5=>4, 6=>5, 7=>6})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c'], ['d', 'd']])
      expect(sa.mapped_elements).to eq([['ijk', 'xy']])
    end
  end

  context 'in the beginning of a string' do
    it 'should detect a deletion' do
                      #012345    012
      sa = TextAlignment::LCSAlignment.new('xyzabc', 'abc')
      expect(sa.position_map_begin).to eq({0=>0, 1=>0, 2=>0, 3=>0, 4=>1, 5=>2, 6=>3})
      expect(sa.position_map_end).to eq({0=>0, 1=>0, 2=>0, 3=>0, 4=>1, 5=>2, 6=>3})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect an addition' do
                      #012    012345
      sa = TextAlignment::LCSAlignment.new('abc', 'xyzabc')
      expect(sa.position_map_begin).to eq({0=>3, 1=>4, 2=>5, 3=>6})
      expect(sa.position_map_end).to eq({0=>3, 1=>4, 2=>5, 3=>6})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect a variation' do
                      #012345    01234
      sa = TextAlignment::LCSAlignment.new('ijkabc', 'xyabc')
      expect(sa.position_map_begin).to eq({0=>0, 1=>nil, 2=>nil, 3=>2, 4=>3, 5=>4, 6=>5})
      expect(sa.position_map_end).to eq({0=>0, 1=>nil, 2=>nil, 3=>2, 4=>3, 5=>4, 6=>5})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([['ijk', 'xy']])
    end
  end

  context 'in the end of a string' do
    it 'should detect a deletion' do
                      #012345    012
      sa = TextAlignment::LCSAlignment.new('abcxyz', 'abc')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>3, 5=>3, 6=>3})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>3, 5=>3, 6=>3})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect an addition' do
                      #012    012345
      sa = TextAlignment::LCSAlignment.new('abc', 'abcxyz')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>6})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>3})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect a variation' do
                      #012345    01234
      sa = TextAlignment::LCSAlignment.new('abcijk', 'abcxy')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>nil, 5=>nil, 6=>5})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>nil, 5=>nil, 6=>5})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([['ijk', 'xy']])
    end
  end
end
