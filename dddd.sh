#!/bin/bash
set -euo pipefail

# ------------------ 配置变量 ------------------
BASE_DIR="/sing-box"
BIN_DIR="${BASE_DIR}/bin"
SUBSCRIPT_DIR="${BASE_DIR}/subscript"
BASECONFIG_DIR="${BASE_DIR}/baseconfig"

SINGBOX="${BIN_DIR}/sing-box"
NODE_JSON="${SUBSCRIPT_DIR}/node.json"
BASE_JSON="${BASECONFIG_DIR}/base.json"
BASE_UPDATED_JSON="${BASECONFIG_DIR}/base.updated.json"
GGGGG_JS="${BASE_DIR}/ggggg.js"

# 替换成你的订阅地址
SUBSCRIPTION_URL="https://dash.pqjc.site/api/v1/client/subscribe?token=e5ad721768f5ce6f362cff754c71970e"

# ------------------ 检查依赖 ------------------
command -v iconv >/dev/null 2>&1 || { echo "需要 iconv" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "需要 jq" >&2; exit 1; }
if [ ! -x "$SINGBOX" ]; then
    echo "警告：未检测到 sing-box 可执行，合并步骤可能失败" >&2
fi

# ------------------ 临时目录 ------------------
TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t initconfig)
trap 'rm -rf "${TMPDIR}"' EXIT INT TERM

# ------------------ 1) 下载订阅并处理 ------------------
VAR1=$(curl -s "$SUBSCRIPTION_URL")
node "$GGGGG_JS" "$VAR1"

echo "1) 从原始 node.json 修复编码并在临时目录中处理流"
iconv -f GB18030 -t UTF-8 "$NODE_JSON" |
  jq ' .outbounds |= map(select(.tag | test("套餐|流量") | not)) ' |
  jq '
    .outbounds |= map(
      if type=="object" and (.tag? | type=="string") then
        .tag |= .[2:]
      else
        .
      end
    )
  ' > "${TMPDIR}/node.utf8.trim.json"

# ------------------ 2) 提取 vless/vmess/hysteria2 的 tag ------------------
jq '[.outbounds[] | select(type=="object" and (.type | IN("vless","vmess","hysteria2"))) | .tag ]' \
    "${TMPDIR}/node.utf8.trim.json" > "${TMPDIR}/vless_vmess_hy2_tags.json"

# ------------------ 3) 生成 base.updated.json ------------------
jq --slurpfile tags "${TMPDIR}/vless_vmess_hy2_tags.json" '
.outbounds |= map(
  if .type == "urltest" then
    .outbounds = $tags[0]
  else
    .
  end
)
' "$BASE_JSON" > "$BASE_UPDATED_JSON"

# ------------------ 4) 生成压缩的 compact JSON 并移动最终文件 ------------------
jq -c . "${TMPDIR}/node.utf8.trim.json" > "${SUBSCRIPT_DIR}/node.utf8.trim.compact.json"
mv "${TMPDIR}/node.utf8.trim.json" "${SUBSCRIPT_DIR}/node.utf8.trim.json"
mv "${TMPDIR}/vless_vmess_hy2_tags.json" "${SUBSCRIPT_DIR}/vless_vmess_hy2_tags.json"

# ------------------ 5) 合并配置（若可用） ------------------
if [ -x "$SINGBOX" ]; then
    "$SINGBOX" merge "${BASE_DIR}/main_config.json" -c "$BASE_UPDATED_JSON" -c "${SUBSCRIPT_DIR}/node.utf8.trim.compact.json"
else
    echo "跳过 sing-box merge：未找到 sing-box 可执行" >&2
fi

# ------------------ 6) 清理 subscript 目录下的中间文件，仅保留原始 node.json ------------------
echo "6) 清理 ${SUBSCRIPT_DIR} 下的中间文件，只保留 node.json"
for f in "${SUBSCRIPT_DIR}/node.utf8.trim.json" \
         "${SUBSCRIPT_DIR}/node.utf8.trim.compact.json" \
         "${SUBSCRIPT_DIR}/vless_vmess_hy2_tags.json" \
         "${SUBSCRIPT_DIR}/node.utf8.json"; do
  if [ -e "$f" ]; then
    if [ -f "$f" ] || [ -L "$f" ]; then
      rm -f "$f" || echo "警告：无法删除 $f" >&2
    else
      echo "跳过非普通文件: $f" >&2
    fi
  fi
done

echo "订阅更新完成（subscript 仅保留 node.json）"
