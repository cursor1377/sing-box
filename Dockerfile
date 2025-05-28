ARG RELEASE

# 阶段 1: 获取 sing-box 二进制文件
FROM ghcr.io/sagernet/sing-box:${RELEASE} AS sing-box

# 阶段 2: 获取 mustpl 二进制文件
FROM ghcr.io/tarampampam/mustpl:0.1.1 AS mustpl-builder

# 阶段 3: 构建最终镜像
FROM alpine:3.18.7

# Choreo 要求非 root 用户，UID 在 10000-20000 之间
# WSO2 示例中常用 10014
ARG CHOREO_UID=10014
ARG CHOREO_GID=10014
ARG CHOREO_USER=choreouser
ARG CHOREO_GROUP=choreo

# 创建用户组和用户
RUN addgroup -g ${CHOREO_GID} ${CHOREO_GROUP} && \
    adduser -u ${CHOREO_UID} -G ${CHOREO_GROUP} -D -h /home/${CHOREO_USER} ${CHOREO_USER}

# 安装依赖并创建目录
# /etc/sing-box/ 目录也需要 choreouser 有权限写入生成的 config.json
RUN apk add --no-cache libqrencode jq coreutils bash && \
    mkdir -p /etc/sing-box/ && \
    chown ${CHOREO_USER}:${CHOREO_GROUP} /etc/sing-box/

# 复制二进制文件和脚本，并设置所有权
# 注意：确保你的 Docker 版本支持 COPY --chown
COPY --from=sing-box /usr/local/bin/sing-box /bin/sing-box
COPY --from=mustpl-builder /bin/mustpl /bin/mustpl

# /opt 目录用于存放脚本，也需要设置权限
RUN mkdir -p /opt && chown ${CHOREO_USER}:${CHOREO_GROUP} /opt
COPY --chown=${CHOREO_USER}:${CHOREO_GROUP} entrypoint.sh config-template* show-template /opt/
COPY --chown=${CHOREO_USER}:${CHOREO_GROUP} gen* /bin/

# 确保脚本有执行权限
RUN chmod +x /opt/entrypoint.sh /bin/gen*

# 暴露应用程序监听的端口 (请根据实际情况修改)
# 这个端口需要与 .choreo/component.yaml 中的 service.port 一致
EXPOSE 8080

# 切换到非 root 用户
USER ${CHOREO_USER}

ENTRYPOINT ["/opt/entrypoint.sh"]

# CMD 中定义的配置文件路径 /etc/sing-box/config.json
# entrypoint.sh 脚本可能会使用模板生成这个文件
CMD ["sing-box", "--config", "/etc/sing-box/config.json", "run"]
