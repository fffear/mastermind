module GameDescription
  TITLE = [ "====================================".center(80),
            "Welcome to Fffear's Mastermind Game!".center(80),
            " ====================================\n".center(80)
          ]

  INSTRUCTIONS = [ "Player's will have a certain number of chances to guess the correct sequence of colors.\n\n",
                   "To guess the sequence of colors, enter the first letter of the color consecutively without any spaces.\n\n",
                   "The available colors are: \n\n"
                 ]

  EXPLANATIONOFEXAMPLE = [
                           "\nAs you can see from the example above, the color combination you have guessed appears on the left hand side.\n\n",
                           "On the right, the result of the guess is displayed.\n\n",
                           "- The 'X' indicates that the guessed letter in the corresponding position (the letter 'R') is incorect and is not in the hidden code.",
                           "- The 'O' indicates that the guessed letter in the corresponding position (the letter 'O') is correct and is in the hidden code.",
                           "- The '-' indicates that the guessed letter in the corresponding position (the letter 'Y' and 'G') is in the hidden code, but is in the wrong position.",
                           "\nYou have a certain number of rounds to guess the correct code.\n\n",
                           "If you don't guess the correct code in the allocated number of rounds, you lose!"
                        ]

  COLORS = %w{red orange yellow green blue indigo violet}
  GUESSRESULT = ["X", "O", "-"]

  EXAMPLEGRID = [ [["R", "O", "Y", "G"], ["X", "O", "-", "-"]] ]
  INVALIDCHARACTERS = /[\d\!\@\#\$\%\^\&\*\(\)\-\+\=\/\.\,\[\]\{\}\|\:\;\"\']/
  INVALIDCHARACTERSMESSAGE = "There are invalid characters in your code! Please only use the colours provided."

  GRID = Array.new(12) {Array.new(2) {Array.new(4, " ")}}

end