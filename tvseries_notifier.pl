#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use JSON;
use LWP::UserAgent;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;
use Email::MIME::CreateHTML;
use Time::Piece;
use Getopt::Long;

my $api = "SECRET"; # Replace with your own API key
my $ua = LWP::UserAgent->new;
my $data;

my $client_id = "151216db7d18bf7e6024552ce1548d795aba23f50fdd01a97c7fe6acf6f41ba2";
$ua->default_header("Content-Type" => "application/json");
$ua->default_header("trakt-api-version" => "2");
$ua->default_header("trakt-api-key" => $client_id);

my $date = localtime->strftime('%Y%m%d');
my $length = '7';
GetOptions (
	"days:i" => \$length
);

my $subscription = {
	'revolution' => {},
	'the 100' => {},
	'the big bang theory' => {},
	'family guy' => {},
	'american dad' => {},
	'the simpsons' => {},
	'the walking dead' => {},
	'the blacklist' => {},
	'person of interest' => {},
	'grimm' => {},
	'helix' => {},
};

# Get json from trakt.tv
my $response = $ua->get("https://api-v2launch.trakt.tv/calendars/shows/$date/$length?extended=images");
if ($response->is_success) {
	$data =  $response->decoded_content;
} else {
	die $response->status_line;
}

my $json = JSON->new;
my $r = $json->decode($data);

# Process response
my $message;
my ($season, $number, $title, $aired, $banner);

foreach my $day (sort keys %$r) {
    my $count = 0;
    $message .= "<h3>$day</h3>";

    foreach my $show (@{$r->{$day}}) {
        my $key = lc($show->{show}->{title});
        if (exists $subscription->{$key}) {
            $count = 1;
            $season = $show->{episode}->{season};
            $number = $show->{episode}->{number};
            $title = $show->{episode}->{title};
            $aired = $show->{airs_at};
            $banner = $show->{show}->{images}->{banner}->{full};
            $message .= "&nbsp;&nbsp;<b>" . $show->{show}->{title} . "</b><br>";
            if (defined $banner) {
                $message .= "&nbsp;&nbsp;<img src=\"" . $banner . "\" width=\"50%\"><br>";
            }
            $message .= "&nbsp;&nbsp;&nbsp;&nbsp;Season $season / episode $number: $title<br>";
            $message .= "&nbsp;&nbsp;&nbsp;&nbsp;Airing time: $aired<br>";
        }
    }
    if ($count == 0) {$message .= "&nbsp;&nbsp;-- no subscription for this date<br>";}
}

my $email = Email::MIME->create_html(
	header => [
		From => 'change@me',
		To => 'change@me',
		Subject => 'Shows to watch',
	],
	body => $message,
	plain => $message
);

my $sender = Email::Send->new(
	{
		mailer => 'Gmail',
		mailer_args => [
			username => 'change@me',
			password => 'p@55w0rd'
		]
	}
);
eval { $sender->send($email)};
die "Error sending email: $@" if $@;
