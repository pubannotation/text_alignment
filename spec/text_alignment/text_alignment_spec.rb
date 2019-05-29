require 'spec_helper'

describe TextAlignment::TextAlignment do
  context 'for exception handling' do
    it 'should raise error for passing of nil strings' do
      expect {TextAlignment::TextAlignment.new('abc', nil)}.to raise_error
      expect {TextAlignment::TextAlignment.new(nil, 'abc')}.to raise_error
      expect {TextAlignment::TextAlignment.new(nil, nil)}.to raise_error
    end

    it 'should raise error for passing of nil dictionary' do
      expect {TextAlignment::TextAlignment.new('abc', 'abc', nil)}.to raise_error
    end
  end

  context 'in the beginning of a string' do
    it 'should detect a deletion' do
                      #012345    012
      sa = TextAlignment::TextAlignment.new('xyzabc', 'abc')
      expect(sa.position_map_begin).to eq({0=>0, 1=>0, 2=>0, 3=>0, 4=>1, 5=>2, 6=>3})
      expect(sa.position_map_end).to eq({0=>0, 1=>0, 2=>0, 3=>0, 4=>1, 5=>2, 6=>3})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect an addition' do
                      #012    012345
      sa = TextAlignment::TextAlignment.new('abc', 'xyzabc')
      expect(sa.position_map_begin).to eq({0=>3, 1=>4, 2=>5, 3=>6})
      expect(sa.position_map_end).to eq({0=>3, 1=>4, 2=>5, 3=>6})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect a variation' do
                      #012345    01234
      sa = TextAlignment::TextAlignment.new('ijkabc', 'xyabc')
      expect(sa.position_map_begin).to eq({0=>0, 1=>nil, 2=>nil, 3=>2, 4=>3, 5=>4, 6=>5})
      expect(sa.position_map_end).to eq({0=>0, 1=>nil, 2=>nil, 3=>2, 4=>3, 5=>4, 6=>5})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([['ijk', 'xy']])
    end
  end

  context 'in the end of a string' do
    it 'should detect a deletion' do
                      #012345    012
      sa = TextAlignment::TextAlignment.new('abcxyz', 'abc')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>3, 5=>3, 6=>3})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>3, 5=>3, 6=>3})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect an addition' do
                      #012    012345
      sa = TextAlignment::TextAlignment.new('abc', 'abcxyz')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>6})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>3})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect a variation' do
                      #012345    01234
      sa = TextAlignment::TextAlignment.new('abcijk', 'abcxy')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>nil, 5=>nil, 6=>5})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>nil, 5=>nil, 6=>5})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c']])
      expect(sa.mapped_elements).to eq([['ijk', 'xy']])
    end
  end

  context 'in the middle of a string' do
    it 'should detect a deletion' do
                      #0123456    0123
      sa = TextAlignment::TextAlignment.new('abxyzcd', 'abcd')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>2, 4=>2, 5=>2, 6=>3, 7=>4})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>2, 4=>2, 5=>2, 6=>3, 7=>4})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c'], ['d', 'd']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect an addition' do
                      #0123    0123456
      sa = TextAlignment::TextAlignment.new('abcd', 'abxyzcd')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>6, 4=>7})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>6, 4=>7})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c'], ['d', 'd']])
      expect(sa.mapped_elements).to eq([])
    end

    it 'should detect a variation' do
                      #0123456    012345
      sa = TextAlignment::TextAlignment.new('abijkcd', 'abxycd')
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>2, 3=>nil, 4=>nil, 5=>4, 6=>5, 7=>6})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>2, 3=>nil, 4=>nil, 5=>4, 6=>5, 7=>6})
      expect(sa.common_elements).to eq([['a', 'a'], ['b', 'b'], ['c', 'c'], ['d', 'd']])
      expect(sa.mapped_elements).to eq([['ijk', 'xy']])
    end
  end

  context ', with a dictionary with the first entry, ' do
    before(:all) do
      @dictionary = [["β", "beta"]]
    end
    it 'should handle consecutive unicode spellouts in the middle of a string' do
                      #0123    01234567890
      sa = TextAlignment::TextAlignment.new('-βκ-', '-betakappa-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>10, 4=>11})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>5, 3=>10, 4=>11})
      expect(sa.common_elements).to match_array([['-', '-'], ['β', 'beta'], ['-', '-']])
      expect(sa.mapped_elements).to eq([['κ', 'kappa']])
    end

    it 'should handle consecutive unicode spellouts in the end of a string' do
                      #012    0123456789
      sa = TextAlignment::TextAlignment.new('-βκ', '-betakappa', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>10})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>5, 3=>10})
      expect(sa.common_elements).to match_array([['-', '-'], ['β', 'beta']])
      expect(sa.mapped_elements).to eq([['κ', 'kappa']])
    end

    it 'should handle consecutive unicode spellouts in the beginning of a string' do
                      #012    0123456789
      sa = TextAlignment::TextAlignment.new('βκ-', 'betakappa-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>4, 2=>9, 3=>10})
      expect(sa.position_map_end).to eq({0=>0, 1=>4, 2=>9, 3=>10})
      expect(sa.common_elements).to match_array([['β', 'beta'], ['-', '-']])
      expect(sa.mapped_elements).to eq([['κ', 'kappa']])
    end

    it 'should handle consecutive unicode restorations in the middle of a string' do
                      #01234567890    0123
      sa = TextAlignment::TextAlignment.new('-betakappa-', '-βκ-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3, 11=>4})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3, 11=>4})
    end

    it 'should handle consecutive unicode restorations in the beginning of a string' do
                      #0123456789    012
      sa = TextAlignment::TextAlignment.new('betakappa-', 'βκ-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>nil, 2=>nil, 3=>nil, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>nil, 9=>2, 10=>3})
      expect(sa.position_map_end).to eq({0=>0, 1=>nil, 2=>nil, 3=>nil, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>nil, 9=>2, 10=>3})
    end

    it 'should handle consecutive unicode restorations in the end of a string' do
                      #0123456789    012
      sa = TextAlignment::TextAlignment.new('-betakappa', '-βκ', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3})
    end
  end

  context ', with a dictionary with the second entry, ' do
    before(:all) do
      @dictionary = [["κ", "kappa"]]
    end
    it 'should handle consecutive unicode spellouts in the middle of a string' do
                      #0123    01234567890
      sa = TextAlignment::TextAlignment.new('-βκ-', '-betakappa-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>10, 4=>11})
    end

    it 'should handle consecutive unicode spellouts in the end of a string' do
                      #012    0123456789
      sa = TextAlignment::TextAlignment.new('-βκ', '-betakappa', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>10})
    end

    it 'should handle consecutive unicode spellouts in the beginning of a string' do
                      #012    0123456789
      sa = TextAlignment::TextAlignment.new('βκ-', 'betakappa-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>4, 2=>9, 3=>10})
    end

    it 'should handle consecutive unicode restorations in the middle of a string' do
                      #01234567890    0123
      sa = TextAlignment::TextAlignment.new('-betakappa-', '-βκ-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3, 11=>4})
    end

    it 'should handle consecutive unicode restorations in the beginning of a string' do
                      #0123456789    012
      sa = TextAlignment::TextAlignment.new('betakappa-', 'βκ-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>nil, 2=>nil, 3=>nil, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>nil, 9=>2, 10=>3})
    end

    it 'should handle consecutive unicode restorations in the end of a string' do
                      #0123456789    012
      sa = TextAlignment::TextAlignment.new('-betakappa', '-βκ', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3})
    end
  end

  context ', with a dictionary with both entries, ' do
    before(:all) do
      @dictionary = [["β", "beta"], ["κ", "kappa"]]
    end
    it 'should handle consecutive unicode spellouts in the middle of a string' do
                      #0123    01234567890
      sa = TextAlignment::TextAlignment.new('-βκ-', '-betakappa-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>10, 4=>11})
    end

    it 'should handle consecutive unicode spellouts in the end of a string' do
                      #012    0123456789
      sa = TextAlignment::TextAlignment.new('-βκ', '-betakappa', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>10})
    end

    it 'should handle consecutive unicode spellouts in the beginning of a string' do
                      #012    0123456789
      sa = TextAlignment::TextAlignment.new('βκ-', 'betakappa-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>4, 2=>9, 3=>10})
    end

    it 'should handle consecutive unicode restorations in the middle of a string' do
                      #01234567890    0123
      sa = TextAlignment::TextAlignment.new('-betakappa-', '-βκ-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3, 11=>4})
    end

    it 'should handle consecutive unicode restorations in the beginning of a string' do
                      #0123456789    012
      sa = TextAlignment::TextAlignment.new('betakappa-', 'βκ-', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>nil, 2=>nil, 3=>nil, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>nil, 9=>2, 10=>3})
    end

    it 'should handle consecutive unicode restorations in the end of a string' do
                      #0123456789    012
      sa = TextAlignment::TextAlignment.new('-betakappa', '-βκ', @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3})
    end
  end

  context ', with a dictionary, ' do
    before(:all) do
      @dictionary = [["β", "beta"], ["κ", "kappa"]]
    end

    it 'should handle a unicode spellout followed by addition' do
                      #012    012345678
      sa = TextAlignment::TextAlignment.new("-β-", "-beta***-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>8, 3=>9})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>5, 3=>9})
    end

    it 'should handle a unicode retoration followed by addition' do
                      #012345    012345
      sa = TextAlignment::TextAlignment.new("-beta-", "-β***-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>5, 6=>6})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>6})
    end

    it 'should handle a unicode spellout followed by deletion' do
                      #012345    012345
      sa = TextAlignment::TextAlignment.new("-β***-", "-beta-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>5, 3=>5, 4=>5, 5=>5, 6=>6})
    end

    it 'should handle a unicode retoration followed by deletion' do
                      #012345678    0123
      sa = TextAlignment::TextAlignment.new("-beta***-", "-β-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>2, 7=>2, 8=>2, 9=>3})
    end

    it 'should handle a unicode spellout following addition' do
                      #012    012345678
      sa = TextAlignment::TextAlignment.new("-β-", "-***beta-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>4, 2=>8, 3=>9})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>8, 3=>9})
    end

    it 'should handle a unicode retoration following addition' do
                      #012345    012345
      sa = TextAlignment::TextAlignment.new("-beta-", "-***β-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>4, 2=>nil, 3=>nil, 4=>nil, 5=>5, 6=>6})
      expect(sa.position_map_end).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>5, 6=>6})
    end

    it 'should handle a unicode spellout following deletion' do
                      #012345    012345
      sa = TextAlignment::TextAlignment.new("-***β-", "-beta-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>1, 3=>1, 4=>1, 5=>5, 6=>6})
    end

    it 'should handle a unicode retoration following deletion' do
                      #012345678    012
      sa = TextAlignment::TextAlignment.new("-***beta-", "-β-", @dictionary)
      expect(sa.position_map_begin).to eq({0=>0, 1=>1, 2=>1, 3=>1, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>2, 9=>3})
    end

  end

  from_text = "-beta***-"
  to_text = "-##β-"

  from_text = "TGF-beta-induced"
  to_text = "TGF-β–induced"
end
