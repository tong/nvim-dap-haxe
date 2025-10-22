# nvim-dap-haxe

A [nvim-dap](https://github.com/mfussenegger/nvim-dap) extension providing configurations for launching Haxe debug targets.

## Usage

This plugin provides several debug configurations under the `haxe` and `hxml` types. When you start debugging (e.g., with `require("dap").continue()`), you will be able to choose from the following configurations:

### Configurations

#### `haxe` type

- **`haxe:hxml`**: Prompts you to select an `.hxml` file to create a launch configuration from.
- **`haxe:call`**: Calls the current function under the cursor using `--macro <Module.function()>`.
- **`haxe:run`**: Runs the current haxe file using `--run <Module>`.
- **`hashlink`**: Launches a HashLink application. It will search for `.hl` files in your workspace and prompt you to choose one if multiple are found.
- **`javascript`**: Launches a JavaScript application using Node.js. It searches for `.js` files with a corresponding `.js.map` source map file.

#### `hxml` type

- **`hxml:current`**: Creates a launch configuration from the currently open `.hxml` file.
