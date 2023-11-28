# export registry="gitlab.spang-lab.de:4687"
# export repo="gitlab.spang-lab.de:4687/containers/fastret"
# docker build -t "${repo}:latest" -t "${repo}:0.996" .
# docker run -it --rm -p "3838:3838" "${repo}:latest"
# docker login "${registry}"
# docker push "${repo}:latest"
# docker push "${repo}:0.996"
FROM rocker/r-ubuntu:22.04

# Install R (based on instructions from https://cran.r-project.org/)
RUN apt update -qq
RUN apt install --no-install-recommends software-properties-common dirmngr
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN apt install --no-install-recommends --upgrade r-base r-base-dev
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# Pre-install all dependencies of FastRet that are available via apt, as apt is much faster then R's install.packages and also installs required system libraries
RUN apt install --no-install-recommends -y \
    r-cran-caret \
    r-cran-devtools \
    r-cran-ggplot2 \
    r-cran-glmnet \
    r-cran-pdist \
    r-cran-rcdk \
    r-cran-readxl \
    r-cran-shiny \
    r-cran-shinybusy

# Downgrade to Java Development Kit (JDK) 8 as rJava with JDK 11+ doesn't work with shiny, as described [here](https://stackoverflow.com/questions/75804123/java-exception-in-r-shiny-reactive-runtime). rJava is used by [rcdk](https://github.com/CDK-R/cdkr#installing-java), which is a dependency of FastRet.
RUN apt install openjdk-8-jdk
# The actual installation path of `openjdk-8-jdk` can be found by running `update-alternatives --config java` interactively inside the container. To tell R which version to use, we need to set `JAVA_HOME` and run `R CMD javareconf` afterwards. Then we need to reinstall rJava from source to force recompilation of all java libs.
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
RUN R CMD javareconf
RUN Rscript -e "install.packages('rJava', type='source')"

# Now install FastRet incl. remaining dependencies
RUN Rscript -e "devtools::install_github( \
        'toscm/FastRet', \
        upgrade = TRUE, \
        Ncpus = parallel::detectCores()
    )"
