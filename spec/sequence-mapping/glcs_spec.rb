require 'spec_helper'

describe GLCS do
  context 'for exception handling' do
    it 'should raise error for passing of nil strings' do
      expect {GLCS.new('abc', nil)}.to raise_error
      expect {GLCS.new(nil, 'abc')}.to raise_error
      expect {GLCS.new(nil, nil)}.to raise_error
    end

    it 'should raise error for passing of nil dictionary' do
      expect {GLCS.new('abc', 'abc', nil)}.to raise_error
    end
  end

  context 'should detect a deletion' do
    it 'in the beginning of string' do
                      #012345    012
      glcs = GLCS.new('xyzabc', 'abc')
      expect(glcs.mapping).to eq({0=>0, 1=>0, 2=>0, 3=>0, 4=>1, 5=>2, 6=>3})
    end

    it 'in the end of string' do
                      #012345    012
      glcs = GLCS.new('abcxyz', 'abc')
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>3, 5=>3, 6=>3})
    end

    it 'in the middle of string' do
                      #0123456    0123
      glcs = GLCS.new('abxyzcd', 'abcd')
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>2, 3=>2, 4=>2, 5=>2, 6=>3, 7=>4})
    end
  end

  context 'should detect an addition' do
    it 'in the beginning of string' do
                      #012    012345
      glcs = GLCS.new('abc', 'xyzabc')
      expect(glcs.mapping).to eq({0=>3, 1=>4, 2=>5, 3=>6})
    end

    it 'in the end of string' do
                      #012    012345
      glcs = GLCS.new('abc', 'abcxyz')
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>2, 3=>3})
    end

    it 'in the middle of string' do
                      #0123    0123456
      glcs = GLCS.new('abcd', 'abxyzcd')
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>[5, 2], 3=>6, 4=>7})
    end
  end

  context 'should detect a variation' do

    it 'in the beginning of string' do
                      #012345    01234
      glcs = GLCS.new('ijkabc', 'xyabc')
      expect(glcs.mapping).to eq({0=>0, 1=>nil, 2=>nil, 3=>2, 4=>3, 5=>4, 6=>5})
    end

    it 'in the end of string' do
                      #012345    01234
      glcs = GLCS.new('abcijk', 'abcxy')
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>2, 3=>3, 4=>nil, 5=>nil, 6=>5})
    end

    it 'in the middle of string' do
                      #0123456    012345
      glcs = GLCS.new('abijkcd', 'abxycd')
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>2, 3=>nil, 4=>nil, 5=>4, 6=>5, 7=>6})
    end

  end

  context ', with a dictionary with the first entry, ' do
    before(:all) do
      @dictionary = [["β", "beta"]]
    end
    it 'should handle consecutive unicode spellouts in the middle of a string' do
                      #0123    01234567890
      glcs = GLCS.new('-βκ-', '-betakappa-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>5, 3=>10, 4=>11})
    end

    it 'should handle consecutive unicode spellouts in the end of a string' do
                      #012    0123456789
      glcs = GLCS.new('-βκ', '-betakappa', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>5, 3=>10})
    end

    it 'should handle consecutive unicode spellouts in the beginning of a string' do
                      #012    0123456789
      glcs = GLCS.new('βκ-', 'betakappa-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>4, 2=>9, 3=>10})
    end

    it 'should handle consecutive unicode restorations in the middle of a string' do
                      #01234567890    0123
      glcs = GLCS.new('-betakappa-', '-βκ-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3, 11=>4})
    end

    it 'should handle consecutive unicode restorations in the beginning of a string' do
                      #0123456789    012
      glcs = GLCS.new('betakappa-', 'βκ-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>nil, 2=>nil, 3=>nil, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>nil, 9=>2, 10=>3})
    end

    it 'should handle consecutive unicode restorations in the end of a string' do
                      #0123456789    012
      glcs = GLCS.new('-betakappa', '-βκ', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3})
    end
  end

  context ', with a dictionary with the second entry, ' do
    before(:all) do
      @dictionary = [["κ", "kappa"]]
    end
    it 'should handle consecutive unicode spellouts in the middle of a string' do
                      #0123    01234567890
      glcs = GLCS.new('-βκ-', '-betakappa-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>5, 3=>10, 4=>11})
    end

    it 'should handle consecutive unicode spellouts in the end of a string' do
                      #012    0123456789
      glcs = GLCS.new('-βκ', '-betakappa', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>5, 3=>10})
    end

    it 'should handle consecutive unicode spellouts in the beginning of a string' do
                      #012    0123456789
      glcs = GLCS.new('βκ-', 'betakappa-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>4, 2=>9, 3=>10})
    end

    it 'should handle consecutive unicode restorations in the middle of a string' do
                      #01234567890    0123
      glcs = GLCS.new('-betakappa-', '-βκ-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3, 11=>4})
    end

    it 'should handle consecutive unicode restorations in the beginning of a string' do
                      #0123456789    012
      glcs = GLCS.new('betakappa-', 'βκ-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>nil, 2=>nil, 3=>nil, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>nil, 9=>2, 10=>3})
    end

    it 'should handle consecutive unicode restorations in the end of a string' do
                      #0123456789    012
      glcs = GLCS.new('-betakappa', '-βκ', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3})
    end
  end

  context ', with a dictionary with both entries, ' do
    before(:all) do
      @dictionary = [["β", "beta"], ["κ", "kappa"]]
    end
    it 'should handle consecutive unicode spellouts in the middle of a string' do
                      #0123    01234567890
      glcs = GLCS.new('-βκ-', '-betakappa-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>5, 3=>10, 4=>11})
    end

    it 'should handle consecutive unicode spellouts in the end of a string' do
                      #012    0123456789
      glcs = GLCS.new('-βκ', '-betakappa', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>5, 3=>10})
    end

    it 'should handle consecutive unicode spellouts in the beginning of a string' do
                      #012    0123456789
      glcs = GLCS.new('βκ-', 'betakappa-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>4, 2=>9, 3=>10})
    end

    it 'should handle consecutive unicode restorations in the middle of a string' do
                      #01234567890    0123
      glcs = GLCS.new('-betakappa-', '-βκ-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3, 11=>4})
    end

    it 'should handle consecutive unicode restorations in the beginning of a string' do
                      #0123456789    012
      glcs = GLCS.new('betakappa-', 'βκ-', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>nil, 2=>nil, 3=>nil, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>nil, 9=>2, 10=>3})
    end

    it 'should handle consecutive unicode restorations in the end of a string' do
                      #0123456789    012
      glcs = GLCS.new('-betakappa', '-βκ', @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>nil, 7=>nil, 8=>nil, 9=>nil, 10=>3})
    end
  end

  context ', with a dictionary, ' do
    before(:all) do
      @dictionary = [["β", "beta"], ["κ", "kappa"]]
    end

    it 'should handle a unicode spellout followed by addition' do
                      #012    012345678
      glcs = GLCS.new("-β-", "-beta***-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>[8, 5], 3=>9})
    end

    it 'should handle a unicode retoration followed by addition' do
                      #012345    012345
      glcs = GLCS.new("-beta-", "-β***-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>[5, 2], 6=>6})
    end

    it 'should handle a unicode spellout followed by deletion' do
                      #012345    012345
      glcs = GLCS.new("-β***-", "-beta-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>5, 3=>5, 4=>5, 5=>5, 6=>6})
    end

    it 'should handle a unicode retoration followed by deletion' do
                      #012345678    0123
      glcs = GLCS.new("-beta***-", "-β-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>nil, 3=>nil, 4=>nil, 5=>2, 6=>2, 7=>2, 8=>2, 9=>3})
    end

    it 'should handle a unicode spellout following addition' do
                      #012    012345678
      glcs = GLCS.new("-β-", "-***beta-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>[4, 1], 2=>8, 3=>9})
    end

    it 'should handle a unicode retoration following addition' do
                      #012345    012345
      glcs = GLCS.new("-beta-", "-***β-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>[4, 1], 2=>nil, 3=>nil, 4=>nil, 5=>5, 6=>6})
    end

    it 'should handle a unicode spellout following deletion' do
                      #012345    012345
      glcs = GLCS.new("-***β-", "-beta-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>1, 3=>1, 4=>1, 5=>5, 6=>6})
    end

    it 'should handle a unicode retoration following deletion' do
                      #012345678    012
      glcs = GLCS.new("-***beta-", "-β-", @dictionary)
      expect(glcs.mapping).to eq({0=>0, 1=>1, 2=>1, 3=>1, 4=>1, 5=>nil, 6=>nil, 7=>nil, 8=>2, 9=>3})
    end

  end

  # from_text = "-beta***-"
  # to_text = "-##β-"

  # from_text = "TGF-beta-induced"
  # to_text = "TGF-β–induced"
end
