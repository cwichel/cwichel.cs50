--[[----------------------------------------------------------------------------
GD50 2022
Pong remake

-- Paddle Class --

Represents a paddle that can move up and down. Used in the main program to
deflect the ball back toward the opponent.
------------------------------------------------------------------------------]]

--[[
class is a library that allows us to represent anything in our game as code
objects, rather than keeping track of many disparate variables and methods
https://github.com/vrld/hump/blob/master/class.lua
]]
local Class = require "libs.class"

--[[
Paddle class declaration.
]]
Paddle = Class{}

--[[----------------------------------------------------------------------------
Initializes a paddle object.
This function require the paddle initial position.
]]
function Paddle:init(x, y)
  -- Position
  self.x  = x
  self.y  = y
  -- Speed
  self.dy = 0
end

--[[----------------------------------------------------------------------------
Updates the paddle position based on the current speed definition.
Note: This function is meant to be called in the `love.update` function.
]]
function Paddle:update(dt)
  -- Position update
  new_y = self.y + (self.dy * dt)
  -- Position limitations
  if (self.dy < 0) then
    self.y = math.max(0, new_y)
  else
    self.y = math.min(VIRTUAL_HEIGHT - PADDLE_HEIGHT, new_y)
  end
end

--[[----------------------------------------------------------------------------
Draws the paddle on the screen.
Note: This function is meant to be called on the `love.draw` function.
]]
function Paddle:render()
  love.graphics.rectangle("fill", self.x, self.y, PADDLE_WIDTH, PADDLE_HEIGHT)
end
