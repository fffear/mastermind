$LOAD_PATH << '.'

require 'game_description'
require 'grid.rb'

class Player
  include GameDescription
  attr_accessor :name, :role, :guess, :hidden_code, :guess_code, :ensure_valid_hidden_code 

  def initialize
    @guess_code = []
  end
end

class HumanPlayer < Player
  def create_hidden_code(code_length)
    loop { ensure_valid_hidden_code.call(code_length) }
  end

  def ensure_valid_hidden_code
    @ensure_valid_hidden_code = Proc.new do |code_length|
      ask_create_code
      
      puts "The hidden code needs to be #{code_length} letters long." if code_length_larger_than_allowed?(code_length)
      puts "The hidden code needs to be #{code_length} letters long." if code_length_less_than_allowed?(code_length)
      puts INVALIDCHARACTERSMESSAGE if invalid_characters_in_code?
      raise StopIteration if appropriate_code_length(code_length) && !invalid_characters_in_code?
    end
  end

  def ask_create_code
    puts "Please create the hidden code for the computer player to guess:"
    self.hidden_code = gets.chomp.upcase
  end

  def appropriate_code_length(code_length)
    hidden_code.length == code_length
  end

  def code_length_larger_than_allowed?(code_length)
    hidden_code.length > code_length
  end

  def code_length_less_than_allowed?(code_length)
    hidden_code.length < code_length
  end

  def invalid_characters_in_code?
    INVALIDCHARACTERS =~ hidden_code
  end
end

class ComputerPlayer < Player
  attr_reader :generate_random_color
  attr_accessor :colors_first_letter, :available_colors, :current_guess, :results, :guessed_letter, :guessed_letter_index
  attr_accessor :results_index_with_same_letter, :results_with_same_letter, :colors_in_wrong_position, :available_colors_position
  attr_accessor :color_in_wrong_position


  def initialize
    self.colors_first_letter = COLORS.map { |color| color[0].upcase }
    self.colors_in_wrong_position = []
    super
  end

  def create_code(hidden_code_length)
    self.hidden_code = []
    (1..hidden_code_length).each(&generate_random_color)
    display_hidden_code
  end

  def generate_random_color
    @generate_random_color = lambda { |num| self.hidden_code << COLORS[rand(COLORS.length)][0] }
  end

  def display_hidden_code
    self.hidden_code = hidden_code.join.upcase
  end

  def create_colors_first_letter(hidden_code_length)
    self.available_colors = Array.new(hidden_code_length) {colors_first_letter}
  end

  def guessed_one_color_in_wrong_position?
    available_colors_position.one? { |c| c == colors_in_wrong_position[0] } &&
    available_colors_position.length > 1 && colors_in_wrong_position.length == 1
  end

  def guessed_more_than_one_color_in_wrong_position?
    available_colors_position.length > 1 && colors_in_wrong_position.length > 1
  end

  def no_colors_in_wrong_position_in_available_position?
    available_colors_position.length == (available_colors_position - colors_in_wrong_position).length
  end

  def colors_in_wrong_position_in_available_position?
    available_colors_position.count(color_in_wrong_position) == 1
  end

  def use_color_in_wrong_position_in_guess
    @guess_code << color_in_wrong_position
    self.colors_in_wrong_position = colors_in_wrong_position - [color_in_wrong_position]
    self.colors_in_wrong_position << color_in_wrong_position
  end

  def random_guess_from_available_colors
    self.guess_code << available_colors_position[rand(available_colors_position.length)]
  end

  def determine_color_from_clues
    colors_in_wrong_position.each do |color|
      self.color_in_wrong_position = color

      case
      when colors_in_wrong_position_in_available_position? then use_color_in_wrong_position_in_guess
      when no_colors_in_wrong_position_in_available_position? then random_guess_from_available_colors
      end

      break if colors_in_wrong_position_in_available_position? || no_colors_in_wrong_position_in_available_position?
    end
  end

  def remove_from_colors_in_wrong_position_from_deduction
    colors_in_wrong_position.each do |color| 
      if available_colors.all? { |array| array.count(color) == 0 || array.count(color) == 1 && array.length == 1 }
        self.colors_in_wrong_position -= [color]
      end
    end
  end

  def smart_guess
    self.guess_code << colors_in_wrong_position[0] if guessed_one_color_in_wrong_position?
    determine_color_from_clues if guessed_more_than_one_color_in_wrong_position?
    random_guess_from_available_colors unless guessed_one_color_in_wrong_position? || guessed_more_than_one_color_in_wrong_position?
  end

  def guess_human_code
    self.guess_code = []

    available_colors.each do |colors|
      self.available_colors_position = colors
      smart_guess
      remove_from_colors_in_wrong_position_from_deduction 
    end

    display_guess_code
  end

  def display_guess_code
    self.guess_code = guess_code.join.upcase
  end

  def smart_deduction_of_possible_colors(current_guess, results)
    assign_arguments_to_instance_var(current_guess, results)

    self.current_guess.each_with_index do |letter, index|
      assign_letters_and_index_in_guess(letter, index)
      find_results_with_same_letter
      reduce_possible_colors_from_clues
    end
  end

  def reduce_possible_colors_from_clues
    case
    when feedback_o? then remove_all_wrong_colors
    when feedback_dash? then delete_color_from_one_position # add method which lists values of colors in the incorrect position
    when feedback_x? && only_color_in_guess? then delete_color_from_all_positions
    when feedback_x? && same_multiple_colors_in_guess_and_none_misplaced? then remove_color_all_positions_with_min_two_colors
    when feedback_x? && same_multiple_colors_in_guess_and_some_misplaced? then delete_color_from_one_position
    end
  end

  def feedback_o?
    results[guessed_letter_index] == "O"
  end

  def feedback_x?
    results[guessed_letter_index] == "X"
  end

  def feedback_dash?
    results[guessed_letter_index] == "-"
  end

  def only_color_in_guess?
    current_guess.count(guessed_letter) == 1
  end

  def multiple_colors_in_guess?
    current_guess.count(guessed_letter) > 1
  end
  
  def same_multiple_colors_in_guess_and_none_misplaced?
    multiple_colors_in_guess? && other_positions_same_color_rightly_placed?
  end

  def same_multiple_colors_in_guess_and_some_misplaced?
    multiple_colors_in_guess? && other_positions_same_color_misplaced?
  end

  def other_positions_same_color_misplaced?
    results_with_same_letter.any? { |result| result == "-" }
  end

  def other_positions_same_color_rightly_placed?
    results_with_same_letter.none? { |result| result == "-" }
  end

  def remove_color_all_positions_with_min_two_colors
    available_colors.each_with_index do |array, index|
      array.select! { |c| c != guessed_letter } if available_colors[index].length > 1
    end
    self.colors_in_wrong_position = colors_in_wrong_position - [guessed_letter]
  end

  def assign_arguments_to_instance_var(current_guess, results)
    self.current_guess = current_guess.split("")
    self.results = results
  end

  def assign_letters_and_index_in_guess(letter, index)
    self.guessed_letter = letter
    self.guessed_letter_index = index
  end

  def find_results_with_same_letter
    self.results_index_with_same_letter = results.each_index.select { |i| current_guess[i] == guessed_letter }
    self.results_with_same_letter = results_index_with_same_letter.map { |num| results[num] }
  end

  def delete_color_from_all_positions
    self.available_colors.each_with_index { |array, index| array.select! { |c| c != guessed_letter } }
    self.colors_in_wrong_position = colors_in_wrong_position - [guessed_letter]

  end
  
  def delete_color_from_one_position
    (self.colors_in_wrong_position << guessed_letter).uniq!
    self.available_colors[guessed_letter_index] = available_colors[guessed_letter_index].select { |color| color != guessed_letter }
    
  end

  def remove_all_wrong_colors
    self.available_colors[guessed_letter_index] = [guessed_letter]
  end
end
