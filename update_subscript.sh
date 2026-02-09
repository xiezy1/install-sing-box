#!/bin/bash
set -euo pipefail
# 这里替换自己的订阅地址
VAR1=$(curl -s https://example.com/your-subscription-url)

node ggggg.js "$VAR1" "/etc/sing-box/subscript/node.json"
command -v iconv >/dev/null 2>&1 || { echo "需要 iconv" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "需要 jq" >&2; exit 1; }
command -v sing-box >/dev/null 2>&1 || echo "警告：未检测到 sing-box 可执行，合并步骤可能失败" >&2

TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t initconfig)
trap 'rm -rf "${TMPDIR}"' EXIT INT TERM

echo "1) 从原始 node.json 修复编码并在临时目录中处理流"
iconv -f GB18030 -t UTF-8 /etc/sing-box/subscript/node.json |
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

echo "2) 从临时结果提取 vless/vmess/hysteria2 的 tag 列表"
jq '[.outbounds[] | select(type=="object" and (.type | IN("vless","vmess","hysteria2"))) | .tag ]' "${TMPDIR}/node.utf8.trim.json" > "${TMPDIR}/vless_vmess_hy2_tags.json"

echo "3) 生成 base.updated.json（使用临时 tags 文件）"
jq --slurpfile tags "${TMPDIR}/vless_vmess_hy2_tags.json" '
.outbounds |= map(
  if .type == "urltest" then
    .outbounds = $tags[0]
  else
    .
  end
)
' /etc/sing-box/baseconfig/base.json > /etc/sing-box/baseconfig/base.updated.json

echo "4) 生成压缩的 compact JSON 并移动最终文件到 subscript"
jq -c . "${TMPDIR}/node.utf8.trim.json" > /etc/sing-box/subscript/node.utf8.trim.compact.json
mv "${TMPDIR}/node.utf8.trim.json" /etc/sing-box/subscript/node.utf8.trim.json
mv "${TMPDIR}/vless_vmess_hy2_tags.json" /etc/sing-box/subscript/vless_vmess_hy2_tags.json


echo "5) 合并配置（若可用）"
if command -v sing-box >/dev/null 2>&1; then
  sing-box merge /etc/sing-box/main_config.json -c /etc/sing-box/baseconfig/base.updated.json -c /etc/sing-box/subscript/node.utf8.trim.compact.json
else
  echo "跳过 sing-box merge：未找到 sing-box 可执行" >&2
fi

# 清理 subscript 目录下的中间文件，仅保留原始 node.json
echo "6) 清理 /etc/sing-box/subscript 下的中间文件，只保留 node.json"
for f in /etc/sing-box/subscript/node.utf8.trim.json /etc/sing-box/subscript/node.utf8.trim.compact.json /etc/sing-box/subscript/vless_vmess_hy2_tags.json /etc/sing-box/subscript/node.utf8.json; do
  if [ -e "$f" ]; then
    # 仅删除普通文件或符号链接，避免误删目录
    if [ -f "$f" ] || [ -L "$f" ]; then
      rm -f "$f" || echo "警告：无法删除 $f" >&2
    else
      echo "跳过非普通文件: $f" >&2
    fi
  fi
done

echo "订阅更新完成（subscript 仅保留 node.json）"
