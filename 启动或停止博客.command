#!/bin/bash
# 双击此文件：未运行则启动；已运行则停止
# 与 Windows 版「启动或停止博客.bat」行为一致

cd "$(dirname "$0")" || exit 1

PORT=4321
PID_FILE=".dev-server.pid"
LOG_DIR="logs"
RUNNING=0

is_port_listening() {
    lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1
}

# ----- 判断服务是否在运行（PID 文件 + 端口双重判断） -----
if [[ -f "$PID_FILE" ]]; then
    SERVER_PID=$(cat "$PID_FILE")
    if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        RUNNING=1
    fi
fi
if is_port_listening; then
    RUNNING=1
fi

if [[ "$RUNNING" == "1" ]]; then
    echo "============================================"
    echo "  正在停止博客开发服务器..."
    echo "============================================"
    if [[ -f "$PID_FILE" ]]; then
        SERVER_PID=$(cat "$PID_FILE")
        kill "$SERVER_PID" 2>/dev/null
        rm -f "$PID_FILE"
    fi
    # ----- 兜底：清理其他占用端口的残留进程 -----
    PIDS=$(lsof -nP -t -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null)
    if [[ -n "$PIDS" ]]; then
        echo "$PIDS" | xargs kill 2>/dev/null
    fi
    echo "服务器已停止。"
else
    echo "============================================"
    echo "  正在后台启动博客开发服务器..."
    echo "  首次启动较慢，请耐心等待（最长约 90 秒）"
    echo "============================================"
    mkdir -p "$LOG_DIR"
    nohup pnpm dev >"$LOG_DIR/dev-server.log" 2>"$LOG_DIR/dev-server.err.log" &
    SERVER_PID=$!
    echo "$SERVER_PID" >"$PID_FILE"

    STARTED=0
    for ((i = 0; i < 90; i++)); do
        sleep 1
        if is_port_listening; then
            STARTED=1
            break
        fi
        if ! kill -0 "$SERVER_PID" 2>/dev/null; then
            break
        fi
    done

    if [[ "$STARTED" == "1" ]]; then
        echo "服务器已启动 (PID: $SERVER_PID)"
        echo "访问地址: http://localhost:$PORT"
        echo "日志文件: $LOG_DIR/dev-server.log"
    elif ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "服务器进程已退出，请查看 $LOG_DIR/dev-server.err.log"
        rm -f "$PID_FILE"
    else
        echo "暂时未检测到服务就绪，但它可能仍在后台启动中。"
        echo "请稍等片刻后访问 http://localhost:$PORT ，或查看 $LOG_DIR/dev-server.log 确认启动进度。"
    fi
fi

echo
read -r -p "按回车键关闭窗口..."
