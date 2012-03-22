#!/usr/bin/perl
use strict;
use warnings;
use Net::SMTP_auth;
use General;

my %CFG = General::get_config('config');

my $MAIL_FROM = $CFG{SMTP_SEVR};
$MAIL_FROM =~ s{^.*?\.}{\@};
$MAIL_FROM = $CFG{SMTP_USER}.$MAIL_FROM;

my @MAIL_TO = split ';', $CFG{MAIL_TO};
my @MAIL_CC = split ';', $CFG{MAIL_CC};
@MAIL_TO or @MAIL_CC or die "There is no one to received mail.";

my ($MAIL_SBJT, $MAIL_BODY) = General::get_mail_content($CFG{MAIL_FILE});

my $smtp = Net::SMTP_auth -> new(
    Host => $CFG{SMTP_SEVR},
    Port => $CFG{SMTP_PORT},
    Hello => $CFG{SMTP_SEVR},
    Debug => 1
) || die 'Cannot connect '.$CFG{SMTP_SEVR}.':'.$CFG{SMTP_PORT}." $!\n";

$smtp -> auth('NTLM', $CFG{SMTP_USER}, $CFG{SMTP_PSWD}) || die "Can't authenticate: $!\n";
$smtp -> mail($MAIL_FROM);
$smtp -> to($MAIL_FROM);
foreach (@MAIL_TO) {$smtp -> to($_);}
foreach (@MAIL_CC) {$smtp -> to($_);}
$smtp -> data();

$smtp -> datasend("Content-Type: multipart/mixed; boundary=a; charset=utf-8\n");
$smtp -> datasend("From: $MAIL_FROM\n");
foreach (@MAIL_TO) {$smtp -> datasend("To: ".$_."\n");}
foreach (@MAIL_CC) {$smtp -> datasend("Cc: ".$_."\n");}
$smtp -> datasend("Subject: $MAIL_SBJT\n\n");

$smtp -> datasend("--a\n\n");
$smtp -> datasend($MAIL_BODY);
$smtp -> datasend("\n");

if (defined $CFG{MAIL_ATTA}) {
    my %atta_list;
    foreach my $att (split ';', $CFG{MAIL_ATTA}) {
        chomp $att;

        if (-e $att) {
            if (-d $att) {
                foreach my $file (General::get_file_list($att)) {
                    my ($att_name, $att_code) = General::get_attach($file);
                    $atta_list{$att_name} = $att_code;
                }
            }
            elsif (-f $att) {
                my ($att_name, $att_code) = General::get_attach($att);
                $atta_list{$att_name} = $att_code;
            }
        }
        else {
            warn "cannot found attachment : <$att>\n";
        }
    }
    
    foreach my $key (keys %atta_list) {
        $smtp -> datasend("--a\n");
        $smtp -> datasend("Content-Type: ".General::get_content_type($key)."; name=$key\n");
        $smtp -> datasend("Content-Transfer-Encoding: base64\n\n");
        $smtp -> datasend($atta_list{$key});
    }
}

$smtp -> datasend("\n");
$smtp -> datasend("--a--\n");
$smtp -> dataend();
$smtp -> quit();
