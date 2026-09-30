case $# in
  1) ;;
  4)
    export WAYLAND_DISPLAY="$2" DISPLAY="$3" XDG_RUNTIME_DIR="$4"
    ;;
  *)
    echo 'Usage: kak-clipboard {copy|paste} [WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR]' >&2
    exit 2
    ;;
esac

case "${1:-}" in
  copy)
    wayland=(wl-copy)
    x11=(xclip -selection clipboard -in)
    ;;
  paste)
    wayland=(wl-paste --no-newline)
    x11=(xclip -selection clipboard -out)
    ;;
  *)
    echo 'Usage: kak-clipboard {copy|paste} [WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR]' >&2
    exit 2
    ;;
esac

if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  exec "${wayland[@]}"
elif [[ -n ${DISPLAY:-} ]]; then
  exec "${x11[@]}"
else
  echo 'kak-clipboard: no Wayland or X11 display is available' >&2
  exit 1
fi
