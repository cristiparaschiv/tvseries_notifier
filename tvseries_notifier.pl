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
my $response = $ua->get('http://api.trakt.tv/calendar/shows.json/'.$api.'/'.$date.'/'.$length);
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
foreach my $days (@$r) {
	$message .= "<h3>$days->{date}</h3>";
	my $count = 0;
	my $episodes = $days->{episodes};
	foreach my $ep (@$episodes) {
		my $key = lc($ep->{show}->{title});
		if (exists $subscription->{$key}) {
			$count = 1;
			$season = $ep->{episode}->{season};
			$number = $ep->{episode}->{number};
			$title = $ep->{episode}->{title};
			$aired = $ep->{episode}->{first_aired_iso};
			$banner = $ep->{show}->{images}->{banner};
			$message .= "&nbsp;&nbsp;<b>" . $ep->{show}->{title} . "</b><br>";
			$message .= "&nbsp;&nbsp;<img src=\"" . $banner . "\" width=\"50%\"><br>";
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
