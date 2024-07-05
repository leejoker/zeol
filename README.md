# ZEol

This is a tool for changing File Eol. Just like dos2unix.

## Usage

```shell

$ zeol --help
Help Message: 
-h, --help                Display this help and exit.
-p, --path        <str>   source file or dir path, example --path "D:\zig\README.md"
-t, --type        <str>   target eol type, example: eoler --type LF
-x, --extension   <str>   file extension, example: zig
-h, --hidden_enable       available to change hidden dir and file
<str>                     same with --path and use OS eol as default
```

## TODO

- [ ] use a config file to set includes and excludes(just like git config)  
- [x] support relative path
