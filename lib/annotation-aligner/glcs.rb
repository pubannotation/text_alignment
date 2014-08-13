#!/usr/bin/env ruby

# An instance of this class holds the results of generalized LCS computation for the two strings str1 and str2.
# an optional dictionary is used for generalized suffix comparision.
class GLCS

  # It initialized the GLCS table for the given two strings, str1 and str2.
  # The dictionary is optional. When it is given, general suffix comparision is performed based on the dictionary.
  # Exception is raised when nil given passed to either str1, str2 or dictionary
  def initialize(str1, str2, dictionary = [])
    raise "nil string" if str1 == nil or str2 == nil
    raise "nil dictionary" if dictionary == nil

    # extend the dictionary to include reversed entries.
    @dic = dictionary + dictionary.map{|e| [e[1], e[0]]}

    # add the initial marker to the strings
    @str1 = '_' + str1
    @str2 = '_' + str2

    # compute the GLCS table
    @glcs = get_glcs
  end

  # compute the GLCS table for the two strings, @str1 and @str2
  def get_glcs
    l1 = @str1.length
    l2 = @str2.length

    glcs = Array.new(l1) { Array.new(l2) }

    # initialize the first row and the first column
    (0...l1).each {|p| glcs[p][0] = 0}
    (0...l2).each {|p| glcs[0][p] = 0}

    # compute the GLCS table
    (1...l1).each do |p1|
      (1...l2).each do |p2|
        s1, s2 = suffix_eq(@str1[1..p1], @str2[1..p2])
        if s1 != nil
          glcs[p1][p2] = glcs[p1-s1.length][p2-s2.length] + 1
        else
          glcs[p1][p2] = (glcs[p1][p2-1] > glcs[p1-1][p2])? glcs[p1][p2-1] : glcs[p1-1][p2]
        end
      end
    end

    glcs
  end

  # general suffix comparision is performed based on the dictionary
  # the pair of matched suffixes are returned when found.
  # otherwise, the pair of nil values are returned.
  def suffix_eq(str1, str2)
    return nil, nil if str1.empty? || str2.empty?
    @dic.each {|s1, s2| return s1, s2 if str1.end_with?(s1) and str2.end_with?(s2)}
    return str1[-1], str2[-1] if (str1[-1] == str2[-1])
    return nil, nil
  end

  # print the GLCS table
  def show_glcs
    puts "\t" + @str2.split(//).join("\t")
    @glcs.each_with_index do |row, i|
      puts @str1[i] + "\t" + row.join("\t")
    end
  end

  # the length of GLCS
  def length
    @glcs[@str1.length - 1][@str2.length - 1]
  end

  # to show only the difference
  def diff
    diff = []

    p1 = @str1.length - 1
    p2 = @str2.length - 1

    begin
      s1, s2 = suffix_eq(@str1[1..p1], @str2[1..p2])
      if s1 != nil
        p1 -= s1.length; p2 -= s2.length
      elsif p2 > 0 && (p1 == 0 or @glcs[p1][p2-1] >= @glcs[p1-1][p2])
        diff.unshift({:action => '+', :old_position => nil, :old_character => nil, :new_position => p2-1, :new_character => @str2[p2]})
        p2 -= 1
      elsif p1 > 0 && (p2 == 0 or @glcs[p1][p2-1]  < @glcs[p1-1][p2])
        diff.unshift({:action => '-', :old_position => p1-1, :old_character => @str1[p1], :new_position => nil, :new_character => nil})
        p1 -= 1
      end
    end until p1 == 0 && p2 == 0

    diff
  end

  # to show the side-by-side difference
  def sdiff
    sdiff = []

    p1 = @str1.length - 1
    p2 = @str2.length - 1

    begin
      s1, s2 = suffix_eq(@str1[1..p1], @str2[1..p2])
      if s1 != nil
        l1 = s1.length
        l2 = s2.length
        sdiff.unshift({:action => '=',
                       :old_position => p1 - l1, :old_character => @str1[p1 - l1 + 1 .. p1],
                       :new_position => p2 - l2, :new_character => @str2[p2 - l2 + 1 .. p2]})
        p1 -= s1.length; p2 -= s2.length
      elsif p2 > 0 && (p1 == 0 or @glcs[p1][p2-1] > @glcs[p1-1][p2])
        sdiff.unshift({:action => '+', :old_position => nil, :old_character => nil, :new_position => p2-1, :new_character => @str2[p2]})
        p2 -= 1
      elsif p1 > 0 && (p2 == 0 or @glcs[p1][p2-1] <= @glcs[p1-1][p2])
        sdiff.unshift({:action => '-', :old_position => p1-1, :old_character => @str1[p1], :new_position => nil, :new_character => nil})
        p1 -= 1
      end
    end until p1 == 0 && p2 == 0

    sdiff
  end

  # compute the mapping of converting @str1 to @str2
  def mapping
    posmap = {}

    addition = []
    deletion = []

    p1 = @str1.length - 1
    p2 = @str2.length - 1

    begin
      s1, s2 = suffix_eq(@str1[1..p1], @str2[1..p2])
      if s1 != nil
        addition.sort!
        deletion.sort!

        if !addition.empty? && deletion.empty?
          if posmap.empty?
            posmap[p1] = p2
          else
            posmap[p1] = [posmap[p1], p2]
          end

        elsif addition.empty? && !deletion.empty?
          posmap[deletion[-1]] = p2 if posmap.empty?
          deletion.each{|p| posmap[p - 1] = p2}

        elsif !addition.empty? && !deletion.empty?
          posmap[deletion[-1]] = addition[-1] if posmap.empty?
          posmap[deletion[0] - 1] = addition[0] - 1
          deletion[1..-1].each{|p| posmap[p - 1] = nil}

        else
          posmap[p1] = p2
        end

        addition.clear
        deletion.clear

        posmap[p1 - s1.length] = p2 - s2.length
        (p1 - s1.length + 1 ... p1).each{|i| posmap[i] = nil}

        p1 -= s1.length; p2 -= s2.length
      elsif p2 > 0 && (p1 == 0 or @glcs[p1][p2-1] >= @glcs[p1-1][p2])
        addition << p2
        p2 -= 1
      elsif p1 > 0 && (p2 == 0 or @glcs[p1][p2-1]  < @glcs[p1-1][p2])
        deletion << p1
        p1 -= 1
      end
    end until p1 == 0 && p2 == 0

    if !addition.empty? && !deletion.empty?
      addition.sort!
      deletion.sort!

      posmap[deletion[0] - 1] = 0
      deletion[1..-1].each{|p| posmap[p - 1] = nil}
    else
      deletion.each{|p| posmap[p - 1] = 0}
    end

    posmap.sort.to_h
  end

  def common_elements
    glcs1 = []
    glcs2 = []

    p1 = @str1.length - 1
    p2 = @str2.length - 1

    begin
      s1, s2 = suffix_eq(@str1[1..p1], @str2[1..p2])
      if s1 != nil
        l1 = s1.length
        l2 = s2.length
        glcs1 << @str1[p1 - l1 + 1 .. p1]
        glcs2 << @str2[p2 - l2 + 1 .. p2]
        p1 -= l1; p2 -= l2
      elsif p2 > 0 && (p1 == 0 or @glcs[p1][p2-1] > @glcs[p1-1][p2])
        p2 -= 1
      elsif p1 > 0 && (p2 == 0 or @glcs[p1][p2-1] <= @glcs[p1-1][p2])
        p1 -= 1
      end
    end until p1 == 0 && p2 == 0

    [glcs1.reverse, glcs2.reverse]
  end

  def diff_string
    diff1 = ''
    diff2 = ''

    p1 = @str1.length - 1
    p2 = @str2.length - 1

    begin
      s1, s2 = suffix_eq(@str1[1..p1], @str2[1..p2])
      if s1 != nil
        l1 = s1.length
        l2 = s2.length
        p1 -= l1; p2 -= l2
      elsif p2 > 0 && (p1 == 0 or @glcs[p1][p2-1] > @glcs[p1-1][p2])
        diff2 += @str2[p2]
        p2 -= 1
      elsif p1 > 0 && (p2 == 0 or @glcs[p1][p2-1] <= @glcs[p1-1][p2])
        diff1 += @str1[p1]
        p1 -= 1
      end
    end until p1 == 0 && p2 == 0

    [diff1.reverse, diff2.reverse]
  end

  def similarity
    c = self.length

    diff_string = self.diff_string
    l1 = c + diff_string[0].length
    l2 = c + diff_string[1].length

    similarity = 2 * c / (l1 + l2).to_f
  end

end

if __FILE__ == $0

  dictionary = [
                ["α", "alpha"],   #U+03B1 (greek small letter alpha)
                ["β", "beta"],    #U+03B2 (greek small letter beta)
                ["γ", "gamma"],   #U+03B3 (greek small letter gamma)
                ["δ", "delta"],   #U+03B4 (greek small letter delta)
                ["ε", "epsilon"], #U+03B5 (greek small letter epsilon)
                ["κ", "kappa"],   #U+03BA (greek small letter kappa)
                ["λ", "lambda"],  #U+03BB (greek small letter lambda)
                ["χ", "chi"],     #U+03C7 (greek small letter chi)
                ["Δ", "delta"],   #U+0394 (greek capital letter delta)
                [" ", " "],       #U+2009 (thin space)
                [" ", " "],       #U+200A (hair space)
                [" ", " "],       #U+00A0 (no-break space)
                ["　", " "],       #U+3000 (ideographic space)
                ["−", "-"],       #U+2212 (minus sign)
                ["–", "-"],       #U+2013 (en dash)
                ["′", "'"],       #U+2032 (prime)
                ["‘", "'"],       #U+2018 (left single quotation mark)
                ["’", "'"],       #U+2019 (right single quotation mark)
                ["“", '"'],       #U+201C (left double quotation mark)
                ["”", '"']        #U+201D (right double quotation mark)
               ]

  # str1 = "-betakappa-"
  # str2 = "-βκ-"

  str1 = "abc-βκ-β–z"
  str2 = "-betakappa-xyz-beta-z"

  # anns1 = JSON.parse File.read(ARGV[0]), :symbolize_names => true
  # anns2 = JSON.parse File.read(ARGV[1]), :symbolize_names => true

  lcs = GLCS.new(str1, str2, dictionary)
  lcs.show_glcs
  puts '-----'
  diff = lcs.diff
  diff.each {|d| p d}
  puts '-----'
  sdiff = lcs.sdiff
  sdiff.each {|d| p d}
  puts '-----'
  mapping = lcs.mapping
  p mapping
  puts '-----'
  p lcs.common_elements
  puts '-----'
  p lcs.diff_string
  puts '-----'
  puts lcs.similarity
end
