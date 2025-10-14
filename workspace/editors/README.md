sync vscode config
```shell
cp -f "$HOME/.config/Code/User/settings.json" "editors/vscode/"
cp -f "$HOME/.config/Code/User/keybindings.json" "editors/vscode/"
cp -f "$HOME/.config/Code/User/tasks.json" "editors/vscode/"
cp -f "$HOME/.config/Code/User/mcp.json" "editors/vscode/"
cp -r "$HOME/.config/Code/User/snippets" "editors/vscode"
```

```shell
cp -f "editors/vscode/settings.json" "$HOME/.config/Code/User/"
cp -f "editors/vscode/keybindings.json" "$HOME/.config/Code/User/"
cp -f "editors/vscode/tasks.json" "$HOME/.config/Code/User/"
cp -f "editors/vscode/mcp.json" "$HOME/.config/Code/User/"
cp -r "editors/vscode/snippets" "$HOME/.config/Code/User"
```

```shell
diff "$HOME/.config/Code/User/settings.json" "editors/vscode/settings.json"
diff "$HOME/.config/Code/User/keybindings.json" "editors/vscode/keybindings.json"
diff "$HOME/.config/Code/User/tasks.json" "editors/vscode/tasks.json"
diff "$HOME/.config/Code/User/mcp.json" "editors/vscode/mcp.json"
```
