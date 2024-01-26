# Nvim lua log function

```lua
local log = function(value)
    local log_file_path = '/home/andrejf/.local/state/nvim/log'
    local log_file = io.open(log_file_path, "a")
    io.output(log_file)
    io.write("DEBUG: ")
    io.write(tostring(value).."\n")
    io.close(log_file)
end
```

# Ideas

- Bufferline show only unsaved tabs or tabs with errors
- Vim surround keep selection after surround/replace surround
