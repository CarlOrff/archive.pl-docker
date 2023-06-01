#!/usr/local/bin/perl
use strict;
use LWP::UserAgent;
use LWP::Protocol::socks4;
my $ua = new LWP::UserAgent(agent => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.5) Gecko/20060719 Firefox/1.5.0.5');
$ua->proxy([qw(http https)] => 'socks4://localhost:9050');
my $response = $ua->get("http://www.freebsd.org");
print $response->code,' ', $response->message,"\n";
my $response = $ua->get("https://www.microsoft.com");
print $response->code,' ', $response->message,"\n";