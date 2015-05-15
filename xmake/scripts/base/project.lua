--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        project.lua
--

-- load modules
local utils = require("base/utils")

-- enter project 
local _PROJECT = {}
local _MAINENV = getfenv()
setmetatable(_PROJECT, {__index = _G})  
setfenv(1, _PROJECT)

-- init the current scope
local current = nil

-- configure scope end
function scopend()

    -- check
    assert(current)

    -- leave the current scope
    current = current._PARENT
end

-- configure platforms
function plarforms(...)

    -- check
    assert(current)

    -- init platforms
    current._PLATFORMS = current._PLATFORMS or {}

    -- init scope
    local scope = {}

    -- configure all platforms
    local arg = arg or {...}
    for _, name in ipairs(arg) do

        -- check
        if current._PLATFORMS[name] then
            -- error
            utils.error("the platform: %s has been defined repeatly!", name)
            assert(false) 
        end

        -- init the platform scope
        current._PLATFORMS[name] = scope

    end

    -- enter scope
    local parent = current
    current = scope
    current._PARENT = parent
end

-- configure target
function target(name)

    -- check
    assert(name and current)

    -- init targets
    current._TARGETS = current._TARGETS or {}

    -- init target scope
    current._TARGETS[name] = {}

    -- enter target scope
    local parent = current
    current = current._TARGETS[name]
    current._PARENT = parent
end

-- configure project
function project(name)

    -- check
    assert(name)

    -- init the root scope, must be only one project
    if not _CONFIGS then
        _CONFIGS = {}
    else
        -- error
        utils.error("the project: %s is redundant!", name)
        return
    end

    -- init the project name
    _CONFIGS.name = name

    -- init the current scope
    current = _CONFIGS
    current._PARENT = nil

end

-- preprocess value
function _preprocess(value)

    -- the value is string?
    if type(value) == "string" then

        -- replace $(variable)
        value = value:gsub("%$%((.*)%)",    function (v) 
                                                if v == "buildir" then
                                                    -- TODO
                                                    return xmake._CONFIGS.all.output
                                                elseif v == "projectdir" then
                                                    return xmake._OPTIONS.project
                                                end
                                                return v 
                                            end)
    end

    -- ok
    return value
end

-- register configures
function _register(names)

    -- check
    assert(_PROJECT)
    assert(names and type(names) == "table")

    -- register all configures
    for _, name in ipairs(names) do

        -- register the configure 
        _PROJECT[name] = _PROJECT[name] or function(...)

            -- check
            assert(current)

            -- init ldflags
            current[name] = current[name] or {}

            -- get arguments
            local arg = arg or {...}
            if table.getn(arg) == 0 then
                -- no argument
                current[name] = nil
            elseif table.getn(arg) == 1 then
                -- save only one argument
                current[name] = _preprocess(arg[1])
            else
                -- save all arguments
                for i, v in ipairs(arg) do
                    current[name][i] = _preprocess(v)
                end
            end
        end
    end
end

-- load xproj
function loadxproj(file)

    -- check
    assert(file)

    -- load and execute the xmake.xproj
    local script = preprocessor.load_xproj(file)
    if script then

        -- init the project envirnoment
        setfenv(script, _PROJECT)

        -- execute it
        local ok, err = pcall(script)
        if not ok then
            -- error
            return false, err
        end
    else
        -- error
        return false, string.format("load %s failed!", file)
    end

    -- ok
    return true
end

-- dump all configures
function dump()
    
    -- dump
    if xmake._OPTIONS.verbose then
        utils.dump(xmake._PROJECT._CONFIGS, "", "_PARENT")
    end
   
end

-- register all configures
_register   {   "kind"
            ,   "deps"
            ,   "files"
            ,   "links" 
            ,   "mflags" 
            ,   "headers" 
            ,   "headerdir" 
            ,   "targetdir" 
            ,   "objectdir" 
            ,   "linkdirs" 
            ,   "includedirs" 
            ,   "cflags" 
            ,   "cxxflags" 
            ,   "ldflags" 
            ,   "mxflags" 
            ,   "defines"} 


-- leave project 
setfenv(1, _MAINENV)
return _PROJECT
