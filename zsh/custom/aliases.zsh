alias python=python3
if ! command -v lsd >/dev/null; then
  alias ll='ls -lah'
else
  alias l='lsd -lah'
fi
