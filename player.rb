class Player
  attr_reader :name
  attr_accessor :role, :colors, :code, :guess_code
  def initialize(name)
    @name = name
    @colors = %w{red orange yellow green indigo blue}
  end

  #def code=(create_code)
  #  @code = create_code
  #end
end

class HumanPlayer < Player; end

class ComputerPlayer < Player
  attr_accessor :correct_combination, :incorrect_letter_placing, :test_letter, :diff_rand_color
  def initialize(name)
    super
    @correct_combination = []
    @incorrect_letter_placing = []
    @test_letter = []
    @diff_rand_color = %w{r o y g i b}
  end

  def set_code
    @code = ""
    (1..4).each do
      random_number = rand(0..5)
      @code += @colors[random_number][0]
    end
    puts "The computer has generated the 4 color code."
  end

  def guess_code
    comp_guess_code = ""
    (0..3).each do |n|
      if self.correct_combination[n] != nil
        comp_guess_code += self.correct_combination[n]
      elsif self.incorrect_letter_placing[n] != self.test_letter[0] && self.test_letter.empty? == false
        comp_guess_code += self.test_letter[0]
      elsif self.incorrect_letter_placing[n] == self.test_letter[0] && self.test_letter.empty? == false
        self.diff_rand_color -= [self.test_letter[0]]
        comp_guess_code += self.diff_rand_color.sample[0]
      else
        comp_guess_code += self.colors[rand(self.colors.length)][0]
      end
    end

    puts "The computer has guessed a code combination."
    
    puts comp_guess_code
    comp_guess_code
  end
end