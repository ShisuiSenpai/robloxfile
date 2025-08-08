-- QuestionManager.lua
-- Manages quiz questions, difficulty scaling, and answer validation

local QuestionManager = {}
QuestionManager.__index = QuestionManager

-- Question categories
local Categories = {
    MATH = "Math",
    SCIENCE = "Science",
    GEOGRAPHY = "Geography",
    HISTORY = "History",
    ROBLOX = "Roblox",
    CINEMA = "Cinema",
    NATURE = "Nature",
    GENERAL = "General Knowledge"
}

-- Question database organized by difficulty (1-6)
local QuestionDatabase = {
    -- Difficulty 1 (Footstep 1) - Very Easy
    [1] = {
        {
            category = Categories.MATH,
            question = "What is 5 + 3?",
            options = {"6", "7", "8", "9"},
            correct = 3
        },
        {
            category = Categories.MATH,
            question = "What is 10 - 4?",
            options = {"5", "6", "7", "8"},
            correct = 2
        },
        {
            category = Categories.ROBLOX,
            question = "What is the currency in Roblox called?",
            options = {"Coins", "Robux", "Tickets", "Gems"},
            correct = 2
        },
        {
            category = Categories.NATURE,
            question = "What color is the sky on a clear day?",
            options = {"Red", "Green", "Blue", "Yellow"},
            correct = 3
        },
        {
            category = Categories.GENERAL,
            question = "How many days are in a week?",
            options = {"5", "6", "7", "8"},
            correct = 3
        },
        {
            category = Categories.CINEMA,
            question = "What type of fish is Nemo?",
            options = {"Shark", "Clownfish", "Goldfish", "Tuna"},
            correct = 2
        }
    },
    
    -- Difficulty 2 (Footstep 2) - Easy
    [2] = {
        {
            category = Categories.MATH,
            question = "What is 7 × 6?",
            options = {"36", "42", "48", "54"},
            correct = 2
        },
        {
            category = Categories.SCIENCE,
            question = "What is H2O?",
            options = {"Air", "Fire", "Water", "Earth"},
            correct = 3
        },
        {
            category = Categories.GEOGRAPHY,
            question = "What is the capital of France?",
            options = {"London", "Berlin", "Madrid", "Paris"},
            correct = 4
        },
        {
            category = Categories.ROBLOX,
            question = "What year was Roblox created?",
            options = {"2004", "2006", "2008", "2010"},
            correct = 2
        },
        {
            category = Categories.NATURE,
            question = "How many legs does a spider have?",
            options = {"6", "8", "10", "12"},
            correct = 2
        },
        {
            category = Categories.CINEMA,
            question = "Who is the main character in 'Toy Story'?",
            options = {"Buzz", "Woody", "Rex", "Hamm"},
            correct = 2
        }
    },
    
    -- Difficulty 3 (Footstep 3) - Medium
    [3] = {
        {
            category = Categories.MATH,
            question = "What is 144 ÷ 12?",
            options = {"10", "11", "12", "13"},
            correct = 3
        },
        {
            category = Categories.SCIENCE,
            question = "What is the chemical symbol for gold?",
            options = {"Ag", "Au", "Fe", "Cu"},
            correct = 2
        },
        {
            category = Categories.HISTORY,
            question = "In which year did World War II end?",
            options = {"1943", "1944", "1945", "1946"},
            correct = 3
        },
        {
            category = Categories.GEOGRAPHY,
            question = "Which is the longest river in the world?",
            options = {"Amazon", "Nile", "Mississippi", "Yangtze"},
            correct = 2
        },
        {
            category = Categories.ROBLOX,
            question = "What is the maximum number of friends you can have on Roblox?",
            options = {"100", "200", "500", "Unlimited"},
            correct = 2
        },
        {
            category = Categories.CINEMA,
            question = "Who directed 'Jurassic Park'?",
            options = {"George Lucas", "Steven Spielberg", "James Cameron", "Christopher Nolan"},
            correct = 2
        }
    },
    
    -- Difficulty 4 (Footstep 4) - Medium-Hard
    [4] = {
        {
            category = Categories.MATH,
            question = "What is the square root of 225?",
            options = {"13", "14", "15", "16"},
            correct = 3
        },
        {
            category = Categories.SCIENCE,
            question = "How many planets are in our solar system?",
            options = {"7", "8", "9", "10"},
            correct = 2
        },
        {
            category = Categories.HISTORY,
            question = "Who was the first President of the United States?",
            options = {"Thomas Jefferson", "George Washington", "Abraham Lincoln", "John Adams"},
            correct = 2
        },
        {
            category = Categories.GEOGRAPHY,
            question = "What is the smallest continent?",
            options = {"Europe", "Antarctica", "Australia", "South America"},
            correct = 3
        },
        {
            category = Categories.NATURE,
            question = "What is the fastest land animal?",
            options = {"Lion", "Cheetah", "Gazelle", "Leopard"},
            correct = 2
        },
        {
            category = Categories.CINEMA,
            question = "Which movie won the Oscar for Best Picture in 2020?",
            options = {"1917", "Joker", "Parasite", "Ford v Ferrari"},
            correct = 3
        }
    },
    
    -- Difficulty 5 (Footstep 5) - Hard
    [5] = {
        {
            category = Categories.MATH,
            question = "What is 17² - 13²?",
            options = {"100", "110", "120", "130"},
            correct = 3
        },
        {
            category = Categories.SCIENCE,
            question = "What is the speed of light in km/s?",
            options = {"200,000", "250,000", "300,000", "350,000"},
            correct = 3
        },
        {
            category = Categories.HISTORY,
            question = "In which year did the Berlin Wall fall?",
            options = {"1987", "1988", "1989", "1990"},
            correct = 3
        },
        {
            category = Categories.GEOGRAPHY,
            question = "What is the deepest ocean trench?",
            options = {"Java Trench", "Mariana Trench", "Puerto Rico Trench", "Tonga Trench"},
            correct = 2
        },
        {
            category = Categories.ROBLOX,
            question = "What scripting language does Roblox use?",
            options = {"Python", "JavaScript", "Lua", "C++"},
            correct = 3
        },
        {
            category = Categories.CINEMA,
            question = "How many Infinity Stones are there in the Marvel Universe?",
            options = {"4", "5", "6", "7"},
            correct = 3
        }
    },
    
    -- Difficulty 6 (Footstep 6) - Very Hard (Final Question)
    [6] = {
        {
            category = Categories.MATH,
            question = "What is the 10th number in the Fibonacci sequence?",
            options = {"34", "55", "89", "144"},
            correct = 2
        },
        {
            category = Categories.SCIENCE,
            question = "How many bones are in an adult human body?",
            options = {"186", "196", "206", "216"},
            correct = 3
        },
        {
            category = Categories.HISTORY,
            question = "Which empire was the largest in history by land area?",
            options = {"Roman Empire", "British Empire", "Mongol Empire", "Ottoman Empire"},
            correct = 2
        },
        {
            category = Categories.GEOGRAPHY,
            question = "How many time zones does Russia span?",
            options = {"9", "10", "11", "12"},
            correct = 3
        },
        {
            category = Categories.NATURE,
            question = "What percentage of Earth's surface is covered by water?",
            options = {"61%", "66%", "71%", "76%"},
            correct = 3
        },
        {
            category = Categories.CINEMA,
            question = "Which film has won the most Academy Awards?",
            options = {"Ben-Hur", "Titanic", "Lord of the Rings: Return of the King", "All tied at 11"},
            correct = 4
        }
    }
}

function QuestionManager.new()
    local self = setmetatable({}, QuestionManager)
    self.usedQuestions = {} -- Track used questions per round
    return self
end

function QuestionManager:GetRandomQuestion(difficulty)
    difficulty = math.clamp(difficulty, 1, 6)
    
    local questions = QuestionDatabase[difficulty]
    if not questions or #questions == 0 then
        warn("[QuestionManager] No questions available for difficulty", difficulty)
        return nil
    end
    
    -- Get unused questions for this difficulty
    local availableQuestions = {}
    for i, question in ipairs(questions) do
        local questionId = difficulty .. "_" .. i
        if not self.usedQuestions[questionId] then
            table.insert(availableQuestions, {question = question, id = questionId})
        end
    end
    
    -- If all questions used, reset for this difficulty
    if #availableQuestions == 0 then
        for i = 1, #questions do
            local questionId = difficulty .. "_" .. i
            self.usedQuestions[questionId] = nil
        end
        availableQuestions = questions
    end
    
    -- Select random question
    local selected = availableQuestions[math.random(1, #availableQuestions)]
    if selected.id then
        self.usedQuestions[selected.id] = true
    end
    
    return selected.question or selected
end

function QuestionManager:ValidateAnswer(question, answerIndex)
    if not question or not answerIndex then
        return false
    end
    
    return question.correct == answerIndex
end

function QuestionManager:ResetUsedQuestions()
    self.usedQuestions = {}
end

return QuestionManager