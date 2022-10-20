
export newestfilename=$(ls /home/zhang/zgo/backup/ -Art | tail -n 1)
export MAILTO="wxiaochi@qq.com, \
zhang1.61803398@foxmail.com"

export SUBJECT="database backup"
export ATTACH="/home/zhang/zgo/backup/$newestfilename"
(
    echo "Date: $(date -R)"
    echo "To: $MAILTO"
    echo "Subject: $SUBJECT"
    echo "MIME-Version: 1.0"
    echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
    echo
    echo '---q1w2e3r4t5'
    echo 'Content-Type: text/plain; charset=utf-8'
    echo 'Content-Transfer-Encoding: 8bit'
    echo
    echo "这是由服务器自动发出的邮件"
    echo '---q1w2e3r4t5'
    echo "Content-Type: text/plain; charset=utf-8; name=$newestfilename"
    echo 'Content-Transfer-Encoding: base64'
    echo "Content-Disposition: attachment; filename=$newestfilename"
    echo
    base64 <"$ATTACH"
    echo
    echo '---q1w2e3r4t5--'
) | sendmail $MAILTO


