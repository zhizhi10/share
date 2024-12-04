from jiangjqian/buildkernel

USER root
RUN apt-get update
RUN apt-get install -y tmux qemu cpio
USER richard

ENTRYPOINT ["tail", "-f", "/dev/null"]
