FROM alpine:latest

RUN apk --no-cache add git jq curl bash zip xmlstarlet python3 openssl openssh-keygen util-linux make && \
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
	
RUN apk --no-cache add libffi gcc python3-dev linux-headers musl-dev libffi-dev openssl-dev && \
    ln -s /usr/bin/python3 /usr/bin/python && \
	echo -e "/usr/lib/azure-cli\n/usr/bin\nn\n" > /tmp/az.rsp && \
	curl -L https://aka.ms/InstallAzureCli | sed -e "s#/dev/tty#/tmp/az.rsp#g" -e "s/XXXX/XXXXXX/g" | bash
	
USER user	
RUN pip install awscli --upgrade --user

RUN echo -e ". /etc/profile\nexport PATH=\$PATH:/home/user/.local/bin\nalias ll='ls -l'" > /home/user/.bash_profile

ENV PATH=$PATH:/home/user/.local/bin \
	TF_DATA_DIR="/home/user/terraform_home"

RUN mkdir /tmp/terraform /home/user/terraform_home && \
	cd /tmp/terraform && \
	echo -e "provider \"aws\" {}\nprovider \"azurerm\" {}\nprovider \"template\" {}\nprovider \"random\" {}" > providers.tf && \
	terraform init

RUN echo "====================================" && \
	ct --version && \
	terraform -v && \
	aws --version && \
	echo "-----------" && \
	az --version && \
	echo "===================================="

ENTRYPOINT [ "/bin/bash", "-l" ]