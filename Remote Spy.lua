local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

local localPlayer = players.LocalPlayer
local screenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 420, 0, 420)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BorderSizePixel = 5
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Active = true

local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BitFX - Remote Spy"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.FredokaOne

local separator = Instance.new("Frame", mainFrame)
separator.Size = UDim2.new(1, 0, 0, 2)
separator.Position = UDim2.new(0, 0, 0, 30)
separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
separator.BorderSizePixel = 0

local remoteListFrame = Instance.new("ScrollingFrame", mainFrame)
remoteListFrame.Size = UDim2.new(1, -10, 0.6, -40)
remoteListFrame.Position = UDim2.new(0, 5, 0, 35)
remoteListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
remoteListFrame.BorderSizePixel = 0
remoteListFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
remoteListFrame.ScrollBarThickness = 6

local codeBox = Instance.new("TextBox", mainFrame)
codeBox.Size = UDim2.new(1, -10, 0.3, -10)
codeBox.Position = UDim2.new(0, 5, 0.68, 0)
codeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
codeBox.TextColor3 = Color3.fromRGB(200, 200, 200)
codeBox.TextScaled = true
codeBox.ClearTextOnFocus = false
codeBox.Font = Enum.Font.Code
codeBox.Text = "Selected remote code will appear here"
codeBox.TextWrapped = true
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top

local copyButton = Instance.new("TextButton", mainFrame)
copyButton.Size = UDim2.new(0.45, -5, 0, 30)
copyButton.Position = UDim2.new(0.05, 0, 1, -40)
copyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
copyButton.Text = "Copy Code"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextScaled = true
copyButton.Font = Enum.Font.FredokaOne

local blockButton = Instance.new("TextButton", mainFrame)
blockButton.Size = UDim2.new(0.45, -5, 0, 30)
blockButton.Position = UDim2.new(0.5, 5, 1, -40)
blockButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
blockButton.Text = "Block Remote"
blockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
blockButton.TextScaled = true
blockButton.Font = Enum.Font.FredokaOne

local remoteRegistry = {}
local blockedRemotes = {}
local selectedLabel

local function tween(object, color, time)
	tweenService:Create(object, TweenInfo.new(time or 0.2), {BackgroundColor3 = color}):Play()
end

local function animateHover(button)
	local originalColor = button.BackgroundColor3
	local hoverColor = Color3.fromRGB(70, 70, 70)
	local clickColor = Color3.fromRGB(100, 100, 100)
	button.MouseEnter:Connect(function() tween(button, hoverColor) end)
	button.MouseLeave:Connect(function() tween(button, originalColor) end)
	button.MouseButton1Down:Connect(function() tween(button, clickColor, 0.1) end)
	button.MouseButton1Up:Connect(function() tween(button, hoverColor, 0.1) end)
end

animateHover(copyButton)
animateHover(blockButton)

local function formatValue(value)
	if typeof(value) == "string" then
		return string.format("%q", value)
	elseif typeof(value) == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", value.X, value.Y, value.Z)
	elseif typeof(value) == "Vector2" then
		return string.format("Vector2.new(%s, %s)", value.X, value.Y)
	elseif typeof(value) == "CFrame" then
		local components = {value:GetComponents()}
		return string.format("CFrame.new(%s)", table.concat(components, ", "))
	elseif typeof(value) == "Color3" then
		return string.format("Color3.fromRGB(%d, %d, %d)", value.R * 255, value.G * 255, value.B * 255)
	elseif typeof(value) == "Instance" then
		return string.format("game:GetService(%q):FindFirstChild(%q)", value.Service or value.ClassName, value.Name)
	else
		return tostring(value)
	end
end

local function generateCode(remote, args)
	local code = ""
	local remoteName = remote:GetFullName()

	if #args > 1 then
		code = "local Arguments = {\n"
		for i, v in ipairs(args) do
			code ..= string.format("    [%d] = %s,\n", i, formatValue(v))
		end
		code ..= "}\n"
		local callType = remote:IsA("RemoteEvent") and ":FireServer(unpack(Arguments))" or ":InvokeServer(unpack(Arguments))"
		code ..= string.format("%s%s", remoteName, callType)
	else
		local argText = args[1] and formatValue(args[1]) or ""
		local callType = remote:IsA("RemoteEvent") and ":FireServer(" or ":InvokeServer("
		code = string.format("%s%s%s)", remoteName, callType, argText)
	end

	return code
end

local function showRemote(remote, args)
	if blockedRemotes[remote] then return end
	local fullName = remote:GetFullName()
	if remoteRegistry[remote] then
		remoteRegistry[remote].count += 1
		remoteRegistry[remote].label.Text = string.format("[%d] %s", remoteRegistry[remote].count, fullName)
		return
	end
	local label = Instance.new("TextButton", remoteListFrame)
	label.Size = UDim2.new(1, -10, 0, 30)
	label.Position = UDim2.new(0, 5, 0, (#remoteListFrame:GetChildren() - 1) * 35)
	label.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	label.Text = string.format("[%d] %s", 1, fullName)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.FredokaOne
	local originalColor = label.BackgroundColor3
	local hoverColor = Color3.fromRGB(70, 70, 70)
	local clickColor = Color3.fromRGB(100, 100, 100)
	label.MouseEnter:Connect(function() tween(label, hoverColor) end)
	label.MouseLeave:Connect(function()
		if label ~= selectedLabel then tween(label, originalColor) end
	end)
	label.MouseButton1Down:Connect(function() tween(label, clickColor) end)
	label.MouseButton1Up:Connect(function() tween(label, hoverColor) end)
	label.MouseButton1Click:Connect(function()
		if selectedLabel then selectedLabel.BackgroundColor3 = originalColor end
		selectedLabel = label
		label.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
		local code = generateCode(remote, args)
		codeBox.Text = code
	end)
	remoteRegistry[remote] = {count = 1, label = label, args = args}
end

local function hookRemote(remote)
	if blockedRemotes[remote] then return end
	if remote:IsA("RemoteEvent") then
		remote.OnClientEvent:Connect(function(...)
			showRemote(remote, {...})
		end)
	elseif remote:IsA("RemoteFunction") then
		local oldInvoke = remote.OnClientInvoke
		remote.OnClientInvoke = function(...)
			showRemote(remote, {...})
			if oldInvoke then
				return oldInvoke(...)
			end
		end
	end
end

for _, remote in ipairs(game:GetDescendants()) do
	if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
		hookRemote(remote)
	end
end

game.DescendantAdded:Connect(function(instance)
	if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then
		hookRemote(instance)
	end
end)

copyButton.MouseButton1Click:Connect(function()
	if codeBox.Text and codeBox.Text ~= "" then
		setclipboard(codeBox.Text)
	end
end)

blockButton.MouseButton1Click:Connect(function()
	if not selectedLabel then return end
	local selectedRemote
	for remote, data in pairs(remoteRegistry) do
		if data.label == selectedLabel then
			selectedRemote = remote
			break
		end
	end
	if selectedRemote then
		blockedRemotes[selectedRemote] = true
		selectedLabel.Text = "[BLOCKED] " .. selectedLabel.Text
		tween(selectedLabel, Color3.fromRGB(120, 30, 30))
		remoteRegistry[selectedRemote] = nil
		codeBox.Text = "Blocked remote: " .. selectedRemote:GetFullName()
	end
end)

local dragging, dragInput, dragStart, startPosition
mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPosition = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

userInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
	end
end)

task.spawn(function()
	while true do
		tweenService:Create(mainFrame, TweenInfo.new(2), {BorderColor3 = Color3.new(math.random(), math.random(), math.random())}):Play()
		task.wait(2)
	end
end)

for _, child in ipairs(mainFrame:GetChildren()) do
	if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") then
		Instance.new("UICorner", child).CornerRadius = UDim.new(0, 10)
	end
end