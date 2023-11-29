# docker build -t "toscm/fastret:0.99.4" .
# docker run -it --rm -p "3838:3838" "toscm/fastret:0.99.4" /bin/bash
# docker push "toscm/fastret:0.99.4"
FROM rocker/shiny-verse:4.1

RUN apt-get update && apt-get install --no-install-recommends -y openjdk-8-jdk
RUN export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN R CMD javareconf
RUN apt-get install -y gdebi-core qpdf devscripts ghostscript r-cran-devtools
RUN Rscript -e "devtools::install_github('toscm/FastRet', Ncpus = 12, upgrade = FALSE)"

CMD Rscript -e "FastRet::FastRet(3838)"
