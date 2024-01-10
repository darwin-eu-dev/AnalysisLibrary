FROM executionengine.azurecr.io/darwin-runtime:latest

# TODO: install with renv.lock?
RUN R -e "remotes::install_github('ohdsi/Achilles')"
RUN R -e "remotes::install_github('darwin-eu/CdmOnboarding')"
RUN R -e "remotes::install_github('darwin-eu/DashboardExport')"
RUN R -e "remotes::install_github('ohdsi/DataQualityDashboard')"

# RUN echo "DATABASECONNECTOR_JAR_FOLDER=/opt/hades/jdbc_drivers" >> /usr/local/lib/R/etc/Renviron
# RUN echo "RENV_PATHS_CELLAR=/opt/renv_cellar" >> /usr/local/lib/R/etc/Renviron

# RUN mkdir /results
# WORKDIR /code

# CMD bash