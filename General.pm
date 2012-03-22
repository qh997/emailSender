package General;

use warnings;
use strict;
use MIME::Base64;

sub get_config {
    my $config_file = shift;

    open my $CF, "< $config_file" or die 'cannot open file : '.$config_file;
    my @file_content = <$CF>;
    close $CF;

    my %configs;
    foreach my $line (@file_content) {
        chomp $line;

        if ($line =~ m{^\s*(.*?)\s*=\s*(.*)\s*$}) {
            $configs{$1} = $2;
        }
    }

    return %configs;
}

sub get_mail_content {
    my $content_file = shift;

    open my $MC, "< $content_file" or die 'cannot open file : '.$content_file;
    my @mail_content = <$MC>;
    close $MC;
    
    my $ret_subject = shift @mail_content;
    chomp $ret_subject;
    
    my $ret_body = join '', @mail_content;
    
    return $ret_subject, $ret_body;
}

sub get_remain_time {
    my $s_time = shift;
    my $e_time = shift;

    my $print_str = '';
    my $r_time = $e_time - $s_time;
    my $hor = int($r_time / 3600);
    $hor =~ s/^(\d{1})$/0$1/;
    my $min = int(($r_time - $hor * 3600) / 60);
    $min =~ s/^(\d{1})$/0$1/;
    my $sec = $r_time - $hor * 3600 - $min * 60;
    $sec =~ s/^(\d{1})$/0$1/;

    return $hor.':'.$min.':'.$sec;
}

sub get_file_list {
    my $path = shift;
    $path =~ s{(?<!/)$}{/};

    opendir DH, $path;
    my @dir_path = readdir(DH);
    closedir DH;

    my @in_list;
    foreach my $in (@dir_path) {
        next if ($in =~ m{^\.+});

        my $in_path = $path.$in;

        if (-d $in_path) {
            push @in_list, get_file_list($in_path.'/');
        }
        else {
            push @in_list, $in_path;
        }
    }
    
    return @in_list;
}

sub get_attach {
    my $file = shift;

    open my $MA, "< $file";
    binmode($MA);
    my $attachment = join('', <$MA>);
    close $MA;
    
    my $att_name = $file;
    $att_name =~ s{.*/}{};
    
    return $att_name, encode_base64($attachment);
}

sub get_content_type {
    my $name = shift;
    
    if ($name =~ m{\.pdf$}) {
        return "application/pdf";
    }
    elsif ($name =~ m{\.jpg$}) {
        return "image/jpeg";
    }
    elsif ($name =~ m{\.eml$}) {
        return "message/rfc822";
    }
    else {
        return "text/plain";
    }
}

return 1;
