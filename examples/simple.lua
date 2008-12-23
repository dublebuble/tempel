#!/usr/bin/lua

local Tempel = require('Tempel')

-- load the template from `simple.ttl'
local f = Tempel.Load('simple.ttl')

-- build a dataset
local replace = {
    title = 'Test Page',
    people = {
	{	
	    id = 12345,
	    name = 'Fred Bloggs',
	    email = 'FREDB@company.com'
	},
	{	
	    id = 9876,
	    name = 'John Smith',
	    email = 'jsmith@company.com'
	},
    }
}

-- run the function `f', substituting
-- values from the table `replace'
f(replace)
