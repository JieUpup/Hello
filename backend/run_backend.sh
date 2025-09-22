#!/usr/bin/env bash
set -euo pipefail

# 配置
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$PROJECT_ROOT/venv"
PYTHON_BIN="$VENV_DIR/bin/python"
PIP_BIN="$VENV_DIR/bin/pip"
UVICORN_BIN="$VENV_DIR/bin/uvicorn"
PORT="${PORT:-8001}"
HOST="${HOST:-0.0.0.0}"

echo "==> 项目目录: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# 1) 创建虚拟环境（如果不存在）
if [ ! -x "$PYTHON_BIN" ]; then
  echo "==> 创建虚拟环境 venv..."
  python3 -m venv "$VENV_DIR"
fi

# 2) 激活虚拟环境（为后续命令使用）
# 使用具体二进制，避免 subshell/激活问题
echo "==> 升级 pip ..."
"$PIP_BIN" install --upgrade pip setuptools wheel

# 3) 安装依赖（如果有 requirements.txt）
if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
  echo "==> 安装 requirements.txt 中的依赖（如果还没安装）..."
  "$PIP_BIN" install -r "$PROJECT_ROOT/requirements.txt"
else
  echo "==> 警告：requirements.txt 未找到，尝试安装最低依赖..."
  "$PIP_BIN" install fastapi uvicorn python-multipart passlib sqlalchemy gTTS moviepy imageio imageio-ffmpeg
fi

# 4) 确保输出目录存在
mkdir -p "$PROJECT_ROOT/uploads"
mkdir -p "$PROJECT_ROOT/videos"

# 5) 检查 ffmpeg（moviepy 需要它来写视频）
if ! command -v ffmpeg >/dev/null 2>&1 ; then
  echo ""
  echo "!!! 注意：系统未检测到 ffmpeg（moviepy 需要）。如果你在 macOS，安装命令："
  echo "    brew install ffmpeg"
  echo "如果在 Linux (Ubuntu/Debian)，安装命令："
  echo "    sudo apt update && sudo apt install -y ffmpeg"
  echo ""
  echo "脚本会继续，但生成视频时可能会失败。"
fi

# 6) 启动 uvicorn（使用 venv 中的 python 启动 uvicorn，确保使用虚拟环境）
echo "==> 启动后端: $PYTHON_BIN -m uvicorn main:app --host $HOST --port $PORT"
# 使用 exec 替换进程（便于前台运行 / 在容器中使用）
exec "$PYTHON_BIN" -m uvicorn main:app --host "$HOST" --port "$PORT"

