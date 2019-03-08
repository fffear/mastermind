class String
  def red
    "\e[31m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end
end

class Game
  attr_reader :colors, :color_strings, :human_player, :computer_player
  def initialize(human_player, computer_player)
    @colors = %w{red orange yellow green indigo blue}
    @human_player = HumanPlayer.new(human_player)
    @computer_player = ComputerPlayer.new(computer_player)
    @players = {}
    @players[:human_player] = {name: human_player, role: @human_player.role}
    @players[:computer_player] = {name: computer_player, role: @computer_player.role}
  end

  def introduction
    puts "Welcome to Fffear's Mastermind Game!"
    puts ""
    puts "Player's will have 12 chances to guess the correct sequence of colors."
    puts "To guess the sequence of colors, enter the first letter of the color consecutively without any spaces."
    print "The available colors are: "
    covert_colors_to_strings_with_first_letter_brackets
    print_color_with_first_letter_brackets
  end

  def computer_set_code
    self.computer_player.set_code
  end

  def play
    self.introduction
    puts "Do you want to guess or set the code? (g/s)"
    role = gets.chomp.downcase
    if role == "g"
      self.human_player.role = "guess_code"
      self.computer_player.role = "set_code"
    else
      self.human_player.role = "set_code"
      self.computer_player.role = "guess_code"
    end

    if self.human_player.role == "guess_code"
      self.computer_set_code
      guess_code_prompt
    else
      puts "Please set the 4 color code:"
      self.human_player.code = gets.chomp
      guess_code_prompt
    end
    
    self.computer_player.incorrect_letter_placing.clear
    self.computer_player.test_letter.clear
    self.computer_player.correct_combination.clear
    self.prompt_restart_game
  end

  def guess_code_prompt
    (1..12).each do |attempt|
      print "Please guess the 4 color code by entering the 1st letter of the color you are guessing."
      print " (eg. 'rgyb' to guess 'red, green, yellow, blue')\n"
      print "The available colors are: "
      print_color_with_first_letter_brackets
      puts "You have #{12 - attempt} attempts."

      if self.human_player.role == "set_code"
        @guess_code = self.computer_player.guess_code
      else
        @guess_code = gets.chomp
      end

      compare_guess_to_code

      case
      when self.human_player.role == "guess_code" then break if @guess_code == self.computer_player.code
      when self.human_player.role == "set_code" then break if @guess_code == self.human_player.code
      end
    end
  end

  def compare_guess_to_code
    guess_code = @guess_code.split("")
    code = (self.human_player.role == "guess_code") ? self.computer_player.code.split("") : self.human_player.code.split("")
    
    i = 0
    guess_code.each do |letter|
      case
      when letter == code[i]
        self.computer_player.correct_combination[i] = letter
        self.computer_player.test_letter.reject! { |l| l == letter } #if self.computer_player.test_letter[0] == letter
        self.computer_player.incorrect_letter_placing.map! { |l| l == letter ? nil : l }
        print letter.green
      when letter != code[i] && code.any? { |l| l == letter }
        if self.computer_player.correct_combination.any? { |l| l == letter } && code.count(letter) == self.computer_player.correct_combination.count(letter)
          print letter.red
          self.computer_player.test_letter.shift if self.computer_player.test_letter[0] == letter
          #self.computer_player.test_letter.reject! { |l| l == letter }
          # put code here
        else
          self.computer_player.incorrect_letter_placing[i] = letter
          self.computer_player.test_letter.push(letter)
          print letter
        end
      else 
        print letter.red
      end
      i += 1
      puts "" if i == 4
    end

    if @guess_code == code.join("")
      puts "You have guessed the winning code!"
      return
    end

    p self.computer_player.correct_combination
    p self.computer_player.incorrect_letter_placing
    p self.computer_player.test_letter
  end

  def prompt_restart_game
    loop do
      puts "Do you want to play again? (y/n)"
      answer = gets.chomp.downcase
  
      case answer
      when "n" then exit
      when "y" then break
      else puts "You didn't select yes or no."
      end
    end
    self.play
  end

  #color_code_feedback = Proc.new do |letter|
  #  print (letter == code[i]) ? letter.green :
  #        (letter != code[i] && code.any? { |l| l == letter }) ? letter : letter.red
  #  i += 1
  #  puts "" if i == 4
  #end

  def colors_first_letter
    @colors_first_letter = @colors.map { |color| color[0] }
  end

  def covert_colors_to_strings_with_first_letter_brackets
    @color_strings = @colors.each_with_object([]) { |color, array| array << color.to_s.gsub(/^\w/, "(#{color[0]})") }
  end

  def print_color_with_first_letter_brackets
    color_strings.each do |color|
      print (color == color_strings[-1]) ? "and #{color}.\n" :
            (color == color_strings[-2]) ? "#{color} " : "#{color}, "
    end
  end

  def human_player
    @human_player
  end

  def computer_player
    @computer_player
  end

  def players
    @players
  end
end

class Player
  attr_reader :name, :code
  attr_accessor :role
  def initialize(name)
    @name = name
    #@role = role
    @colors = %w{red orange yellow green indigo blue}
  end

  def code=(create_code)
    @code = create_code
  end
end

class HumanPlayer < Player; end

class ComputerPlayer < Player
  attr_accessor :correct_combination, :incorrect_letter_placing, :test_letter
  def initialize(name)
    super
    @correct_combination = []
    @incorrect_letter_placing = []
    @test_letter = []
  end

  def set_code
    @code = ""
    (1..4).each do
      random_number = rand(0..5)
      @code += @colors[random_number][0]
    end
    puts "The computer has generated the 4 color code."
    puts @code
  end

  def guess_code
    comp_guess_code = ""
    (0..3).each do |n|
      if self.correct_combination[n] != nil
        comp_guess_code += self.correct_combination[n]
      elsif self.incorrect_letter_placing[n] != self.test_letter[0] && self.incorrect_letter_placing.length > 0

        if self.test_letter.length > 0 && self.test_letter.any? { |l| l != nil }
          comp_guess_code += self.test_letter[0]
        else
          random_number = rand(0..5)
          comp_guess_code += @colors[random_number][0]
        end
      else
        random_number = rand(0..5)
        comp_guess_code += @colors[random_number][0]
      end
    end
    puts "The computer has guessed a code combination."
    #if
    #end
    puts comp_guess_code
    comp_guess_code
  end
end


# The game will provide 12 turns
# The color combination will be a series of 4 colors
#The total amount of colors available to choose from will be 6


game = Game.new("human_player", "computer_player")

p game.human_player
p game.computer_player
p game.players

game.play