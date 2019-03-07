class String
  def red
    "\e[31m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end
end

class Game
  attr_reader :colors, :color_strings
  def initialize(human_player, computer_player)
    @colors = %w{red orange yellow green indigo blue}
    #@colors = {red: "r", orange: "o", yellow: "y", green: "g", indigo: "i", blue: "b"}
    @human_player = Player.new(human_player, "guess_code")
    @computer_player = Player.new(computer_player, "set_code")
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
    @code = ""
    (1..4).each do
      random_number = rand(0..5)
      @code += @colors[random_number][0]
    end
    puts "The computer has generated the 4 color code."
    puts @code
  end

  def play
    self.introduction
    self.computer_set_code

    (1..12).each do
      print "Please guess the 4 color code by entering the 1st letter of the color you are guessing."
      print " (eg. 'rgyb' to guess 'red, green, yellow, blue')\n"
      print "The available colors are: "
      print_color_with_first_letter_brackets
      puts "You have 12 attempts."
      @guess_code = gets.chomp

      compare_guess_to_code
      break if @guess_code == @code
    end

    self.prompt_restart_game
  end

  def compare_guess_to_code
    guess_code = @guess_code.split("")
    code = @code.split("")

    if @guess_code == @code
      puts "You have guessed the winning code!"
      return
    end
    
    i = 0
    guess_code.each do |letter|
      print (letter == code[i]) ? letter.green :
            (letter != code[i] && code.any? { |l| l == letter }) ? letter : letter.red
      i += 1
      puts "" if i == 4
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
  attr_reader :name
  def initialize(name, role)
    @name = name
    @role = role
  end

  def name
    @name
  end

  def role
    @role
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