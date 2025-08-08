-- QuizController.lua
-- Controls quiz rounds, timing, and player progression

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConstants"))

local QuizController = {}
QuizController.__index = QuizController

local QUIZ_TIME = 15 -- seconds per question

function QuizController.new(gameManager, pathManager, questionManager)
    local self = setmetatable({}, QuizController)
    
    self.gameManager = gameManager
    self.pathManager = pathManager
    self.questionManager = questionManager
    
    self.currentQuestion = nil
    self.currentTimer = 0
    self.timerConnection = nil
    self.playerAnswers = {}
    self.isQuizActive = false
    
    -- Create RemoteEvents
    self:CreateRemoteEvents()
    
    return self
end

function QuizController:CreateRemoteEvents()
    -- Use existing RemoteEvents from the folder
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    
    -- Get existing RemoteEvents
    self.showQuestionRemote = remoteEvents:WaitForChild("ShowQuestion")
    self.submitAnswerRemote = remoteEvents:WaitForChild("SubmitAnswer")
    self.updateQuizTimerRemote = remoteEvents:WaitForChild("UpdateQuizTimer")
    self.showQuizResultRemote = remoteEvents:WaitForChild("ShowQuizResult")
    self.announceWinnerRemote = remoteEvents:WaitForChild("AnnounceWinner")
    self.updateNextQuestionRemote = remoteEvents:WaitForChild("UpdateNextQuestion")
    
    print("[QuizController] Connected to existing RemoteEvents")
    
    -- Connect answer submission
    self.submitAnswerRemote.OnServerEvent:Connect(function(player, answerIndex)
        self:OnPlayerAnswer(player, answerIndex)
    end)
end

function QuizController:StartQuizRound()
    if self.isQuizActive then
        warn("[QuizController] Quiz already active!")
        return
    end
    
    print("[QuizController] Starting quiz round")
    
    self.isQuizActive = true
    self.playerAnswers = {}
    
    -- Determine difficulty based on furthest player
    local maxFootstep = 1
    local activePlayers = self.gameManager:GetActivePlayers()
    
    for _, player in ipairs(activePlayers) do
        local position = self.pathManager:GetPlayerPosition(player)
        if position and position.footstepIndex > maxFootstep then
            maxFootstep = position.footstepIndex
        end
    end
    
    -- Get question for current difficulty
    self.currentQuestion = self.questionManager:GetRandomQuestion(maxFootstep)
    
    if not self.currentQuestion then
        warn("[QuizController] Failed to get question!")
        self:EndQuizRound()
        return
    end
    
    -- Show question to all players
    self.showQuestionRemote:FireAllClients(self.currentQuestion, QUIZ_TIME)
    
    -- Start timer
    self:StartTimer()
end

function QuizController:StartTimer()
    self.currentTimer = QUIZ_TIME
    
    -- Update clients immediately
    self.updateQuizTimerRemote:FireAllClients(self.currentTimer)
    
    -- Timer countdown
    if self.timerConnection then
        self.timerConnection:Disconnect()
    end
    
    self.timerConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self.currentTimer = self.currentTimer - deltaTime
        
        -- Update clients every second
        local roundedTime = math.ceil(self.currentTimer)
        if roundedTime ~= math.ceil(self.currentTimer + deltaTime) then
            self.updateQuizTimerRemote:FireAllClients(roundedTime)
        end
        
        -- Check if time's up or everyone answered
        if self.currentTimer <= 0 or self:AllPlayersAnswered() then
            self:EndQuizRound()
        end
    end)
end

function QuizController:OnPlayerAnswer(player, answerIndex)
    -- Validate player and answer
    if not self.isQuizActive or not self.currentQuestion then
        return
    end
    
    -- Check if player already answered
    if self.playerAnswers[player] then
        return
    end
    
    -- Validate answer index
    if type(answerIndex) ~= "number" or answerIndex < 1 or answerIndex > 4 then
        return
    end
    
    -- Record answer
    self.playerAnswers[player] = {
        answer = answerIndex,
        correct = self.questionManager:ValidateAnswer(self.currentQuestion, answerIndex)
    }
    
    print("[QuizController]", player.Name, "answered", answerIndex, "- Correct:", self.playerAnswers[player].correct)
end

function QuizController:AllPlayersAnswered()
    local activePlayers = self.gameManager:GetActivePlayers()
    
    for _, player in ipairs(activePlayers) do
        if not self.playerAnswers[player] then
            return false
        end
    end
    
    return true
end

function QuizController:EndQuizRound()
    print("[QuizController] Ending quiz round")
    
    self.isQuizActive = false
    
    -- Stop timer
    if self.timerConnection then
        self.timerConnection:Disconnect()
        self.timerConnection = nil
    end
    
    -- Process results
    local results = {}
    local winners = {}
    local activePlayers = self.gameManager:GetActivePlayers()
    
    for _, player in ipairs(activePlayers) do
        local answerData = self.playerAnswers[player]
        
        if answerData and answerData.correct then
            -- Player got it right - advance them
            table.insert(winners, player)
            results[player] = {correct = true, answer = answerData.answer}
        else
            -- Player got it wrong or didn't answer
            results[player] = {correct = false, answer = answerData and answerData.answer or 0}
        end
    end
    
    -- Show results to all players
    -- Convert player instances to a format that works better with RemoteEvents
    local serializedResults = {}
    for player, data in pairs(results) do
        serializedResults[player.Name] = data
    end
    
    print("[QuizController] Sending results:", serializedResults)
    self.showQuizResultRemote:FireAllClients(serializedResults, self.currentQuestion.correct)
    
    -- Wait for results display
    wait(3)
    
    -- Only show countdown if there are more questions coming
    local anyPlayerContinuing = false
    for _, player in ipairs(winners) do
        local position = self.pathManager:GetPlayerPosition(player)
        if position and position.footstepIndex < 6 then
            anyPlayerContinuing = true
            break
        end
    end
    
    if anyPlayerContinuing then
        -- Show next question countdown (3 seconds)
        print("[QuizController] Showing next question countdown")
        for i = 3, 1, -1 do
            self.updateNextQuestionRemote:FireAllClients(i)
            wait(1)
        end
        self.updateNextQuestionRemote:FireAllClients(0)
        wait(0.2)
    end
    
    -- Advance winners
    for _, player in ipairs(winners) do
        local position = self.pathManager:GetPlayerPosition(player)
        if position then
            if position.footstepIndex >= 6 then
                -- Player wins!
                self:OnPlayerWin(player)
            else
                -- Advance to next footstep
                self.pathManager:AdvancePlayer(player)
            end
        end
    end
    
    -- Wait for movement to complete
    wait(3)
    
    -- Check if game should continue
    if self.gameManager:GetState() == GameConstants.GameState.IN_GAME then
        -- Start next round after a short delay
        wait(2)
        self:StartQuizRound()
    end
end

function QuizController:OnPlayerWin(player)
    print("[QuizController] Player", player.Name, "wins!")
    
    -- Announce winner
    self.announceWinnerRemote:FireAllClients(player)
    
    -- Update game state
    self.gameManager:SetState(GameConstants.GameState.ROUND_END)
    
    -- TODO: Add celebration effects, rewards, etc.
    
    -- Reset game after delay
    wait(5)
    self:ResetQuiz()
end

function QuizController:ResetQuiz()
    self.currentQuestion = nil
    self.playerAnswers = {}
    self.isQuizActive = false
    
    if self.timerConnection then
        self.timerConnection:Disconnect()
        self.timerConnection = nil
    end
    
    self.questionManager:ResetUsedQuestions()
end

return QuizController