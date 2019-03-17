class Board
  attr_accessor :line, :heading_separator, :round_separator, :board, :round_number, :total_rounds, :code_length, :example_grid
  attr_accessor :hidden_code, :current_guess, :guess_attempt, :guessed_letter, :letter_position, :current_round, :guessed_result_params
  attr_accessor :guessed_letter_params, :check_individual_letters, :determine_correct_guessed_letters, :correct_letters
  attr_accessor :correct_count, :guess_count, :code_count, :incorrect_letters_count, :find_letters_exceeding_code_in_wrong_position

  def initialize
    @round_separator = ""
    @heading_separator = ""
    @correct_count = Hash.new(0)
    @guess_count = Hash.new(0)
    @code_count = Hash.new(0)
    @no_incorrect_letters = Hash.new(0)
  end

  
  GRIDHEADINGS = [ "GUESS", "RESULT" ]
  HEADINGSEPARATOR = "+---------------+---------------+----------+"
  ROUNDSEPARATOR = "+---+---+---+---+---+---+---+---+---+---+----------+"
  GUESSRESULT = ["X", "O", "-"]

  def adjust_round_separator(code_length)
    self.round_separator = ""
    adjustment_factor = code_length
    adjustment_factor.times { self.round_separator += "+---+---" }
    self.round_separator += "+----------+"
  end

  def adjust_heading_separator(code_length)
    self.heading_separator = "+---------------"
    adjustment_factor = code_length - 4
    adjustment_factor.times { self.heading_separator += "----" }
    self.heading_separator += heading_separator
    self.heading_separator += "+----------+"
  end

  def create_board(total_rounds, code_length)
    @board = Array.new(total_rounds) {Array.new(2) {Array.new(code_length, " ")}}
    @code_length = code_length
    @total_rounds = total_rounds
  end

  def create_example
    @example_grid = [ [["R", "O", "Y", "G"], ["X", "O", "-", "-"]] ]
  end

  def print_row
    row = ""
    round_number = row + "1"
    puts round_number
  end

  def print_entire_board
    adjust_round_separator(self.code_length)
    adjust_heading_separator(self.code_length)

    print_board_heading(self.code_length)
    print_all_rounds = Proc.new { |n| print_board_row(n) }
    (1..self.total_rounds).each(&print_all_rounds)
  end

  def print_board_heading(code_length)
    heading = ""
    heading_width = code_length * 4 - 3
    create_heading = Proc.new { |head| heading += "| #{head.center(heading_width)} " }
    GRIDHEADINGS.each(&create_heading)
    heading += "|          |"
    display_heading = Proc.new { |n| puts (n % 2 == 0) ? self.heading_separator : heading }

    (0..2).each(&display_heading)
  end

  def print_board_row(num)
    row = ""
    self.round_number = self.board[num - 1]
    display_guess_and_result = Proc.new { |guessed_letter| row += "| #{guessed_letter} " }
    round_number.each { |guess| guess.each(&display_guess_and_result) }
    row += (num < 10) ? "| Round #{num}  |" : "| Round #{num} |"
    puts row
    puts correct_separator
  end

  def final_round?
    round_number.equal? self.board.last
  end

  def correct_separator
    (final_round?) ? heading_separator : round_separator
  end

  def input_guess(guess, round)
    guess = guess.split("")
    enter_guess = Proc.new { |letter,index| access_board_guess_attempt(round)[index] = letter }
    guess.each_with_index(&enter_guess)
  end

  def access_board_guess_attempt(num)
    self.board[num - 1][0]
  end

  def access_board_guess_result(num)
    self.board[num - 1][1]
  end

  def display_guess_result(hidden_code, guess, round)
    reset_count_hashes
    guessed_result_params.call(hidden_code, guess, round)
    current_guess.each_with_index(&determine_correct_guessed_letters)
    determine_guess_count_values
    current_guess.each_with_index(&check_individual_letters)
      
    #puts "This is the number of correct letters: #{correct_count}" 
    #puts "This is the number o letters in guess: #{guess_count}"
    #puts "This is the number of letters in code: #{code_count}"
    #puts "This is the number of incorrect letters: #{incorrect_letters_count}"
  end

  def reset_count_hashes
    @correct_count = Hash.new(0)
    @guess_count = Hash.new(0)
    @code_count = Hash.new(0)
    @incorrect_letters_count = Hash.new(0)
  end

  def determine_guess_count_values
    correct_letters.each { |letter|correct_count[letter] += 1 }
    current_guess.each { |letter|guess_count[letter] += 1 }
    self.hidden_code.each { |letter|code_count[letter] += 1 }
    current_guess.each_with_index(&find_letters_exceeding_code_in_wrong_position)
  end

  def determine_correct_guessed_letters
    self.correct_letters = []
    @determine_correct_guessed_letters = lambda do |letter, index|
      (letter == hidden_code[index]) ? correct_letters[index] = letter : correct_letters[index] = nil
    end
  end

  def check_individual_letters
    @check_individual_letters = lambda do |letter, index|
      guessed_letter_params.call(letter, index)
      input_clues
    end
  end

  def guessed_result_params
    @guessed_result_params = lambda do |hidden_code, guess, round|
      self.hidden_code = hidden_code.split("")
      self.current_guess = guess.split("")
      self.current_round = round
    end
  end

  def guessed_letter_params
    @guessed_letter_params = lambda do |letter, index|
      self.guessed_letter = letter
      self.letter_position = index
    end
  end

  def find_letters_exceeding_code_in_wrong_position
    @find_letters_exceeding_code_in_wrong_position = lambda do |letter, index|
      guessed_letter_params.call(letter,index)
      count_incorrect_letters_exceeding_code if wrong_guess_position? && more_in_guess_than_code? && less_in_correct_than_code?
    end
  end

  def count_incorrect_letters_exceeding_code
    incorrect_letters_count[guessed_letter] = guess_count[guessed_letter].to_i - code_count[guessed_letter].to_i
  end

  def guess_position_eql_code?
    guessed_letter == self.hidden_code[letter_position]
  end

  def guess_position_not_eql_code?
    guessed_letter != self.hidden_code[letter_position]
  end

  def code_not_contain_guessed_letter?
    self.hidden_code.none? {|l| l == guessed_letter }
  end

  def code_contain_guessed_letter?
    self.hidden_code.any? {|l| l == guessed_letter }
  end

  def more_in_guess_than_code?
    guess_count[guessed_letter] > code_count[guessed_letter]
  end

  def less_in_correct_than_code?
    correct_count[guessed_letter] < code_count[guessed_letter]
  end

  def wrong_guess_position?
    guess_position_not_eql_code? && code_contain_guessed_letter?
  end

  def guessed_all_particular_letter_in_code?
    correct_letters.count(guessed_letter) == hidden_code.count(guessed_letter)
  end

  def input_o
    access_board_guess_result(current_round)[letter_position] = GUESSRESULT[1]
  end

  def input_x
    access_board_guess_result(current_round)[letter_position] = GUESSRESULT[0]
  end

  def input_x_decrement_incorrect_letter
    input_x
    self.incorrect_letters_count[guessed_letter] -= 1
  end

  def input_dash
    access_board_guess_result(current_round)[letter_position] = GUESSRESULT[2]
  end

  def input_clues
    case
    when guess_position_eql_code? then input_o
    when guess_position_not_eql_code? && code_not_contain_guessed_letter? then input_x
    when wrong_guess_position? && incorrect_letters_count[guessed_letter] >= 1 then input_x_decrement_incorrect_letter
    when wrong_guess_position? && guessed_all_particular_letter_in_code? then input_x
    when wrong_guess_position? then input_dash
    end
  end
end