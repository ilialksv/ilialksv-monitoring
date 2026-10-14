FROM alpine:3.24.2

# adduser -D leaves the password field as "!", which sshd treats as a locked
# account and refuses even key logins. "*" means "no password" but not locked.
RUN apk --no-cache add openssh-server \
 && adduser -D -H -s /sbin/nologin tunnel \
 && sed -i 's/^tunnel:!/tunnel:*/' /etc/shadow \
 && mkdir -p /etc/ssh/keys /etc/ssh/authorized_keys

COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 2222
VOLUME /etc/ssh/keys

ENTRYPOINT ["/entrypoint.sh"]
