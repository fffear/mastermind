require "./player.rb"

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
    choose_to_create_or_guess_code

    if self.human_player.role == "guess_code"
      computer_set_code
      guess_code_prompt
    else
      human_player_create_code
      guess_code_prompt
    end
    
    reset_game_conditions
    self.prompt_restart_game
  end

  def choose_to_create_or_guess_code
    loop do
      puts "Do you want to guess or set the code? (g/s)"
      role = gets.chomp.downcase

      player_chose_guess_code if role == "g"
      player_chose_create_code if role == "s"
      puts "You didn't choose to guess or set code. Please pick an option." if ["g", "s"].none? { |letter| letter == role }

      break if ["g", "s"].any? { |letter| letter == role }
    end
  end

  def player_chose_guess_code
    self.human_player.role = "guess_code"
    self.computer_player.role = "set_code"
  end

  def player_chose_create_code
    self.human_player.role = "set_code"
    self.computer_player.role = "guess_code"
  end

  def human_player_create_code
    loop do
      puts "Please set the 4 color code:"
      self.human_player.code = gets.chomp

      case
      when (self.human_player.code.length == 4 && illegal_colors.length == 0) then break
      else puts "You have entered a color that is not available, or the code is either too short or too long."
      end
    end 
  end

  def reset_game_conditions
    self.computer_player.colors = %w{red orange yellow green indigo blue}
    self.computer_player.diff_rand_color = %w{r o y g i b}
    self.computer_player.incorrect_letter_placing.clear
    self.computer_player.test_letter.clear
    self.computer_player.correct_combination.clear
  end

  def guess_code_prompt
    (1..12).each do |attempt|
      guess_code_introduction
      puts (attempt < 12) ? "You have #{13 - attempt} attempts left." : "You have #{13 - attempt} attempt left."

      (self.human_player.role == "set_code") ? @guess_code = self.computer_player.guess_code : @guess_code = gets.chomp
      compare_guess_to_code

      case
      when attempt == 12 && self.human_player.role == "set_code" then computer_player_victory_or_defeat_message
      when attempt == 12 && self.computer_player.role == "set_code" then human_player_victory_or_defeat_message
      when attempt < 12 && self.human_player.role == "set_code" then computer_player_victory_message
      when attempt < 12 && self.computer_player.role == "set_code" then human_player_victory_message
      end

      case
      when self.human_player.role == "guess_code" then break if @guess_code == self.computer_player.code
      when self.human_player.role == "set_code" then break if @guess_code == self.human_player.code
      end
    end
  end

  def guess_code_introduction
    print "Please guess the 4 color code by entering the 1st letter of the color you are guessing."
    print " (eg. 'rgyb' to guess 'red, green, yellow, blue')\n"
    print "The available colors are: "
    print_color_with_first_letter_brackets
  end

  def computer_player_victory_or_defeat_message
    puts "Computer wins!" if self.human_player.code == @guess_code
    puts "Computer loses!" if self.human_player.code != @guess_code
    puts "The code is: #{self.human_player.code}"
  end

  def human_player_victory_or_defeat_message
    puts "Player wins!" if self.computer_player.code == @guess_code
    puts "Player loses!" if self.computer_player.code != @guess_code
    puts "The code is: #{self.computer_player.code}"
  end

  def computer_player_victory_message
    puts "Computer wins!" if self.human_player.code == @guess_code
    puts "The code is: #{self.human_player.code}" if self.human_player.code == @guess_code
  end

  def human_player_victory_message
    puts "Player wins!" if self.computer_player.code == @guess_code   
    puts "The code is: #{self.computer_player.code}" if self.computer_player.code == @guess_code
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

  def colors_initials
    @colors_initials = @colors.map { |color| color[0] }
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

  def illegal_colors
    self.human_player.code.split("") - colors_initials
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

game = Game.new("human_player", "computer_player")
game.play