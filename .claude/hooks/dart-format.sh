#!/bin/sh
# Hook PostToolUse de Claude Code: aplica `dart format` al fichero Dart recién editado,
# dentro de mydiary-flutter. Si el contenedor no está levantado no hace nada: nunca
# bloquea la edición; el pre-commit y la CI siguen siendo la red de seguridad.

file=$(jq -r '.tool_input.file_path // empty')

case "$file" in
    *.dart) ;;
    *) exit 0 ;;
esac

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$file" in
    "$root"/*) rel="${file#"$root"/}" ;;
    *) exit 0 ;;
esac

[ -f "$file" ] || exit 0
[ "$(docker inspect -f '{{.State.Running}}' mydiary-flutter 2>/dev/null)" = "true" ] || exit 0

docker exec mydiary-flutter dart format "$rel" >/dev/null 2>&1

exit 0
