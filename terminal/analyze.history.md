- Count frequency of command.

```shell
awk -F ';' '{print $2}' $HISTFILE | awk '{print $1}' | sort | uniq -c | sort -nr
```

- Analyze particular command, for example `git`

```shell
awk -F ';' '{print $2}' $HISTFILE | grep -E "git .*" | awk '{print $1, $2}' | sort | uniq -c | sort -nr
```
