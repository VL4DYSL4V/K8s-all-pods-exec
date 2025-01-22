# K8s All Pods Exec

This script executes the command that you provide in every container of every pod in every namespace.
This is particularly useful when checking which containers run as root.
The table is sortable by all columns, the TXT is easily grep-able

## Note
It requires `jq` as a dependency

## Example usage:

```bash
# In HTML format
$ ./k8s-pods-all-exec.sh --command='id' --output-format=html --output-file=./k8s-pods-all-exec-result.html

In TXT format
$ ./k8s-pods-all-exec.sh --command='id' --output-format=txt --output-file=./k8s-pods-all-exec-result.txt
```
