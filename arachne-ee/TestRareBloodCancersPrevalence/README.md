# C1-001: Rare Blood Cancers  

<img src="https://img.shields.io/badge/Study%20Status-Started-blue.svg" alt="Study Status: Started">

- Analytics use case(s): **-**
- Study type: Off-the-shelf; prevalence
- Tags: **-**
- Study lead: Edward Burn, Marti Catala
- Study start date: **-**
- Study end date: **-**
- Protocol: **-**
- Publications: **-**
- Results explorer: **-**

## Instructions to run
1) Download this entire repository (you can download as a zip folder using Code -> Download ZIP, or you can use GitHub Desktop). 
2) Open the project <i>RareBloodCancersPrevalence.Rproj</i> in RStudio (when inside the project, you will see its name on the top-right of your RStudio session)
3) Open the CodeToRun.R file - this is the only file you should need to interact with. 
- Install the latest versions of IncidencePrevalence (by uncommenting and running line 4). Because IncidencePrevalence is currently a private package, please see the instructions below on installing a private package. 
- Add your database specific parameters (name of database, schema name with OMOP data, schema name to write results, table name stem for results to be saved in the result schema).
- Create a connection to the via CDMConnector (see https://odyosg.github.io/CDMConnector/articles/DBI_connection_examples.html for connection examples for different dbms).
- Choose whether to run as a test (TRUE/ FALSE - if TRUE we'll run the analysis for one denominator cohort and one outcome to quickly get an idea if the full analysis code should run without a problem).
- Run the source analysis line which will start the analysis. Once completed, the results should be in your output folder.

## Installing a private package
Once your username has been added to the private GitHub repo you will be able to install once you have your Github PAT set up. If you do not already have this, you can set this up by: 
### In GitHub
- Click on your username/ profile picture  
- Go to Settings
- Choose Developer Settings
- In the left sidebar, choose Personal access tokens
- Choose Generate new token
- Provide a name and description for your token,
- Choose Generate token
- Copy the token you are given to your clipboard
### In RStudio
- usethis::edit_r_environ()
- GITHUB_PAT = '.....'
- restart RStudio
- Now you can run: remotes::install_github("....")
