FROM python:3.11.4-slim-bullseye

# 添加构建参数用于认证
ARG HTUSER=admin
ARG HTPASSWD=defaultpass

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ENV API_PORT="15372" \
    NGINX_PORT="15373" \
    UMASK=000

WORKDIR "/app"
COPY lib_deb lib_deb
COPY src src
COPY static static
COPY temp temp
COPY dist dist
COPY docs/requirements_api.txt requirements_api.txt

RUN mkdir media  \
    && cp -r lib_deb/sources.list /etc/apt/sources.list \
    # 增加apache2-utils安装
    && apt-get update -o Acquire::Check-Valid-Until=false  \
    && apt-get install -y libmediainfo0v5 libzen0v5 nginx gettext-base apache2-utils \
    # 生成密码文件（生产环境建议通过secret注入）
    && htpasswd -bc /etc/nginx/.htpasswd ${HTUSER} ${HTPASSWD} \
    && chmod 644 /etc/nginx/.htpasswd \
    && cp -r lib_deb/entrypoint entrypoint \
    && chmod +x entrypoint \
    && cp -r dist /public \
    # 确保nginx配置包含认证设置
    && cp -r lib_deb/nginx.conf /etc/nginx/nginx.template.conf \
    && pip install -r requirements_api.txt --trusted-host mirrors.aliyun.com --default-timeout=600 -i https://mirrors.aliyun.com/pypi/simple/

USER root
EXPOSE 15372 15373
ENV PYTHONPATH=${PYTHONPATH}:.
CMD ["sh", "entrypoint"]
