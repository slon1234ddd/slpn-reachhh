-- SLPN Visual Reach (V13.1 - 23% POWER)  
 -- Scale 1-10: 1 = +23% (Subtle), 10 = +230% (Strong) 
 -- FIX: Zmniejszono moc zasięgu do 23% na poziom. 
   
 if getgenv().SLPN_V13_Loaded then   
     getgenv().SLPN_V13_Loaded = false   
 end  
 getgenv().SLPN_V13_Loaded = true  
   
 local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()  
 local RunService = game:GetService("RunService")  
 local UserInputService = game:GetService("UserInputService") 
 local Players = game:GetService("Players")  
 local LocalPlayer = Players.LocalPlayer  
   
 local Window = Rayfield:CreateWindow({  
    Name = "SLPN | All Balls Reach (V13.1)",  
    LoadingTitle = "Ładowanie V13.1 SUBTLE...",  
    LoadingSubtitle = "by Assistant (23% Power)",  
    ConfigurationSaving = { Enabled = true, FolderName = "SLPN_V13", FileName = "Config" },  
    Discord = { Enabled = false, Invite = "noinvite", RememberJoins = true },  
    KeySystem = false,  
 })  
   
 -- Variables  
 local ReachEnabled = false  
 local VisualsEnabled = true  
 local ReachLevel = 1   
 local HitboxTransparency = 0.98  
 local GhostBallEnabled = false 
 local SafeModeEnabled = true -- Nowa flaga Safe Mode 
 local OriginalTransp = {} 
 local BallNames = {"Ball", "Football", "SoccerBall", "CLIENT_BALL_", "RealBall", "Soccer Ball", "FootballPart", "TPSBall", "MPSBall", "BallPart", "GameBall", "MainBall"}  
 local TrackedBalls = {}  
 local ActiveVisuals = {}  
 local LastTouchTime = {}  
 local PlayerCache = {} -- Cache pozycji graczy 
  
 -- UI Setup  
 local MainTab = Window:CreateTab("Główne", 4483362458)   
 local BallStatusLabel = MainTab:CreateLabel("Status: Szukanie piłek...")  
  
 -- Optymalizacja: Aktualizacja cache graczy co 0.2s (5Hz) zamiast co klatkę 
 task.spawn(function() 
     while true do 
         if SafeModeEnabled then 
             local newCache = {} 
             for _, player in pairs(Players:GetPlayers()) do 
                 if player ~= LocalPlayer and player.Character then 
                     local root = player.Character:FindFirstChild("HumanoidRootPart") 
                     if root then 
                         table.insert(newCache, root.Position) 
                     end 
                 end 
             end 
             PlayerCache = newCache 
         end 
         task.wait(0.2) 
     end 
 end) 
  
 -- Pomocnicza funkcja do sprawdzania czy ktoś inny jest blisko piłki (korzysta z cache) 
 local function IsAnotherPlayerNear(ball, baseThreshold) 
     if not SafeModeEnabled then return false end 
      
     -- Dynamiczny próg: jeśli piłka leci szybko, ochrona gracza jest mniejsza (łatwiejsze przechwyty) 
     local velocity = ball.Velocity.Magnitude 
     local threshold = baseThreshold 
      
     if velocity > 30 then 
         threshold = math.max(3.5, baseThreshold - (velocity / 20)) -- Zmniejsz próg przy strzałach 
     end 
      
     for _, pos in ipairs(PlayerCache) do 
         if (pos - ball.Position).Magnitude < threshold then 
             return true 
         end 
     end 
     return false 
 end 
  
 -- Filtr piłki 
 local function IsBall(obj) 
     if not obj:IsA("BasePart") then return false end 
     if obj:IsDescendantOf(LocalPlayer.Character) then return false end 
     if obj.Anchored then return false end 
      
     local name = obj.Name:lower() 
     local isBallName = false 
     for _, pattern in pairs(BallNames) do 
         if name == pattern:lower() or name:find("ball") or name:find("football") then 
             isBallName = true 
             break 
         end 
     end 
      
     -- Dodatkowy check po rozmiarze (piłki są zazwyczaj sferyczne i małe/średnie) 
     if isBallName or (obj:IsA("Part") and obj.Shape == Enum.PartType.Ball) then 
         return true 
     end 
     return false 
 end 
  
 -- Śledzenie piłek 
 local function AddBall(obj) 
     if not TrackedBalls[obj] and IsBall(obj) then 
         TrackedBalls[obj] = true 
         LastTouchTime[obj] = 0 
         BallStatusLabel:Set("Status: Znaleziono piłkę (" .. obj.Name .. ")") 
     end 
 end 
  
 workspace.DescendantAdded:Connect(function(obj) 
     AddBall(obj) 
 end) 
  
 local function CleanupVisuals(ball) 
     if ActiveVisuals[ball] then 
         local visuals = ActiveVisuals[ball] 
         if visuals.Sphere then pcall(function() visuals.Sphere:Destroy() end) end 
         ActiveVisuals[ball] = nil 
     end 
 end 
  
 -- Główna logika (V11.1 RESTORED) 
 task.spawn(function() 
     while true do 
         task.wait(1/30) -- 30Hz 
          
         if not ReachEnabled then  
             for ball, _ in pairs(ActiveVisuals) do CleanupVisuals(ball) end 
             continue 
         end  
           
         local char = LocalPlayer.Character  
         local hum = char and char:FindFirstChild("Humanoid") 
         local root = char and char:FindFirstChild("HumanoidRootPart") 
         local rFoot = char and (char:FindFirstChild("Right Foot") or char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")) or root 
          
         if not hum or not root then continue end 
         local state = hum:GetState() 
         if state == Enum.HumanoidStateType.Seated or state == Enum.HumanoidStateType.Dead then continue end 
  
         local multiplier = 1 + (ReachLevel * 0.23)  
  
         -- Przetwarzanie wszystkich śledzonych piłek 
         for ball, _ in pairs(TrackedBalls) do 
             if ball and ball.Parent and not ball.Anchored then 
                 -- Ghost Ball logic 
                 if GhostBallEnabled then 
                     if not OriginalTransp[ball] then OriginalTransp[ball] = ball.Transparency end 
                     ball.Transparency = 0.95 
                 end 
  
                 local dist = (root.Position - ball.Position).Magnitude 
                 local reachRadius = (ball.Size.Magnitude * multiplier) / 1.4 
  
                 -- 1. Zarządzanie wizualizacjami 
                 if VisualsEnabled and dist < 150 then 
                     local visuals = ActiveVisuals[ball] 
                     if not visuals then 
                         visuals = {} 
                         visuals.Sphere = Instance.new("SphereHandleAdornment") 
                         visuals.Sphere.Color3 = Color3.fromRGB(0, 255, 0) 
                         visuals.Sphere.AlwaysOnTop = false 
                         visuals.Sphere.Adornee = ball 
                         visuals.Sphere.Parent = LocalPlayer:WaitForChild("PlayerGui") 
                         ActiveVisuals[ball] = visuals 
                     end 
                     visuals.Sphere.Radius = reachRadius 
                     visuals.Sphere.Transparency = HitboxTransparency 
                 else 
                     CleanupVisuals(ball) 
                 end 
  
                 -- 2. Logika interakcji (V12.1 - PLAYER DISTANCE CHECK) 
                 local deadzone = 3.5  
                 local dotProduct = root.CFrame.LookVector:Dot((ball.Position - root.Position).Unit) 
                 local heightDiff = math.abs(root.Position.Y - ball.Position.Y) 
                  
                 -- Relaxed dotProduct (> -0.5 zamiast > 0.1) 
                 if dist <= reachRadius and dist > deadzone and dotProduct > -0.5 and heightDiff < 5 then 
                     local now = tick() 
                     -- Sprawdź czy inny gracz nie ma już piłki (Safe Mode) 
                     local isNear = IsAnotherPlayerNear(ball, 5.0) -- ZMNIEJSZONO: Próg 5.0 studa zamiast 6.5 
                      
                     if not isNear then 
                         -- Cooldown 0.1s zamiast resetowania po wyjściu z zasięgu 
                         if (now - (LastTouchTime[ball] or 0)) > 0.1 then 
                             if ball.Velocity.Magnitude < 120 then -- Zwiększony limit prędkości 
                                 firetouchinterest(rFoot, ball, 0) 
                                 task.wait() 
                                 firetouchinterest(rFoot, ball, 1) 
                                 LastTouchTime[ball] = now 
                             end 
                         end 
                     end 
                 end 
             else 
                 -- Piłka nieprawidłowa lub usunięta 
                 TrackedBalls[ball] = nil 
                 LastTouchTime[ball] = nil 
                 OriginalTransp[ball] = nil 
                 CleanupVisuals(ball) 
             end 
         end 
     end 
 end) 
   
 -- UI 
 local ReachToggle = MainTab:CreateToggle({  
    Name = "Włącz Multi-Reach (V13.1)",  
    CurrentValue = false,  
    Flag = "ReachToggle",  
    Callback = function(Value)   
       ReachEnabled = Value   
       if not Value then  
           for ball, _ in pairs(ActiveVisuals) do CleanupVisuals(ball) end 
       end 
    end,  
 })  
  
 -- Obsługa klawisza H 
 UserInputService.InputBegan:Connect(function(input, gameProcessed) 
     if not gameProcessed and input.KeyCode == Enum.KeyCode.H then 
         ReachEnabled = not ReachEnabled 
         ReachToggle:Set(ReachEnabled) -- Synchronizacja UI 
          
         Rayfield:Notify({ 
             Title = "Reach " .. (ReachEnabled and "WŁĄCZONY" or "WYŁĄCZONY"), 
             Content = "Przełączono klawiszem H.", 
             Duration = 2, 
         }) 
     end 
 end) 
  
 MainTab:CreateToggle({  
    Name = "Safe Mode (Nie kradnij piłki)",  
    CurrentValue = true,  
    Flag = "SafeModeToggle",  
    Callback = function(Value)   
       SafeModeEnabled = Value   
    end,  
 })  
  
 MainTab:CreateToggle({  
    Name = "Pokaż Prawdziwy Hitbox",  
    CurrentValue = true,  
    Flag = "VisualToggle",  
    Callback = function(Value)   
       VisualsEnabled = Value   
       if not Value then  
           for ball, _ in pairs(ActiveVisuals) do CleanupVisuals(ball) end 
       end 
    end,  
 })  
  
 MainTab:CreateToggle({  
    Name = "Ghost Ball (Przezroczysta piłka)",  
    CurrentValue = false,  
    Flag = "GhostBallToggle",  
    Callback = function(Value)   
       GhostBallEnabled = Value   
       if not Value then 
           for ball, transp in pairs(OriginalTransp) do 
               if ball and ball.Parent then ball.Transparency = transp end 
           end 
           OriginalTransp = {} 
       end 
    end,  
 })  
   
 MainTab:CreateSlider({  
    Name = "Zasięg (+23% na poziom)",  
    Range = {1, 10},  
    Increment = 1,  
    CurrentValue = 1,  
    Flag = "ReachLevel",  
    Callback = function(Value) ReachLevel = Value end,  
 })  
  
 MainTab:CreateSlider({  
    Name = "Przezroczystość Hitboxa",  
    Range = {0, 1},  
    Increment = 0.01,  
    CurrentValue = 0.98,  
    Flag = "VisualTransparency",  
    Callback = function(Value) HitboxTransparency = Value end,  
 })  
   
 task.spawn(function() 
     for _, obj in pairs(workspace:GetDescendants()) do 
         AddBall(obj) 
         if _ % 1000 == 0 then task.wait() end 
     end 
 end) 
  
 Rayfield:Notify({  
    Title = "SLPN V13.1 SUBTLE!",  
    Content = "Moc zmniejszona do 23%. Zasięg Safe Mode: 5.0.",  
    Duration = 5,  
 }) 
