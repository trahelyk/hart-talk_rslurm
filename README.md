---
title: "Reproducible Research"
author: "Kyle Hart"
date: "03 May 2017"
output: 
  ioslides_presentation:
    logo: gfx/logo.png
    css: styles.css
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE)
```

## Kyle who?

* MS in Biostatistics from OHSU in June 2014
* 2016 – Now: Statistician at OHSU Department OB/GYN
* 2014 – 2016: Statistician at OHSU Department of Surgery
* 2014 - Now: Statistician with the Biostatistics & Design Program
* 2013 – 2014: Data manager at the VA 
* 2004 – 2013: Data manager in industry

## Why I act this way
	
* I've been writing code since I was 8; I see all this through the eyes of a programmer.
* I'm deeply committed to R.
* I'm cautiously optimisitc about the Hadley Wickham/tidyverse/RStudio movement.
* It's all about literate programming.

<img src="gfx/me.jpg" alt="me." width="250px" align="right"/>

## (with applications in R)

This talk will focus on applications in R.

* I think implementations in SAS and Stata are clunky and immature. 
* SPSS, as far as I can tell, isn't even really trying. 
* Also, because R is just how I roll.

# What is research? 
What is not resarch?

## Things that are not research
* Journal article
* Talk at a conference
* Poster
* Slide deck
* Book
* Web site

	
These things are not research; they are advertising for research. Research is "the full software environment, code, and data that produced the results." 

(Claerbout 1992)

## Gold standard: Replicability

---

<div class="centered">
<img src="gfx/the_difference.png" alt="XKCD" height="550px"/>
</div>

## Gold standard: Replicability

* The research includes enough stuff that a different researcher can follow the same procedures in a new sample and come up with the same results.
* Hard to do if the original study used the whole population or if there isn't funding to replicate the results.
* Perhaps journals are culpable here because "statistically significant, novel, and theoretically tidy results are published more easily than null, replication, or perplexing results" (Miguel et al). 

## Next-best thing: Reproducibility

When replicability is not feasible, reproducibility is a minimum standard for judging scientific claims.

(Peng 2011)

The research includes enough stuff that a different researcher can follow the same procedures in the same sample and come up with the same results.

## Why is reproducibility important?
* Reproducible does not mean results aren't wrong.
* Reproducible does not mean results are credible. 
* Reproducibility does not mean results are not sensitive to methods.
* But it exposes these things so peers can spot them and improve scientific consensus.

## Why is reproducibility important?
> - If you know somebody else might look, your code might magically become more organized
> - Improves collaboration
> - Who is your most important collaborator?
> - Revise and resubmit. Make it easier for Future You.

---

You could get hit by a bus.

<img src="gfx/bus2.jpg" altw="Don't get hit by a bus." height="450px" align="right"/>

## Traditional (non-reproducible) workflow 

<div class="centered">
<img src="gfx/workflow1.png" alt="Traditional workflow" width="700px"/>
</div>

## Reproducible workflow 

<div class="centered">
<img src="gfx/workflow2.png" alt="Reproducible workflow" width="700px"/>
</div>

## Minimum components of a reproducible workflow
* Data
* Code
* Software (including versions)
* Presentation (manuscript, slide deck, or whatever)
* Documentation that explains how all the pieces are connected
	
## Tools
  * Data:
    + X Drive
    + Data dictionary 
        + Names of data files and what they contain
        + Columns used in analysis
        + Names and definitions of data columns
        + Value labels and coding conventions for categorical variables
        
## Tools
  * Code:
    + R
  *	Software:
    + R
    + R packages
    + Code comments or Word document to keep track of versions
    
## Tools    
  * Presentation:
    + MS Word
    + MS Powerpoint
    + Whatever
  * Documentation:
    + MS Word
    + Code comments

## More ideal components of a reproducible workflow
* Data
* Code
* Software (including versions)
* Presentation (manuscript, slide deck, or whatever)
* Documentation that explains how all the pieces are connected
* An elegant way to package all of this
	
## Tools
* Data:
    + Git/GitHub
    + Make files and R make-like files
    + Data dictionary
* Code: 
    + RStudio (is anybody using R without RStudio?)
    + tidyverse
    + Master script
	  
## Tools
* Software:
	  + R
	  + packrat
* Presentation:
	  + knitr
	  + RMarkdown
	  + LaTeX
* Documentation:
	  + knitr
	  + RMarkdown
    + Git/GitHub

## A literate document

```{r echo=FALSE, results="hide" , message=FALSE} 
library ("JM")
library("survminer")
library("survival")
data("aids.id")
```

```{r coxmodel , echo=TRUE, results="hide" , message=FALSE}
coxAids <- coxph(Surv(Time,death) ~ drug + gender + CD4 + AZT, 
                 data=aids.id) 
```

We examined survival time among `r length(aids.id$patient)` AIDS patients using a Cox proportional hazards model , adjusting for drug treatment group , gender , baseline CD4 lymphocyte count , and history of Zidovudine (AZT) tolerance or
failure.

Significant predictors included baseline CD4 lymphocyte count
(HR: `r round(exp(coef(coxAids)[3]), 3)`,
95\% CI: `r round(exp(confint(coxAids)),3)[3,]`)
and history of AZT failure (HR: `r round(exp(coef(coxAids )[4]) , 3)`, 95\% CI: `r round(exp(confint(coxAids)),3)[4,]`).

## A literate document {.codetxt}
\`\`\`{r}

coxAids <- coxph(Surv(Time,death) ~ drug + gender + CD4 + AZT, data=aids.id) 
                 
\`\`\`

We examined survival time among <span style="color:red"> \` r length(aids.id$patient)\` </span> AIDS patients using a Cox proportional hazards model, adjusting for drug treatment group, gender, baseline CD4 lymphocyte count, and history of Zidovudine (AZT) tolerance or failure.

Significant predictors included baseline CD4 lymphocyte count
(HR: <span style="color:red">\` r round(exp(coef(coxAids)[3]), 3)\` </span>,
95\\\% CI: <span style="color:red">\` r round(exp(confint(coxAids)),3)[3,]\` </span>)
and history of AZT failure (HR: <span style="color:red">\` r round(exp(coef(coxAids )[4]) , 3)\` </span> , 95\\\% CI: <span style="color:red">\` r round(exp(confint(coxAids)),3)[4,]\` </span>).

## A literate document

```{r echo = TRUE, fig.height=3.75, fig.width=5}
fit <- survfit(Surv(Time, death) ~ drug, data = aids.id)
ggsurvplot(fit, data = aids.id, ylim = c(0.4, 1))
```

## A literate document {.codetxt}

\`\`\`{r}

fit <- survfit(Surv(Time, death) ~ drug, data = aids.id)

ggsurvplot(fit, ylim = c(0.4, 1))

\`\`\`

## File management
* Working folders
* Relative paths
* Getwd(), and setwd()
* RStudio projects

## Git/GitHub
<div class="centered">
<img src="gfx/Octocat.png" alt="Reproducible workflow" height="400px"/>
</div>

## Git on Exacloud
<span style="color:blue">Initialize Git in your local directory:</span>
<div style="background-color: #D3D3D3">
```
$ cd foo
$ git init
```
</div>

<span style="color:red">Initialize a repository on Exacloud:</span>
<div style="background-color: #D3D3D3">
```
$ mkdir foo.git
$ cd foo.git
$ git init --bare
```
</div>

## Git on Exacloud
<span style="color:blue">Tell your local Git where the remote repository is:</span>
<div style="background-color: #D3D3D3">
```
$ git remote add origin <username>@exacloud.ohsu.edu:<repo-name>.git
$ git remote -v
```
</div>

<span style="color:blue">Write your code locally. Save changes. Add new files to Git:</span>
<div style="background-color: #D3D3D3">
```
$ git add foobar.R
```
</div>

## Git on Exacloud

<span style="color:blue">Commit your changes locally and add a comment to mark your spot:</span>
<div style="background-color: #D3D3D3">
```
$ git commit -m "Added foobar.R"
```
</div>

<span style="color:blue">Push your changes to the remote repository on Exacloud:</span>
<div style="background-color: #D3D3D3">
```
$ git push origin master
```
</div>

## packrat
Initialize packrat for your R project:
<div style="background-color: #D3D3D3">
```
> library(packrat)
> packrat::init("~/projects/foobar")
```
</div>

Load your packages per usual routine:
<div style="background-color: #D3D3D3">
```
> install.packages("foo")
> library(foo)
```
</div>

Save a snapshot:
<div style="background-color: #D3D3D3">
```
> snapsnot()
```
</div>

Details here:
https://rstudio.github.io/packrat/

## Resources

* Gandrud C. *Reproducible Research with R and RStudio*. 2nd ed. 2015; CRC Press, Boca Raton, FL.
* Xie Y. *Dynamic Documents with R and knitr*. 2nd ed. 2015; CRC Press, Boca Raton, FL.
* Grolemond G, Wickham H. *R for Data Science*. 2017; O'Reilly Media, Sebastopol, California. 
* Ben Chan's analytic workflow for using Git on OHSU's Exacloud: https://github.com/benjamin-chan/workflow

## Thanks
I borrowed the concept for the workflow figures from Ben Chan, et al at the Center for Health Systems Effectiveness (CHSE). They gave a talk on reproducible research with knitr on July 22, 2015. 

