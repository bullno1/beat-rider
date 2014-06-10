local extraPath="./src/?.lua;./src/?/init.lua"
package.path=extraPath..';'..package.path

require "luacov"
assert=require "luassert"

local glider = require "glider"
glider.start{}
