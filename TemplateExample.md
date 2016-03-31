
```
<html>
    # comments can be added in shell format
    -- or in Lua format

    # all comments are removed from the 
    # output buffer at template load time

    <head>
        # Fallback to default if 'title'
        # is not set to be replaced
        <title>${title or 'Site Name'}</title>
    </head>

    <body>
        # lines beginning with `~' 
        # are executed as normal Lua code
~       for person in each(people) do
            <p>
                ID is %{person.id}<br />                   # URI encode
                Name is !{person.name}<br />               # HTML encode
                Email is ${lowercase(person.email)}<br />  # convert to uppercase 
            </p>

            <hr />
~       end
    </body>
</html>
```