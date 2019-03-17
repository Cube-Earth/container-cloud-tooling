FROM alpine:latest

RUN apk --no-cache add git jq curl bash zip xmlstarlet python3 openssl openssh-keygen util-linux && \
	adduser -D -g '' -s /sbin/nologin user

WORKDIR /tmp	
RUN wget "`curl -sL https://www.terraform.io/downloads.html | awk 'match($0, /<a *href="[^"]+/) { s=substr($0,RSTART,RLENGTH); gsub(/[^"]*"/, "", s); print s }' | grep linux | grep amd64`" && \
	unzip *.zip -d /usr/local/bin && \
	rm *.zip
	
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
	python3 get-pip.py && \
	rm *.py
	
RUN apk add --update wget ca-certificates && \
	wget -q -O /etc/apk/keys/necromancerr@users.noreply.github.com.rsa.pub https://github.com/Cube-Earth/alpine-tools/releases/download/repository%2Fx86_64/necromancerr.users.noreply.github.com.rsa.pub && \
	echo "https://github.com/Cube-Earth/alpine-tools/releases/download/repository" >> /etc/apk/repositories && \
	apk add --no-cache coreos-ct
	
USER user	
RUN pip install awscli --upgrade --user

RUN echo -e ". /etc/profile\nexport PATH=\$PATH:/home/user/.local/bin\nalias ll='ls -l'" > /home/user/.bash_profile

ENV PATH=$PATH:/home/user/.local/bin \
	TF_DATA_DIR="/home/user/terraform_home"

RUN mkdir /tmp/terraform /home/user/terraform_home && \
	echo "provider "aws" {}" > /tmp/terraform/providers.tf && \
	cd /tmp/terraform && \
	terraform init

RUN echo "====================================" && \
	ct --version && \
	terraform -v && \
	aws --version && \
	echo "===================================="

ENTRYPOINT [ "/bin/bash", "-l" ]