#!/bin/sh

# 1. 生成 /opt/show 脚本 (修改了输出路径)
mustpl -d '{"SERVER": "${SERVER:-SET_SERVER}", "PUBLIC_KEY": "${PUBLIC_KEY:-SET_PUBLIC_KEY}", "NAME": "${NAME:-ss}"}' -o /opt/show /opt/show-template
# 2. 给 /opt/show 添加执行权限 (修改了路径)
chmod +x /opt/show

# 3. 根据 PROTOCOL 环境变量生成 /etc/sing-box/config.json
#    仅当 /etc/sing-box/config.json 不存在时才生成
if [ ! -f /etc/sing-box/config.json ] && [ "${PROTOCOL}" = "shadowsocks" ]; then
    mustpl -d '{"METHOD": "${METHOD:-2022-blake3-aes-128-gcm}", "PASS": "${PASS:-SET_PASSWORD}", "PORT": "${PORT:-443}"}' -o /etc/sing-box/config.json /opt/config-template-shadowsocks.json
elif [ ! -f /etc/sing-box/config.json ] && [ "${PROTOCOL}" = "vless" ]; then
    mustpl -d '{"UUID": "${UUID:-SET_UUID}", "PRIVATE_KEY": "${PRIVATE_KEY:-SET_PRIVATE_KEY}", "SHORT_ID": "${SHORT_ID:-153bb5b1383b79fd}", "FAKE_SERVER": "${FAKE_SERVER:-www.google.com}", "PORT": "${PORT:-443}", "NAME": "${NAME:-vless}"}}' -o /etc/sing-box/config.json /opt/config-template-vless.json
fi

# 4. 执行传递给脚本的命令 (即 Dockerfile 中的 CMD)
exec "$@"
