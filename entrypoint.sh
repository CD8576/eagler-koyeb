#!/bin/sh
set -e
cd /server

PORT="${PORT:-8000}"
RAM="${JAVA_RAM:-320}"          # MB of heap; free instance only has 512MB total
VIEW="${VIEW_DISTANCE:-4}"

# Make the server listen where Koyeb sends traffic
if [ -f server.properties ]; then
  sed -i "s/^server-port=.*/server-port=$PORT/" server.properties
  sed -i "s/^query.port=.*/query.port=$PORT/" server.properties
  sed -i "s/^server-ip=.*/server-ip=/" server.properties
  sed -i "s/^online-mode=.*/online-mode=false/" server.properties
  sed -i "s/^view-distance=.*/view-distance=$VIEW/" server.properties
else
  printf 'server-port=%s\nonline-mode=false\nview-distance=%s\n' "$PORT" "$VIEW" > server.properties
fi
echo "eula=true" > eula.txt

# Optional persistence: if a Koyeb volume is mounted at /data, keep worlds
# and key plugin data there so they survive redeploys.
if [ -d /data ]; then
  PERSIST="${PERSIST:-world world_nether world_the_end plugins/AuthMe plugins/Essentials plugins/LuckPerms}"
  for p in $PERSIST; do
    mkdir -p "/data/$p"
    if [ -d "/server/$p" ] && [ ! -L "/server/$p" ] && [ -z "$(ls -A "/data/$p")" ]; then
      cp -a "/server/$p/." "/data/$p/"
    fi
    rm -rf "/server/$p"
    mkdir -p "$(dirname "/server/$p")"
    ln -s "/data/$p" "/server/$p"
  done
  echo "[entrypoint] Persistent storage enabled at /data"
else
  echo "[entrypoint] No /data volume: world will reset on every redeploy/restart"
fi

JAR=$(ls /server/*.jar | grep -i paper | head -n1 || ls /server/*.jar | head -n1)

exec java -Xms${RAM}M -Xmx${RAM}M \
  -XX:+UseSerialGC -XX:MaxMetaspaceSize=96M -Xss512k \
  -XX:+ExitOnOutOfMemoryError \
  -jar "$JAR" nogui
