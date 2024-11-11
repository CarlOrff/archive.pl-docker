FROM perl:5.40.0-bookworm
RUN cpanm --force HTML::Form
COPY tor.list /etc/apt/sources.list.d/
RUN apt-get update --allow-insecure-repositories
RUN apt-get install -y apt-utils --allow-unauthenticated
RUN apt install -y net-tools --allow-unauthenticated
RUN apt-get -y install systemctl --allow-unauthenticated
RUN apt-get -y install tsocks --allow-unauthenticated
RUN apt install -y apt-transport-https --allow-unauthenticated
RUN apt-get -y install dos2unix --allow-unauthenticated
RUN cpanm URI
RUN cpanm URI::Encode
RUN cpanm URI::URL
RUN cpanm Browser::Open
RUN cpanm Data::Dumper
RUN cpanm --force Test2::Plugin::NoWarnings && cpanm Params::ValidationCompiler && cpanm DateTime
RUN cpanm Feed::Find
RUN cpanm FileHandle
RUN cpanm FindBin
RUN apt-get -y install xvfb --allow-unauthenticated
RUN apt-get install -y --allow-unauthenticated --no-install-recommends firefox-esr
RUN xvfb-run firefox &
RUN cpanm Firefox::Marionette
RUN apt-get -y install libgd-dev --allow-unauthenticated && cpanm GD
RUN cpanm Getopt::Std
RUN cpanm HTML::Entities
RUN cpanm HTML::LinkExtor
RUN cpanm HTML::Strip
RUN cpanm Image::Info
RUN cpanm Image::Thumbnail
RUN cpanm JSON::XS
RUN cpanm List::Util
#RUN cpanm LWP::ConsoleLogger::Everywhere
RUN cpanm LWP::Protocol::socks
RUN cpanm LWP::RobotUA
RUN cpanm MIME::Base64
RUN cpanm Net::FTP
RUN cpanm Net::IDN::Encode
RUN cpanm PDF::API2
RUN cpanm POSIX
RUN cpanm Scalar::Util
RUN cpanm Try::Tiny
RUN cpanm Web::Scraper
RUN cpanm --force XMLRPC::Lite && cpanm WP::API
RUN cpanm WWW::Mechanize
RUN cpanm WWW::RobotRules
RUN cpanm XML::Atom::SimpleFeed
RUN cpanm XML::Feed
RUN cpanm XML::Twig
#RUN cpanm --uninstall LWP
#RUN cpanm LWP@6.68
RUN wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null
RUN apt-get install -y tor deb.torproject.org-keyring --allow-unauthenticated
RUN apt-get install -y bash --allow-unauthenticated
RUN apt-get clean all
COPY torrc /etc/tor/
COPY . /usr/src/archive
WORKDIR /usr/src/archive
RUN dos2unix ./init.sh
RUN chmod +x ./init.sh
CMD ["/usr/src/archive/init.sh"]