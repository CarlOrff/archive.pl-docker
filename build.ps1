Copy-Item -Path C:\Users\Work\Documents\ingram\Perl\archive\archive.pl -Destination .
Copy-Item -Path C:\Users\Work\Documents\ingram\Perl\dzil\WWW-YaCyBlacklist\yacy\default.black -Destination .
Copy-Item -Path C:\Users\Work\Documents\ingram\Perl\dzil\WWW-YaCyBlacklist\lib\WWW\YaCyBlacklist.pm -Destination .
docker image rm archive.pl-docker
docker build -t archive.pl-docker .
docker tag archive.pl-docker archaeopath/archive.pl-docker:latest
docker login -u archaeopath
docker image push archaeopath/archive.pl-docker
