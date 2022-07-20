--[[----------------------------------------------------------------------------
GD50 2022
Pong remake

-- Main Program --

Originally programmed by Atari in 1972. Features two paddles, controlled by
players, with the goal of getting the ball past your opponent's edge. First to
10 points wins.

This version is built to more closely resemble the NES than the original Pong
machines or the Atari 2600 in terms of resolution, though in widescreen (16:9)
so it looks nicer on modern systems.
------------------------------------------------------------------------------]]

--[[
push is a library that will allow us to draw our game at a virtual resolution,
instead of however large our window is; used to provide a more retro aesthetic
https://github.com/Ulydev/push/blob/master/push.lua
]]
local push = require "libs.push"

--[[
Internal classes and utilities.
]]
require "Ball"
require "Paddle"

--[[
Window resolution configuration
]]
WINDOW_WIDTH    = 1280
WINDOW_HEIGHT   = 720
VIRTUAL_WIDTH   = 432
VIRTUAL_HEIGHT  = 243

--[[
Game tunables
]]
BALL_SIZE       = 4
PADDLE_WIDTH    = 5
PADDLE_HEIGHT   = 20
PADDLE_SPEED    = 200
SPEED_FACTOR    = 1.03
WINNING_SCORE   = 5

--[[----------------------------------------------------------------------------
Runs when the game first starts up, only once; used to initialize the game
]]
function love.load()
  -- Set the window title
  love.window.setTitle("Pong")

  -- Initializes the random generaton.
  math.randomseed(os.time())

  --[[
  Configure the fonts using a procided asset to give a more "retro-looking"
  aspect to the game.
  ]]
  fonts = {
    ["small"] = love.graphics.newFont("assets/fonts/retro.ttf", 8),
    ["large"] = love.graphics.newFont("assets/fonts/retro.ttf", 16),
    ["score"] = love.graphics.newFont("assets/fonts/retro.ttf", 32)
  }
  love.graphics.setFont(fonts["small"])

  --[[
  Setup sound effects; later we can just index this table and call each entry
  on the `play` method.
  ]]
  sounds = {
    ["hit_paddle"]  = love.audio.newSource("assets/sounds/hit_paddle.wav", "static"),
    ["hit_wall"]    = love.audio.newSource("assets/sounds/hit_wall.wav", "static"),
    ["score"]       = love.audio.newSource("assets/sounds/score.wav", "static")
  }

  --[[
  Use nearest-neighbor filtering on upscaling and downscaling to prevent
  blurring of text and graphics and initialize the virtual resolution to resize
  the pixels to the desired ratio.
  ]]
  love.graphics.setDefaultFilter("nearest", "nearest")
  push:setupScreen(
    VIRTUAL_WIDTH,  VIRTUAL_HEIGHT,
    WINDOW_WIDTH,   WINDOW_HEIGHT,
    {
      fullscreen  = false,
      resizable   = true,
      vsync       = true
    })

  -- Initializes the player paddles and tha ball
  ball    = Ball(BALL_SIZE)
  player1 = Paddle(10, 30)
  player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30)

  -- Initializes the game state
  score1  = 0
  score2  = 0
  server  = 1
  winner  = 1
  state   = "start"

end

--[[----------------------------------------------------------------------------
Resize logic.
Push does this for us, we only need to pass the new dimensions.
]]
function love.resize(w, h)
  push:resize(w, h)
end

--[[----------------------------------------------------------------------------
Called every frame by LÖVE2D, with "dt" passed in, our delta in seconds since
the last frame.
]]
function love.update(dt)
  -- Player movement update ---------------------
  -- Player 1 movement
  if love.keyboard.isDown("w") or love.keyboard.isDown("s") then
    player1.dy = love.keyboard.isDown("w") and -PADDLE_SPEED or PADDLE_SPEED
  else
    player1.dy = 0
  end
  player1:update(dt)

  -- Player 2 movement
  if love.keyboard.isDown("up") or love.keyboard.isDown("down") then
    player2.dy = love.keyboard.isDown("up") and -PADDLE_SPEED or PADDLE_SPEED
  else
    player2.dy = 0
  end
  player2:update(dt)

  -- Ball movement update -----------------------
  if state == "serve" then
    -- Define the new ball start velocity based on last server
    aux_dx  = math.random(140, 200)
    ball.dx = (server == 1) and aux_dx or -aux_dx
    ball.dy = math.random(-50, 50)

  elseif state == "play" then
    -- Detect and handle collision with a player
    if ball:collides(player1) or ball:collides(player2) then
      -- Reverse X velocity and increase it a little
      ball.x  = ball:collides(player1) and (player1.x + PADDLE_WIDTH) or (player2.x - BALL_SIZE)
      ball.dx = -SPEED_FACTOR * ball.dx

      -- Keep Y velocity direction but randomize it a little
      new_dy  = math.random(10, 150)
      ball.dy = (ball.dy < 0) and -new_dy or new_dy

      -- Reproduce sound
      sounds["hit_paddle"]:play()

    end

    -- Detect upper/lower boundaries collision and reverse if required
    if (ball.y <= 0) or (ball.y >= (VIRTUAL_HEIGHT - BALL_SIZE)) then
      -- Compute new speed
      ball.y  = (ball.y <= 0) and 0 or (VIRTUAL_HEIGHT - BALL_SIZE)
      ball.dy = -ball.dy

      -- Reproduce sound
      sounds["hit_wall"]:play()

    end

    -- Detect player score and reset --------------
    if (ball.x <= 0) or (ball.x >= VIRTUAL_WIDTH) then
      -- Scored, need to serve
      if (ball.x <= 0) then
        -- player 2 scored
        server = 1
        score2 = score2 + 1
      else
        -- player 1 scored
        server = 2
        score1 = score1 + 1
      end

      -- Reproduce sound
      sounds['score']:play()

      -- Check end of game
      if (score1 == WINNING_SCORE) or (score2 == WINNING_SCORE) then
        -- Finish game
        state  = "done"
        winner = (score1 == WINNING_SCORE) and 1 or 2
      else
        -- Continue
        state  = "serve"
      end

      -- Reset ball
      ball:reset()
    else
      -- Perform actual update
      ball:update(dt)

    end
  end
end

--[[----------------------------------------------------------------------------
Called after update by LÖVE2D, used to draw anything to the screen, updated or
otherwise
]]
function love.draw()
  -- Start rendering on virtual screen --------------------
  push:apply("start")

  -- Clear the screen with a given RGB color, alpha 255
  love.graphics.clear(40/255, 45/255, 52/255, 255/255)

  -- Display score
  displayScore()

  -- Display state info
  if state == "start" then
    love.graphics.setFont(fonts["small"])
    love.graphics.printf("Welcome to Pong!", 0, 10, VIRTUAL_WIDTH, "center")
    love.graphics.printf("Press Enter to begin!", 0, 20, VIRTUAL_WIDTH, "center")

  elseif state == "serve" then
    love.graphics.setFont(fonts["small"])
    love.graphics.printf("Player " .. tostring(server) .. "'s serves!", 0, 10, VIRTUAL_WIDTH, "center")
    love.graphics.printf("Press Enter to serve!", 0, 20, VIRTUAL_WIDTH, "center")

  elseif state == "play" then
    -- No UI display

  elseif state == "done" then
    love.graphics.setFont(fonts["large"])
    love.graphics.printf("Player " .. tostring(winner) .. " wins!", 0, 10, VIRTUAL_WIDTH, "center")
    love.graphics.setFont(fonts["small"])
    love.graphics.printf("Press Enter to restart!", 0, 30, VIRTUAL_WIDTH, "center")

  end

  -- Render paddles and ball
  player1:render()
  player2:render()
  ball:render()

  -- Show FPS
  displayFPS()

  -- Stop rendering on virtual screen ---------------------
  push:apply("end")
end

--[[----------------------------------------------------------------------------
Keyboard handling, called by LÖVE2D each frame; passes in the key we pressed so
we can access.
Note: Keys can be accessed by their string name.
]]
function love.keypressed(key, scancode, isrepeat)
  -- Exit game using escape or Q keys
  if (key == "q") or (key == "escape") then
    love.event.quit()

  -- Start / reset the play
  elseif (key == "enter") or (key == "return") then
    if state == "start" then
      -- Just started, serve!
      state = "serve"

    elseif state == "serve" then
      -- Just served, play!
      state = "play"

    elseif state == 'done' then
      -- Game finished, reset!
      state  = "serve"
      server = (winner == 1) and 2 or 1
      score1 = 0
      score2 = 0
      ball:reset()

    end
  end
end

--[[----------------------------------------------------------------------------
Renders the current FPS.
Note: This function is meant to be called on the `love.draw` function.
]]
function displayFPS()
  love.graphics.setFont(fonts["small"])
  love.graphics.setColor(0, 255, 0, 255)
  love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
end

--[[----------------------------------------------------------------------------
Draws the score into the screen.
Note: This function is meant to be called on the `love.draw` function.
]]
function displayScore()
  love.graphics.setFont(fonts["score"])
  love.graphics.printf(tostring(score1), (VIRTUAL_WIDTH / 2) - 50, (VIRTUAL_HEIGHT / 3), 50, "center")
  love.graphics.printf(tostring(score2), (VIRTUAL_WIDTH / 2), (VIRTUAL_HEIGHT / 3), 50, "center")
end
