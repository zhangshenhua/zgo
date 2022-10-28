#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use Dir::ls;
use MIME::QuotedPrint;
use MIME::Base64;
use Mail::Sendmail;


chdir '/home/zhang/zgo/backup/';

sub SENDMAIL {
    my (%args) = @_;
    print $args{file} . "\n";

    my %mail = (from => $args{from},  
                to =>   $args{to},  
                subject => $args{subject} || 'no_subject',
                );

    my $boundary = "====" . time() . "====";
    $mail{'content-type'} = "multipart/mixed; boundary=\"$boundary\"";

    my $message = encode_qp( $args{message} );

    my $file = $args{file}; 

    open (F, $file) or die "Cannot read $file: $!";
    binmode F; undef $/;
    $mail{body} = encode_base64(<F>);
    close F;

    $boundary = '--'.$boundary;

#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{
$mail{body} = <<END_OF_BODY;
$boundary
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: quoted-printable

$message
$boundary
Content-Type: application/octet-stream; name="$file"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="$file"

$mail{body}
$boundary--
END_OF_BODY
#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
    sendmail(%mail) || print "Error: $Mail::Sendmail::error\n";
};



my $i=1;
foreach(
    (ls('.', {
    -r => 1, 
    sort => 'time'
    }))[0,1]){
    my $filename = $_;

    SENDMAIL (
        from    =>  'zhang@xiaochi.shenhua.zgogo.com',
        to      =>  'wxiaochi@qq.com, ' .
                    'zhang1.61803398@foxmail.com'
                    ,
        subject =>  '系统备份' . '(' . $i++ . ')',
        message =>  '本邮件由系统自动发出，请勿回复。',
        file    =>  "$filename",
    )
    ;
}


say 'OK';



