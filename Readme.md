# Tempel.lua #

A templating library for Lua. Designed to be used to generate HTML from templates, but can be used for any kind of templating.

# Details #

## Synopsis ##

```
require('Tempel')

func = Tempel.Load('/path/to/file.template')

replaces = {varname = 'Hello world!'}
func(replace)
```


## Methods ##

#### func = Tempel.Load(filename) ####

Loads the template from filename, parses it and returns a function. The returned function takes a single table which it uses to replace values inside the template definition.

## Template Format ##

If the first character of a line is a `~`, the rest of the line will be a line if executable Lua code. All other lines are assumed to be plain text and will be echoed directly (after substitutions).

Comments can be added to the templated either with `#` or `--`. All comments are removed from the template output at loading time.

## Template Substitutions ##

Inside a plain text line of a template substitutions can be declared. There are 3 types of
substitions:

  * ${varname} will echo the value of varname as plain text
  * %{varname} will echo the value of varname as a URI encoded string
  * !{varname} will echo the calue of varname as a string of hexadecimal HTML entities

String transformation functions can be used inside the the substitution declaration, for
example:

```
  ${uppercase(varname)}
```

will print the value of `varname` converted to uppercase as plain text.

## Template Built-in Functions ##

Several built-in functions are available from within the template. The functions are:

#### uri\_str = uri\_encode(str) ####

returns the URI encoded version of `str`

#### html\_str = html\_encode(str) ####

returns the HTML entity encoded version of `str`

#### echo(str, ...) ####

echoes values to the output buffer. `str` can be a plain string, or a format string to be used in conjunction with the trailing arguments

#### str = format(str) ####

returns the string value of `str`, or `''` if `str` is nil

#### substr = substring(str, startpos, len) ####

returns a substring of `str` starting at `startpos` for `len` characters. if `len` is undefined assume we want start number of characters from the start of the string.

#### len = length(str) ####

returns the length of `str` in characters

#### iter = each(table) ####

returns an iterator to be used in `for ... in` which iterates over table numerically.

#### iter = pairs(table) ####

returns an iterator to be used in `for ... in` which iterates over table by keyname/value

#### include(filename) ####

includes the file `filename` into the source of this template

#### require(filename) ####

loads the file `filename` as Lua source code in this template

#### upper = uppercase(str) ####

returns the uppercase version of `str`

#### lower = lowercase(str) ####

returns the lowercase version of `str`

#### str = timestamp([format](format.md)[,epoch]) ####

returns a timestamp string based on the value of `format`. `format` should be a format string compatible with the POSIX `strftime` function. `epoch` is the UNIX epoch time to be formatted.

If `format` is not provided it defaults to `%c`
If `epoch` is not provided the current system time is used

#### newstr = replace(str, match, rep) ####

replace all instances of `match` with `rep` in `str`

#### str = join(table, joinstr) ####

joins all the values of `table` into a string separated by `joinstr`

#### table = split(str, seperator) ####

splits `str` into a table based split on `seperator`. If `seperator` is `''` or `nil` explodes `str` into a table of individual characters