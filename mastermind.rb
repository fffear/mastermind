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
    loop do
      puts "Do you want to guess or set the code? (g/s)"
      role = gets.chomp.downcase

      case role
      when "g"
        self.human_player.role = "guess_code"
        self.computer_player.role = "set_code"
      when "s"
        self.human_player.role = "set_code"
        self.computer_player.role = "guess_code"
      else
        puts "You didn't choose to guess or set code. Please pick an option."
      end

      break if ["g", "s"].any? { |letter| letter == role }
    end

    if self.human_player.role == "guess_code"
      self.computer_set_code
      guess_code_prompt
    else
      loop do
        puts "Please set the 4 color code:"
        self.human_player.code = gets.chomp
        colors_initial = self.computer_player.colors.map { |c| c[0] }

        if self.human_player.code.length == 4 && (self.human_player.code.split("") - colors_initial).length == 0
          break 
        else
          puts "You have entered a color that is not available."
        end
      end
      guess_code_prompt
    end
    
    self.computer_player.colors = %w{red orange yellow green indigo blue}
    self.computer_player.diff_rand_color = %w{r o y g i b}
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
      puts (attempt < 12) ? "You have #{13 - attempt} attempts left." : "You have #{13 - attempt} attempt left."

      if self.human_player.role == "set_code"
        @guess_code = self.computer_player.guess_code
      else
        @guess_code = gets.chomp
        self.human_player.code = @guess_code
      end

      compare_guess_to_code

      if attempt == 12 && self.human_player.role == "set_code"       
        puts "Computer wins!" if self.human_player.code == @guess_code
        puts "Computer loses!" if self.human_player.code != @guess_code
        puts "The code is: #{self.human_player.code}"
      elsif attempt == 12 && self.computer_player.role == "set_code"
        puts "Player wins!" if self.computer_player.code == @guess_code
        puts "Player loses!" if self.computer_player.code != @guess_code
        puts "The code is: #{self.computer_player.code}"
      elsif attempt < 12 && self.human_player.role == "set_code"
        puts "Computer wins!" if self.human_player.code == @guess_code
        puts "The code is: #{self.human_player.code}" if self.human_player.code == @guess_code
      elsif attempt < 12 && self.computer_player.role == "set_code"
        puts "Player wins!" if self.computer_player.code == @guess_code   
        puts "The code is: #{self.computer_player.code}" if self.computer_player.code == @guess_code
      end

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
      self.computer_player.correct_combination[i] = letter if letter == code[i]
      i += 1
    end

    for n in 0..3
      letter = guess_code[n]

      case
      when letter == code[n] 
        self.computer_player.correct_combination[n] = letter
        self.computer_player.incorrect_letter_placing.map! { |l| l == letter ? nil : l }
        print letter.green
      when letter != code[n]
        if code.count(letter) == 0
          self.computer_player.test_letter.reject! { |l| l == letter }
          self.computer_player.colors.reject! { |c| c[0] == letter }
          self.computer_player.diff_rand_color -= [letter]
          print letter.red
        elsif code.count(letter) == 1 && code.count(letter) == self.computer_player.correct_combination.count(letter)
          self.computer_player.colors.reject! { |c| c[0] == letter }
          self.computer_player.test_letter.reject! { |l| l == letter }
          self.computer_player.incorrect_letter_placing.map! { |l| l == letter ? nil : l }
          self.computer_player.diff_rand_color -= [letter]
          print letter.red
        elsif code.count(letter) == 1 && code.count(letter) != self.computer_player.correct_combination.count(letter)
          self.computer_player.incorrect_letter_placing[n] = letter
          self.computer_player.test_letter << letter
          print letter
        elsif code.count(letter) > 1 && code.count(letter) == self.computer_player.correct_combination.count(letter)
          self.computer_player.test_letter.reject! { |l| l == letter }
          self.computer_player.incorrect_letter_placing.map! { |l| l == letter ? nil : l }
          self.computer_player.colors.reject! { |c| c[0] == letter }
          self.computer_player.diff_rand_color -= [letter]
          print letter.red
        elsif code.count(letter) > 1 && code.count(letter) != self.computer_player.correct_combination.count(letter)
          self.computer_player.incorrect_letter_placing[n] = letter
          self.computer_player.test_letter << letter
          print letter
        end
      end
      puts "" if n == 3
    end

    if self.human_player.role == "guess_code" && @guess_code == code.join("")
      puts "#{self.human_player.name.capitalize} has guessed the winning code!"
    elsif self.human_player.role == "set_code" && @guess_code == code.join("")
      puts "#{self.computer_player.name.capitalize} has guessed the winning code!"
    else
      puts "The code you have guessed is incorrect."
    end
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
  attr_accessor :role, :colors
  def initialize(name)
    @name = name
    @colors = %w{red orange yellow green indigo blue}
  end

  def code=(create_code)
    @code = create_code
  end
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
    #puts @code
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

game = Game.new("human_player", "computer_player")
game.play
