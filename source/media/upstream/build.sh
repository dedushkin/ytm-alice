#!/bin/sh
# Сборка bt-proxy: статический musl, библиотеки прошивки не требуются.
# Нужны rustup и встроенный rust-lld.
#
# По умолчанию ARMv7 (работает на любой колонке). На колонках с ARM64-ядром
# старше 5.1 (например, Лайт: 4.9) ARMv7-сборка на каждом чтении часов сначала
# пробует clock_gettime64, ядро его не знает и пишет дамп в журнал. Для таких
# колонок собирайте ARM64: BT_PROXY_TARGET=aarch64-unknown-linux-musl ./build.sh
# Результат: ../dist/bt-proxy (ARMv7) или ../dist/bt-proxy-arm64.
set -eu
cd "$(dirname "$0")"
target=${BT_PROXY_TARGET:-armv7-unknown-linux-musleabihf}
case "$target" in
    armv7-unknown-linux-musleabihf) out=bt-proxy ;;
    aarch64-unknown-linux-musl) out=bt-proxy-arm64 ;;
    *) echo "Неподдерживаемая цель: $target" >&2; exit 1 ;;
esac
rustup target add "$target"
host=$(rustc -vV | sed -n 's/^host: //p')
linker=$(rustc --print sysroot)/lib/rustlib/$host/bin/rust-lld
test -x "$linker"
# пути исходников попадают в сообщения паник — не публиковать домашний каталог сборщика
RUSTFLAGS="--remap-path-prefix=$HOME=~ --remap-path-prefix=$PWD=bt-proxy -C linker=$linker -C linker-flavor=ld.lld -C link-self-contained=yes -C target-feature=+crt-static" \
  cargo build --locked --release --target "$target"
mkdir -p ../dist
cp "target/$target/release/bt-proxy" "../dist/$out"
