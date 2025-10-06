# nvim-dap-haxe

A [nvim-dap](https://github.com/mfussenegger/nvim-dap) extension providing configurations for launching Haxe debug targets.

## Features

- Sets up DAP adapters for Haxe's `eval` interpreter, HashLink, and JavaScript (node).
- Provides launch configurations for various Haxe targets and workflows.
- Automatic detection of program files (`.hl`, `.js`).
- Parsing of `.hxml` files to generate DAP configurations on the fly.
- Dynamic argument generation for `eval` adapter (e.g., debug current function or file).

## Installation

Install with your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "tong/nvim-dap-haxe",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
        require("dap-haxe").setup({
            -- Your custom options here
        })
    end,
}
```

## Configuration

You can override the default settings by passing an options table to the `setup` function.

Here is an example of how to specify the path to your main JavaScript file:

```lua
require("dap-haxe").setup({
    javascript = {
        -- If not specified, the plugin will search for *.js files in your workspace.
        program = "/path/to/your/main.js",
    },
})
```

## Usage

This plugin provides several debug configurations under the `haxe` and `hxml` types. When you start debugging (e.g., with `require("dap").continue()`), you will be able to choose from the following configurations:

### `haxe` type

- **`eval:function_call`**: Runs the current function under the cursor using Haxe's interpreter.
- **`eval:run_file`**: Runs the current Haxe file using Haxe's interpreter.
- **`hashlink`**: Launches a HashLink application. It will search for `.hl` files in your workspace and prompt you to choose one if multiple are found.
- **`javascript`**: Launches a JavaScript application using Node.js. It searches for `.js` files with a corresponding `.js.map` source map file.
- **`haxe:hxml`**: Prompts you to select an `.hxml` file to create a launch configuration from.

### `hxml` type

- **`hxml:current`**: Creates a launch configuration from the currently open `.hxml` file.

