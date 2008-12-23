--Copyright (c) 2008 Neil Richardson (nrich@iinet.net.au)
--
--Permission is hereby granted, free of charge, to any person obtaining a copy 
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights 
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
--copies of the Software, and to permit persons to whom the Software is 
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
--IN THE SOFTWARE.

module('Tempel', package.seeall)

local io = require('io')
local os = require('os')
local table = require('table')
local string = require('string')

local function uri_encode(str)
    str = string.gsub(str, '[^a-zA-Z0-9 *-._]', function(c)
        return string.format('%%%02x', tonumber(string.byte(c)))
    end)

    str = string.gsub(str, ' ', '+')

    return str
end

local function uri_decode(str)
    str = string.gsub(str, '+', ' ')
    str = string.gsub(str, '%%(%x%x)', function(h)
        return string.char(tonumber(h, 16))
    end)

    return str
end

local function html_encode(str)
    str = string.gsub(str, '.', function(c)
        return string.format('&#x%02X;', tonumber(string.byte(c)))
    end)
    return str
end

local function html_decode(str)
    str = string.gsub(str, '&#x(%X%X);', function(h)
        return string.char(tonumber(h, 16))
    end)
    return str
end

function Load(filename)
    local fh = assert(io.open(filename))

    local funcstr = ''
    for line in fh:lines() do
        if string.match(line, '^~') then
	    -- a line of Lua code
	    -- strip the first symbol and save the
	    -- rest for execution
            line = string.gsub(line, '^~(.*)$', '%1')
            funcstr = funcstr .. line .. '\n'
        elseif string.match(line, '^%s*#') or string.match(line, '^%s*%-%-')then
	    -- this line is a template comment
	    -- skip it for compilation
        else
	    -- this is template text, we'll want to do
	    -- value substitutions on it
            local subs = {}

            line = string.gsub(line, '${(.-)}', function(s)
		-- ${varname}, echo it back as plain text
                table.insert(subs, string.format('format(%s)', s))
                return '%s'
            end)

            line = string.gsub(line, '%%{(.-)}', function(s)
		-- %{varname}, echo back after URI encoding
                table.insert(subs, string.format('uri_encode(format(%s))', s))
                return '%s'
            end)

            line = string.gsub(line, '!{(.-)}', function(s)
		-- !{varname}, echo back after HTML entity encoding
                table.insert(subs, string.format('html_encode(format(%s))', s))
                return '%s'
            end)

	    line = line .. '\n'
            if table.maxn(subs) > 0 then
		-- echo back the line with a list of variables to substitute
                funcstr = funcstr .. string.format('echo(%q, %s)', line, table.concat(subs, ', ')) .. '\n'
            else
		-- not substitutions found, echo back the line
                funcstr = funcstr .. string.format('echo(%q)', line) .. '\n'
            end
        end
    end

    fh:close()

    local f = assert(loadstring(funcstr, filename))

    -- this is the function returned as the result
    -- the value of `vars' is the environment
    -- the constructed function executes under
    return function(vars)
	vars = vars or {}

	-- as above
	vars.uri_encode = uri_encode
	vars.html_encode = html_encode

	-- 'prints' a value into output
	-- supports format strings
        vars.echo = function(format, ...)
            print(string.format(format, ...))
        end

	-- returns the string version of v
	-- or '' if v is nil
        vars.format = function(v)
            if v == nil then
                v = ''
            end

            return tostring(v)
        end

	-- returns a substring of str
	-- starting at start for len characters
	-- if len is undefined assume we want
	-- start number of characters from the
	-- start of the string
	vars.substring = function(str, start, len)
	    if len == nil then
		len = start
		start = 1
	    end

	    return string.sub(str, start, len)
	end

	-- returns the length of a string
	-- in characters
	vars.length = function(str)
	    return string.len(tostring(str))
	end

	-- numerically walk over a table
	-- and returns the value of at each index
	-- and optionally index
	-- (ipairs in reverse)
        vars.each = function(array)
            local i = 0
	    array = array or {}

            return function()
                i = i + 1
                return array[i],i
            end
        end

	-- iterate the table and return 
	-- key/value pairs
	vars.pairs = function(hashtable)
	    hashtable = hashtable or {}

	    local k

	    return function()
		k = next(hashtable, k)

		if k == nil then
		    return nil
		end

		return k,hashtable[k]
	    end
	end

	-- include a file into the source of a template
	-- this is done at run time, not load time
        vars.include = function(filename)
            local f = assert(Load(filename))
            f(vars)
        end

        -- include a file of Lua source code
        -- into the template
        vars.require = function(filename)
            local f = assert(loadfile(filename))
            setfenv(f, vars)
            f()
        end

	-- return the uppercase version 
	-- of str
        vars.uppercase = function(str)
	    return string.upper(str)
        end

	-- return the lowercase version
	-- of str
	vars.lowercase = function(str)
	    return string.lower(str)
	end

	-- returns a timestamp 
	vars.timestamp = function(...)
	    return os.date(...)
	end

	-- replace all instances of `match' with `rep'
	-- in str
	vars.replace = function(str, match, rep)
	    return string.gsub(str, match, rep)
	end

	-- joins a table into a string
	vars.join = function(...)
	    return table.concat(...)
	end

	-- splits a string into a table
	vars.split = function(str, sep)
            local res = {}
            local offset = 1

            sep = sep or ''

            -- no seperator, explode string into characters
            if string.len(sep) == 0 then
                for char in string.gmatch(str, '.') do
                    table.insert(res, char)
                end

                return res
            end

            -- not matching the separator
            if not string.find(str, sep, 1, 1) then
                return {str}
            end

            if string.len(sep) == 1 then
                if sep == ' ' then
                    -- turn a single space into all whitespace
                    sep = '%s+'
                else
                    -- turn single chars into literals
                    -- in the match
                    sep = '%' .. sep
                end
            end

            local pat = '(.-)' .. sep .. '()'

            repeat
                local match,rem = string.match(str, pat, offset)

                if not match then
                    -- push remainder into results
                    table.insert(res, string.sub(str, offset))
                    break
                end

                table.insert(res, match)
                offset = rem
            until string.len(str) == 0

            return res
	end

        setfenv(f, vars)
        f()
    end
end

--
-- Tempel.lua
--
-- A templating library for Lua. Designed to be used to generate HTML from templates, but
-- can be used for any kind of templating.
--
-- 
--
-- Synopsis
--
-- require('Tempel')
--
-- func = Tempel.Load('/path/to/file.template')
--
-- replaces = {varname = 'Hello world!'}
-- func(replace)
--
--
--
-- Methods:
--
-- func = Tempel.Load(filename)
--   Loads the template from filename, parses it and returns a function. The returned function 
--   takes a single table which it uses to replace values inside the template definition.
--
--
--
-- Template Format:
--
-- If the first character of a line is a `~', the rest of the line will be a line if executable
-- Lua code. All other lines are assumed to be plain text and will be echoed directly (after 
-- substitutions).
-- 
-- Comments can be added to the templated either with '#' or '--'. All comments are removed
-- from the template output at loading time.
--
-- Template Substitutions:
--
-- Inside a plain text line of a template substitutions can be declared. There are 3 types of 
-- substitions:
--
--   ${varname} will echo the value of varname as plain text
--   %{varname} will echo the value of varname as a URI encoded string
--   !{varname} will echo the calue of varname as a string of hexedecimal HTML entities
--
-- String transformation functions can be used inside the the substitution declaration, for 
-- example:
--
--   ${uppercase(varname)}
--
-- will print the value of varname converted to uppercase as plain text.
--
--
-- Template Built-in Functions:
--
-- Several built-in functions are available from within the template. The functions are:
--
--   uri_str = uri_encode(str)
--      returns the URI encoded version of `str'
--
--   html_str = html_encode(str)
--	returns the HTML entity encoded version of `str'
--
--   echo(str, ...)
--	echoes values to the output buffer. `str' can be a plain string, or a
--	format string to be used in conjunction with the trailing arguments
--
--   str = format(str)
--	returns the string value of `str', or '' if `str' is nil
--
--   substr = substring(str, startpos, len)
--	returns a substring of str starting at `startpos' for `len' characters.
--	if `len' is undefined assume we want start number of characters from the 
--	start of the string.
--
--   len = length(str)
--	returns the length of `str' in characters
--
--   iter = each(table)
--      returns an iterator to be used in `for ... in ' which iterates
--      over table numerically.
--
--   iter = pairs(table)
--	returns an iterator to be used in `for ... in ' which iterates over
--	table by keyname/value
--
--   include(filename)
--	includes the file `filename' into the source of this template
--
--   require(filename)
--      loads the file `filename' as Lua source code inth this template
--
--   upper = uppercase(str)
--      returns the uppercase version of str
--
--   lower = lowercase(str)
--	returns the lowercase version of str
--
--   str = timestamp([format][,epoch])
--	returns a timestamp string based on the value of `format'. `format' should
--	be a format string compatible with the POSIX `strftime' function. `epoch'
--	is the unix epoch time to be formatted.
--	If `format' is not provided it defaults to `%c'
--	If `epoch' is not provied the current system time is used
--
--   newstr = replace(str, match, rep)
--	replace all instances of `match' with `rep' in `str'
--
--   str = join(table, joinstr)
--	joins all the values of `table' into a string separated by `joinstr'
--
--   table = split(str, seperator)
--	splits `str' into a table based split on `seperator'.
--	If `seperator' is '' or nil explodes `str' into a table of individual characters
