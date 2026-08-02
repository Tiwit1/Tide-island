#!/usr/bin/env bash
# dev-build.sh — build rápido do Tide Island direto do clone, sem AUR/tarball
# Uso:
#   ./compilar.sh          -> compila e roda isolado (sem instalar no sistema)
#   ./compilar.sh install  -> compila e instala de verdade via cmake --install
#   ./compilar.sh build    -> só compila, não roda nem instala

set -e

cd "$(dirname "$0")"

BUILD_DIR="build"
MODE="${1:-run}"

echo "==> Configurando CMake..."
cmake -S . -B "$BUILD_DIR" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug

echo "==> Compilando..."
cmake --build "$BUILD_DIR" -j"$(nproc)"

case "$MODE" in
  build)
    echo "==> Build concluído. Nada foi instalado nem executado."
    ;;
  install)
    echo "==> Instalando no sistema (requer sudo)..."
    sudo cmake --install "$BUILD_DIR"
    echo "==> Reiniciando serviço..."
    systemctl --user restart tide-island
    echo "==> Pronto. Pra reverter depois: git checkout . && yay -S tide-island"
    ;;
  run|*)
    echo "==> Matando instância anterior (se houver)..."
    pkill tide-island 2>/dev/null || true
    sleep 0.5
    echo "==> Rodando isolado, sem instalar (Ctrl+C pra sair)..."
    QML2_IMPORT_PATH="$PWD/$BUILD_DIR/qt6/qml" /usr/bin/quickshell -p "$PWD"
    ;;
esac
