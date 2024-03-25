#!/bin/bash

set -eu

# 全局变量
MAX_BACKUP_COUNT=10
SOURCE_DIR="$HOME/Library/Application Support/uTools"
BACKUP_DIR="$HOME/Documents/Backup/uTools"
export RESTIC_PASSWORD="password"
export RESTIC_REPOSITORY="${BACKUP_DIR}"

# 初始化仓库函数
init_repo() {
    # 检查备份仓库是否初始化，如果未初始化则自动初始化
    if ! restic check &> /dev/null; then
        echo "备份仓库未初始化，开始初始化..."
        echo "初始化备份仓库..."
        restic init
        echo "初始化完成."
    fi
}

# 备份函数
backup() {
    init_repo
    echo "开始备份..."
    cd "$SOURCE_DIR" && restic backup . --tag uTools

    # 删除较早的备份
    restic forget --tag uTools --prune --keep-last $MAX_BACKUP_COUNT 

    echo "备份完成."
}

# 恢复函数
restore() {
    echo "开始恢复最新备份..."
    restic restore latest --target "$SOURCE_DIR" --no-lock
    echo "恢复完成."
}

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "源目录不存在: $SOURCE_DIR"
    exit 1
fi

# 检查备份目录是否存在，如果不存在则创建
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# 根据参数执行相应的操作
case "$1" in
    backup) backup;;
    restore) restore;;
    *) echo "无效的参数. 使用: $0 [backup|restore]";;
esac
