--[[----------------------------------------------------------------------------
GD50 2022
Pong remake

-- Ball Class --

Represents a ball which will bounce back and forth between paddles and walls
until it passes a left or right boundary of the screen, scoring a point for the
opponent.
------------------------------------------------------------------------------]]

--[[
class is a library that allows us to represent anything in our game as code
objects, rather than keeping track of many disparate variables and methods
https://github.com/vrld/hump/blob/master/class.lua
]]
local Class = require "libs.class"

--[[
Ball class declaration.
]]
Ball = Class{}

--[[----------------------------------------------------------------------------
Initializes a ball object.
]]
function Ball:init()
  self:reset()
end

--[[----------------------------------------------------------------------------
Updates the ball position based on the current speed.
Note: This function is meant to be called in the `love.update` function.
]]
function Ball:update(dt)
  self.x = self.x + (self.dx * dt)
  self.y = self.y + (self.dy * dt)
end

--[[----------------------------------------------------------------------------
Draws the ball on the screen.
Note: This function is meant to be called on the `love.draw` function.
]]
function Ball:render()
  love.graphics.rectangle('fill', self.x, self.y, BALL_SIZE, BALL_SIZE)
end

--[[----------------------------------------------------------------------------
Places the ball in the middle of the screen, with an initial random velocity on
both X and Y axis.
]]
function Ball:reset()
  -- Reset position
  self.x  = (VIRTUAL_WIDTH / 2)  - (BALL_SIZE / 2)
  self.y  = (VIRTUAL_HEIGHT / 2) - (BALL_SIZE / 2)
  -- Reset speed
  self.dx = 0
  self.dy = 0
end

--[[----------------------------------------------------------------------------
Checks if the ball is colliding with a paddle
]]
function Ball:collides(paddle)
  -- Check if there is a possibility of collision on the X axis
  if (self.x > (paddle.x + PADDLE_WIDTH)) or (paddle.x > (self.x + BALL_SIZE)) then
    return false
  end

  -- Check if there is a possibility of collision on the Y axis
  if (self.y > (paddle.y + PADDLE_HEIGHT)) or (paddle.y > (self.y + BALL_SIZE)) then
    return false
  end

  -- If none of the above are true then we are in a collision
  return true
end
