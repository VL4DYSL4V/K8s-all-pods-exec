#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Default parameters
OUTPUT_FILE="results.txt"
OUTPUT_FORMAT="txt"
COMMAND="id"

usage() {
  echo -e "Usage: $0 [--output-file=FILE] [--output-format=txt|html] [--command=COMMAND]"
  echo -e "\nOptions:"
  echo -e "  --output-file=FILE       Specify the output file name (default: results.txt)"
  echo -e "  --output-format=FORMAT   Specify the output format: txt or html (default: txt)"
  echo -e "  --command=COMMAND        Specify the command to execute in containers (default: 'id -u')"
  echo -e "  --help                   Show this help message and exit"
}

initialize_txt_output() {
  local cluster_info=$1
  local timestamp=$2
  local command=$3
  local output_file=$4

  echo "Cluster Info: $cluster_info" > "$output_file"
  echo "Timestamp: $timestamp" >> "$output_file"
  echo "Executed Command: $command" >> "$output_file"
  echo -e "\nNamespace,Pod,Container,Command Result" >> "$output_file"
}

initialize_html_output() {
  local cluster_info=$1
  local timestamp=$2
  local command=$3
  local output_file=$4

  echo "<html><head><title>K8s Container Report</title>" > "$output_file"
  echo "<style>" >> "$output_file"
  echo "body { font-family: Arial, sans-serif; margin: 20px; }" >> "$output_file"
  echo "h1 { text-align: center; }" >> "$output_file"
  echo "table { margin: auto; border-collapse: collapse; width: 80%; }" >> "$output_file"
  echo "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }" >> "$output_file"
  echo "th { background-color: #f2f2f2; cursor: pointer; }" >> "$output_file"
  echo "</style>" >> "$output_file"
  echo "<script>" >> "$output_file"
  echo "function sortTable(n) {" >> "$output_file"
  echo "  var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;" >> "$output_file"
  echo "  table = document.getElementById('k8sTable');" >> "$output_file"
  echo "  switching = true; dir = 'asc';" >> "$output_file"
  echo "  while (switching) {" >> "$output_file"
  echo "    switching = false; rows = table.rows;" >> "$output_file"
  echo "    for (i = 1; i < (rows.length - 1); i++) {" >> "$output_file"
  echo "      shouldSwitch = false;" >> "$output_file"
  echo "      x = rows[i].getElementsByTagName('TD')[n];" >> "$output_file"
  echo "      y = rows[i + 1].getElementsByTagName('TD')[n];" >> "$output_file"
  echo "      if (dir === 'asc') {" >> "$output_file"
  echo "        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {" >> "$output_file"
  echo "          shouldSwitch = true; break;" >> "$output_file"
  echo "        }" >> "$output_file"
  echo "      } else if (dir === 'desc') {" >> "$output_file"
  echo "        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {" >> "$output_file"
  echo "          shouldSwitch = true; break;" >> "$output_file"
  echo "        }" >> "$output_file"
  echo "      }" >> "$output_file"
  echo "    }" >> "$output_file"
  echo "    if (shouldSwitch) {" >> "$output_file"
  echo "      rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);" >> "$output_file"
  echo "      switching = true; switchcount++;" >> "$output_file"
  echo "    } else {" >> "$output_file"
  echo "      if (switchcount === 0 && dir === 'asc') {" >> "$output_file"
  echo "        dir = 'desc'; switching = true;" >> "$output_file"
  echo "      }" >> "$output_file"
  echo "    }" >> "$output_file"
  echo "  }" >> "$output_file"
  echo "}" >> "$output_file"
  echo "</script>" >> "$output_file"
  echo "</head><body>" >> "$output_file"
  echo "<h1>Kubernetes Container Report</h1>" >> "$output_file"
  echo "<p><strong>Cluster Info:</strong> $cluster_info</p>" >> "$output_file"
  echo "<p><strong>Timestamp:</strong> $timestamp</p>" >> "$output_file"
  echo "<p><strong>Executed Command:</strong> $command</p>" >> "$output_file"
  echo "<table id='k8sTable'><thead><tr>" >> "$output_file"
  echo "<th onclick='sortTable(0)'>Namespace</th><th onclick='sortTable(1)'>Pod</th><th onclick='sortTable(2)'>Container</th><th onclick='sortTable(3)'>Command Result</th>" >> "$output_file"
  echo "</tr></thead><tbody>" >> "$output_file"
}

finalize_txt_output() {
  echo "" >> "$OUTPUT_FILE"
}

finalize_html_output() {
  echo "</tbody></table></body></html>" >> "$OUTPUT_FILE"
}

initialize_output() {
  local cluster_info=$1
  local timestamp=$2
  local command=$3
  local output_file=$4
  local format=$5

  if [[ "$format" == "html" ]]; then
    initialize_html_output "$cluster_info" "$timestamp" "$command" "$output_file"
  else
    initialize_txt_output "$cluster_info" "$timestamp" "$command" "$output_file"
  fi
}

finalize_output() {
  local format=$1

  if [[ "$format" == "html" ]]; then
    finalize_html_output
  else
    finalize_txt_output
  fi
}

execute_command() {
  local namespace=$1
  local pod=$2
  local container=$3
  local command=$4

  kubectl exec -n "$namespace" "$pod" -c "$container" -- $command 2>/dev/null
}

output_result() {
  local namespace=$1
  local pod=$2
  local container=$3
  local result=$4

  if [[ "$OUTPUT_FORMAT" == "html" ]]; then
    echo "<tr><td>$namespace</td><td>$pod</td><td>$container</td><td>$result</td></tr>" >> "$OUTPUT_FILE"
  else
    echo "$namespace,$pod,$container,$result" >> "$OUTPUT_FILE"
  fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

for arg in "$@"; do
  case $arg in
    --output-file=*)
      OUTPUT_FILE="${arg#*=}"
      ;;
    --output-format=*)
      OUTPUT_FORMAT="${arg#*=}"
      ;;
    --command=*)
      COMMAND="${arg#*=}"
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: $arg${RESET}"
      usage
      exit 1
      ;;
  esac
done

# Validate output format
if [[ "$OUTPUT_FORMAT" != "txt" && "$OUTPUT_FORMAT" != "html" ]]; then
  echo -e "${RED}Invalid output format: $OUTPUT_FORMAT. Use 'txt' or 'html'.${RESET}"
  usage
  exit 1
fi

# Get cluster information
CLUSTER_INFO=$(kubectl cluster-info | head -n 1)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

initialize_output "$CLUSTER_INFO" "$TIMESTAMP" "$COMMAND" "$OUTPUT_FILE" "$OUTPUT_FORMAT"

# Get all namespaces
kubectl get namespaces -o json | jq -r '.items[].metadata.name' | while read namespace; do
  # Get all pods in the namespace
  kubectl get pods -n "$namespace" -o json | jq -r '.items[] | .metadata.name' | while read pod; do
    echo "Executing in namespace: '$namespace', in pod: '$pod'"

    # Get the containers in the pod
    kubectl get pod "$pod" -n "$namespace" -o json | jq -r '.spec.containers[].name' | while read container; do
      echo "  Executing in container: '$container'..."

      # Execute the command inside the container
      COMMAND_RESULT=$(execute_command "$namespace" "$pod" "$container" "$COMMAND")

      if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Command succeeded for container '$container' in pod '$pod' in namespace '$namespace'${RESET}"
      else
        echo -e "${RED}Command failed for container '$container' in pod '$pod' in namespace '$namespace'${RESET}"
      fi

      output_result "$namespace" "$pod" "$container" "$COMMAND_RESULT"
    done
  done
done

finalize_output "$OUTPUT_FORMAT"
