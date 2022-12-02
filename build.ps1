docker image rm archive.pl-docker
docker build -t archive.pl-docker .
docker tag archive.pl-docker archaeopath/archive.pl-docker:latest
docker login -u archaeopath
docker image push archaeopath/archive.pl-docker