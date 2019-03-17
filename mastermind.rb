$LOAD_PATH << '.'

require 'game_description'
require 'grid.rb'
require 'player.rb'

class Mastermind
  include GameDescription

  attr_accessor :start_game_response, :game_board, :rounds, :round, :code_length, :round_separator, :example_board
  attr_accessor :human_player, :computer_player, :human_role, :guess_attempt, :guesser, :creator
  attr_reader :start_game_decision, :determine_number_of_rounds, :determine_code_length


  def initialize
    @game_board = Board.new
    @example_board = Board.new
    @human_player = HumanPlayer.new
    @computer_player = ComputerPlayer.new
    @computer_player.name = "Computer Player"
  end

  def introduction
    puts TITLE
    puts INSTRUCTIONS
    puts colors_list
    puts ""
    display_example_board
    puts EXPLANATIONOFEXAMPLE
  end

  def prompt_start_game # begin game commands
    loop(&start_game_decision)
  end

  def start_game_decision
    @start_game_decision = lambda do
      ask_to_play
      continue_or_exit_game
    end
  end

  def continue_or_exit_game
    ask_player_name if start_game_response == "Y" || start_game_response == "YES"
    play if start_game_response == "Y" || start_game_response == "YES"
    leave_game if start_game_response == "N" || start_game_response == "NO"

    puts "You didn't answer yes or no!" if invalid_response?(start_game_response)
    raise StopIteration unless invalid_response?(start_game_response)
  end

  def ask_to_play
    puts "Do you want to play? (y/n)"
    self.start_game_response = gets.chomp.upcase
  end

  def invalid_response?(response)
    invalid_answer = Proc.new { |answer| answer == response }
    ["Y", "YES", "N", "NO"].none?(&invalid_answer)
  end

  def leave_game
    puts "See you later!"
    exit
  end

  def play
    puts "Lets begin!\n"
    set_game_details
    (choose_guess?) ? play_as_guesser : play_as_creator
    restart_game
  end

  def play_as_guesser
    puts "Computer Player has created a code:"
    puts self.computer_player.create_code(code_length)
    display_color_options
    play_guess_rounds
  end

  def play_as_creator
    human_player.create_hidden_code(code_length)
    computer_player.create_colors_first_letter(code_length)
    play_guess_rounds
  end


  def restart_game
    loop do
      puts "Do you want to play again?"
      restart_game_answer = gets.chomp.upcase
  
      play if restart_game_answer == "Y" || restart_game_answer == "YES"
      exit if restart_game_answer == "N" || restart_game_answer == "NO"
      puts "You didn't answer yes or no." if invalid_response?(restart_game_answer)
      break unless invalid_response?(restart_game_answer)
    end
  end

  def set_game_details
    choose_role
    set_and_display_game_board
  end

  def display_color_options
    puts INSTRUCTIONS[2]
    puts colors_list
  end

  def ask_human_guess_code
    loop do
      puts "\nPlease guess the code the computer has created:"
      self.human_player.guess_code = gets.chomp.upcase
  
      puts "Your guess needs to be #{code_length} letters long." if human_player.guess_code.length != code_length
      puts INVALIDCHARACTERSMESSAGE if INVALIDCHARACTERS =~ human_player.guess_code
      break if human_player.guess_code.length == code_length && !(INVALIDCHARACTERS =~ human_player.guess_code)
    end
  end

  def computer_guess_human_code
    puts "The computer player will now try to guess your hidden code."
    computer_player.guess_human_code
    puts computer_player.guess_code
  end

  def play_guess_rounds
    (1..rounds).each do |round|
      self.round = round
      ask_guesser_to_guess
      update_game_board(guesser.guess_code, creator.hidden_code)
      print_game_board
      victory_or_defeat_message
      break if correct_guess? || final_round?
      reduce_possible_combination_of_colors if guesser == computer_player
      display_color_options
    end
  end

  def reduce_possible_combination_of_colors
    computer_player.smart_deduction_of_possible_colors(guesser.guess_code, game_board.access_board_guess_result(round))
  end

  def ask_guesser_to_guess
    ask_human_guess_code if guesser == human_player
    computer_guess_human_code if guesser == computer_player
  end

  def update_game_board(guess_attempt, hidden_code)
    game_board.input_guess(guess_attempt, self.round)
    game_board.display_guess_result(hidden_code, guess_attempt, self.round)
  end

  def victory_or_defeat_message
    victory_message(guesser.name) if correct_guess?
    defeat_message(guesser.name) if final_round? && !correct_guess?
  end

  def defeat_message(player)
    puts "#{player} has failed to guess the hidden code in the selected number of rounds! #{player} LOSES!"
  end

  def victory_message(player)
    puts "#{player} has guessed the hidden code! #{player} WINS!"
  end

  def correct_guess?
    guesser.guess_code == creator.hidden_code
  end

  def final_round?
    self.round == rounds
  end

  def choose_role
    loop do
      ask_guess_or_create
      assign_role
      break unless valid_role_entered?
    end
  end

  def ask_player_name
    puts "What is your name? Please enter:"
    self.human_player.name = gets.chomp
  end

  def assign_role
    role_scenario_1 if choose_guess?
    role_scenario_2 if choose_create?
    puts "You didn't enter guess or create." if valid_role_entered?
  end

  def choose_guess?
    human_role == "G"
  end

  def choose_create?
    human_role == "C"
  end

  def ask_guess_or_create
    puts "\nDo you want to guess or create the code? (g/c)"
    self.human_role = gets.chomp.upcase
  end

  def role_scenario_1
    self.guesser = human_player
    self.creator = computer_player
  end

  def role_scenario_2
    self.guesser = computer_player
    self.creator = human_player
  end

  def valid_role_entered?
    valid_role = Proc.new { |answer| answer == human_role }
    ["G", "GUESS", "C", "CREATE"].none?(&valid_role)
  end

  def create_game_board # Game board
    game_board.create_board(rounds, code_length)
  end

  def ensure_valid_number_of_rounds #loop to get valid round number
    loop(&determine_number_of_rounds)
  end

  def determine_number_of_rounds
      @determine_number_of_rounds = lambda do
        ask_number_of_rounds
        error_if_round_invalid
        raise StopIteration if valid_round_range?
      end
  end

  def error_if_round_invalid
    not_a_number_message if rounds_contains_letters?
    self.rounds = rounds.to_i
    invalid_number_message(4, 12) unless valid_round_range?
  end

  def rounds_contains_letters?
    /\D/ =~ rounds
  end

  def not_a_number_message
    puts "You didn't enter a number! Please try again."
  end

  def invalid_number_message(min, max)
    puts "Number has to be in between #{min} and #{max}. Please try again."
  end

  def ask_number_of_rounds
    puts "How many rounds would you like to guess the code? (4 to 12)"
    self.rounds = gets.chomp
  end

  def valid_round_range?
    rounds >= 4 && rounds <= 12
  end
  
  def ensure_valid_code_length #loop to get valid code length number
    loop(&determine_code_length)
  end

  def determine_code_length
    @determine_code_length = lambda do
      ask_code_length
      error_code_length_invalid
      raise StopIteration if valid_code_length?
    end
  end

  def error_code_length_invalid
    not_a_number_message if code_length_contains_letters?
    self.code_length = code_length.to_i
    invalid_number_message(4, 8) unless valid_code_length?
  end

  def ask_code_length
    puts "How many letters would you like the code to be? (4 to 8)"
    self.code_length = gets.chomp

  end

  def code_length_contains_letters?
    /\D/ =~ code_length
  end

  def valid_code_length?
    code_length >= 4 && code_length <= 8
  end
  
  def determine_game_board_size
    ensure_valid_number_of_rounds
    ensure_valid_code_length
  end
  
  def print_game_board
    game_board.print_entire_board
  end
  
  def set_and_display_game_board
    determine_game_board_size
    create_game_board
    print_game_board
  end
  
  def create_example_board # Example Board
    example_board.create_board(1, 4)
  end

  def assign_example_board
    example_board.board = EXAMPLEGRID
  end

  def print_example_board
    example_board.print_entire_board
  end

  def display_example_board
    create_example_board
    assign_example_board
    print_example_board
  end

  def colors_list # Colors list with color initials as bullets
    list_colors_as_options = Proc.new { |color| color.to_s.gsub(/^\w/, "#{color[0].upcase} - (#{color[0].upcase})") }
    colors_list = COLORS.collect(&list_colors_as_options)
  end
end


game1 = Mastermind.new
game1.introduction
game1.prompt_start_game