---
title: "Slurmming it in R"
author: "Kyle Hart"
date: "03 May 2017"
output:
  ioslides_presentation:
    css: styles.css
---

## It's highly addictive! 
![](gfx/slurm3_resized.jpg)

## What is this talk about?
* Very simple implementation of Slurm in R on Exacloud. 
* No details on tuning Slurm--we're sticking to default settings. 
* Focus on embarrassingly parallel tasks only.
* It's a simple demo of the <tt>**rslurm**</tt> package, which makes slurmming it in R easy. 

Details:

https://cran.r-project.org/web/packages/rslurm/vignettes/rslurm.html

## What is Slurm?
<img src="gfx/slurm_diagram.png" width="100%" style="display: block; margin: auto;" />

## Embarrassing parallel tasks
* No effort to split the processing among multiple processors
* No need to communicate or share results between tasks

**Embarrassing:** Have 10 nodes simulate 1000 datasets, run a single linear model on each dataset, and report the p-value for the first independent variable in each model.

**Less embarrassing:** Have 10 nodes simulate 1000 datasets, with the parameters of each dataset refined based on a summary of the previous dataset.

# The exacloud environment

## Connecting to exacloud
**On a PC:** http://www.putty.org/

**On a Mac:** ⌘-space > Terminal

<br><br>
**Secure shell:**

```
$ ssh exahead1.ohsu.edu
```


## Setting up the environment
* I had to install packages and dependencies one at a time. 
* <tt>install.packages("tidyverse")</tt> has never worked for me on Exacloud. I would welcome insights into this problem. 

## Directories to use
* For running parallelized scripts, put your data in <tt>/home/exacloud/lustre1/biostat/hartky</tt>.<span style="color:red;">*</span>
* Can also store your script on lustre, or you can put it in your home directory (<tt>/home/users/hartky</tt><span style="color:red;">*</span>)

<div class="footer">
\* If you are not <tt>**hartky**</tt>, replace that part with your own user name.
</div>

## Directories not to use
* Don't store your data on lustre when you're done with it. I put mine in <tt>/home/groups/biostats/hartky</tt><span style="color:red;">*</span>, but I don't know if that's the right thing to do. 
    + Discuss!
* Don't put any data in <tt>/home/users/hartky</tt><span style="color:red;">*</span> at any time. 
    + Doing so upsets the admins. 

<div class="footer">
\* If you are not <tt>**hartky**</tt>, replace that part with your own user name.
</div>

## Partitions
**Default:** Exacloud. All nodes except GPU. Time Limit: 36 hours. Preempt Action: Requeue. 

**mpi:** Infiniband-connected nodes. Time Limit: 14 days. Preempt Action: Requeue. 

**gpu:** GPU nodes. Time Limit: 14 days. Preempt Action: Requeue. 

**long_jobs:** 10gbps ethernet nodes. Time Limit: 10 days. Preempt Action: Requeue. Limits: 60 jobs running.

**very_long_jobs:** 10gbps ethernet nodes. Time Limit: 30 days. Preempt Action: Suspend.

# R package rslurm

## Motivating example
Fry, Leela, Bender, Zoidberg, and Amy deliver a lot of packages to the Alpha Centauri system. Leela and Fry have gotten into an argument about who is the better pilot and can deliver packages more quickly. To settle the dispute, we would like to conduct an RCT where each delivery is randomized to be piloted by either Fry or Leela. Professor Farnsworth is designing the study, and he thinks Leela gets the packages to Alpha Centauri on average 20 minutes faster than Fry. How many observations of deliveries do we need to have 80% power to detect a difference of 20 minutes in delivery time between the two pilots? 

<img src="gfx/Planet_express.png" width="20%" style="display: block; margin: auto 0 auto auto;" />

## Sample size
$H_1: \mu_1 - \mu_0 \ne 0$

If we set $\mu_0 = 240$, $\mu_1 = 220$, $\sigma_0 = \sigma_1 = 20$, and $n_1 = n_2$, we can solve for $n$ easily:

$$
\begin{align*}
n_1 = n_2 &= \frac{2\sigma^2(z_{1-\alpha/2} + z_{1-\beta})^2}{\mu_1 - \mu_0} \\[0.2in]
 &= \frac{2(20^2)(1.960 + 0.842)^2}{240 - 220} \\[0.2in]
 &\approx 16
\end{align*}
$$

## Sample size
$H_1: \mu_1 - \mu_0 \ne 0$

Could also use the black box:


```r
power.t.test(delta=20, sd=20, power=0.8)
```

```
## 
##      Two-sample t test power calculation 
## 
##               n = 16.71477
##           delta = 20
##              sd = 20
##       sig.level = 0.05
##           power = 0.8
##     alternative = two.sided
## 
## NOTE: n is number in *each* group
```

## Simulation
But let's pretend we want to use simulation instead. 

Generate a dataset; start with sample size $n = 10$:



```r
n <- 10
(sim_df <- tibble(x = c(rep(0, n/2), rep(1, n/2)),
                  y = 240 - (20 * x) + rnorm(n=n, mean=0, sd=20)))
```

```
## # A tibble: 10 x 2
##        x        y
##    <dbl>    <dbl>
##  1     0 227.5390
##  2     0 263.0122
##  3     0 245.2342
##  4     0 224.8448
##  5     0 219.1766
##  6     1 235.3668
##  7     1 213.7075
##  8     1 215.1101
##  9     1 215.2433
## 10     1 213.7202
```

## Simulation

```r
t.test(y ~ x, data=sim_df)
```

```
## 
## 	Welch Two Sample t-test
## 
## data:  y by x
## t = 1.9103, df = 6.0279, p-value = 0.1044
## alternative hypothesis: true difference in means is not equal to 0
## 95 percent confidence interval:
##  -4.843523 39.507126
## sample estimates:
## mean in group 0 mean in group 1 
##        235.9614        218.6296
```



It isn't significant at $\alpha=0.05$. 

## Simulation

Record results:

```r
sig_tests <- list(n_10 = c(0),
                  n_11 = c(),
                  n_12 = c(),
                  n_13 = c())
```

Repeat 100 times:


```
## $n_10
##   [1] 0 1 1 0 1 1 1 0 0 0 0 1 0 1 1 1 0 0 0 0 1 0 0 1 1 1 0 0 0 0 0 1 0 1 0
##  [36] 0 1 1 0 0 0 1 0 1 0 1 0 0 1 0 0 1 1 1 0 1 1 0 1 0 1 0 1 0 1 0 0 1 0 1
##  [71] 1 1 1 0 1 0 1 0 1 1 0 0 1 0 1 1 0 1 0 0 1 0 0 1 1 1 0 0 0 0 0
## 
## $n_11
## NULL
## 
## $n_12
## NULL
## 
## $n_13
## NULL
```

## Simulation

Solve for power:

```r
sum(sig_tests$n_10) / length(sig_tests$n_10)
```

```
## [1] 0.4653465
```

Increment $n$ by 2 and start over. Repeat until power $\ge 0.80$.

## Functionalize

```r
run_sim <- function(n) {
  sim_df <- tibble(x = c(rep(0, n/2), rep(1, n/2)),
                   y = 240 - (20 * x) + rnorm(n=n, mean=0, sd=20))
  result <- t.test(sim_df$y ~ sim_df$x)
  significant <- ifelse(result$p.value < 0.05, 
                        yes = 1,
                        no = 0)
  return(as.integer(significant))
}

run_sim(10)
```

```
## [1] 0
```

## Purrr 
Generate a vector of <tt>n_sims</tt> 10s. 

```r
n_sims <- 20
(sample_size <- rep(10, n_sims))
```

```
##  [1] 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10
```

Run the simulation function <tt>n_sims</tt> times.

```r
(test_results <- map_int(sample_size, run_sim))
```

```
##  [1] 0 0 0 1 1 1 0 0 0 0 1 0 0 0 1 0 0 0 1 0
```

Calculate power for sample size $n=10$.

```r
sum(test_results)/length(test_results)
```

```
## [1] 0.3
```

## Functionalize again

```r
calc_power <- function(n, n_sims) {
  sample_size <- rep(n, n_sims)
  test_results <- map_int(sample_size, run_sim)
  return(sum(test_results)/length(test_results))
}

pwr <- map_dbl(seq(10,40, by=2), calc_power, n_sims=100)

cbind(n=seq(10,40, by=2), pwr)
```

```
##        n  pwr
##  [1,] 10 0.24
##  [2,] 12 0.41
##  [3,] 14 0.45
##  [4,] 16 0.54
##  [5,] 18 0.49
##  [6,] 20 0.49
##  [7,] 22 0.63
##  [8,] 24 0.61
##  [9,] 26 0.70
## [10,] 28 0.74
## [11,] 30 0.78
## [12,] 32 0.78
## [13,] 34 0.83
## [14,] 36 0.83
## [15,] 38 0.89
## [16,] 40 0.86
```

## Do it in base R 
**<tt>lapply(X, FUN, ...)</tt>**


```r
calc_power_base <- function(n, n_sims) {
  sample_size <- rep(n, n_sims)
  test_results <- unlist(lapply(X=sample_size, FUN=run_sim))
  return(sum(test_results)/length(test_results))
}

pwr <- sapply(X=seq(10,40, by=2), FUN=calc_power_base, n_sims=100)

cbind(n=seq(10,40, by=2), pwr)
```

```
##        n  pwr
##  [1,] 10 0.27
##  [2,] 12 0.27
##  [3,] 14 0.42
##  [4,] 16 0.44
##  [5,] 18 0.50
##  [6,] 20 0.52
##  [7,] 22 0.67
##  [8,] 24 0.66
##  [9,] 26 0.68
## [10,] 28 0.67
## [11,] 30 0.72
## [12,] 32 0.85
## [13,] 34 0.85
## [14,] 36 0.85
## [15,] 38 0.88
## [16,] 40 0.91
```

## Do it in Slurm

```r
(sample_sizes <- seq(10,40, by=2))

(params_df <- data.frame(n = sample_sizes,
                        n_sims = rep(100, length(sample_sizes))))

sjob <- slurm_apply(f=calc_power_base, 
                    params=params_df,
                    jobname = "sample_size_job2",
                    nodes = 4, cpus_per_node = 2)
```

<div class="footer">
\* Unlike lapply, slurm_apply requires params to be passed as a data frame, with the column names matching the names of the parallelized function's parameters. 
</div>

## Namespaces

```r
(sample_sizes <- seq(10,40, by=2))

sjob <- slurm_apply(f=calc_power_base, 
                    params=params_df,
                    jobname = "sample_size_job2",
                    nodes = 4, cpus_per_node = 2)
```

Except this won't work. Why not?

## A slurm implementation that works

```r
calc_power_base <- function(n, n_sims) {
  sample_size <- rep(n, n_sims)
  test_results <- unlist(lapply(X=sample_size, FUN=function(n) {
    sim_df <- data.frame(x = c(rep(0, n/2), rep(1, n/2)),
                         y = batman(n))
    
    sim_df$y <- 240 - (20 * sim_df$x) + rnorm(n=n, mean=0, sd=20)
    
    result <- t.test(sim_df$y ~ sim_df$x)
    
    significant <- ifelse(result$p.value < 0.05, 
                          yes = 1,
                          no = 0)
    
    return(as.integer(significant))
  }))
  return(sum(test_results)/length(test_results))
}

sjob <- slurm_apply(f=calc_power_base, 
                    params=params_df,
                    jobname = "sample_size_job2",
                    nodes = 4, cpus_per_node = 2)
```

## Retrieving results

```r
print_job_status(sjob)
```


```r
(res <- get_slurm_out(sjob, outtype = "table"))

cbind(sample_sizes, res)
```

## Slurm options
The <tt>slurm_options</tt> argument passes options to Slurm's <tt>sbatch</tt> command. 

https://slurm.schedmd.com/sbatch.html


```r
sopt <- list(time = "1:00:00",
             `mail-type` = "END",
             `mail-user` = "hartky@ohsu.edu",
             #<b>
            partition = "exacloud"#</b>
)

sjob <- slurm_apply(f=calc_power_base, 
                    params=data.frame(n = sample_sizes,
                                      n_sims = rep(100, length(sample_sizes))), ## * 
                    jobname = "sample_size_job",
                    nodes = 2, cpus_per_node = 2,
                    #<b>
                  slurm_options = sopt#</b>
)
```

## Under the hood
<div style="background-color: #000000; color:lightgreen;">

```
exahead1 $ ls
_rslurm_sample_size_job
exahead1 $ cd _rslurm_sample_size_job/
exahead1 $ ls
f.RDS  params.RDS  results_0.RDS  results_1.RDS  slurm_0.out  slurm_1.out  slurm_run.R  submit.sh
exahead1 $ ls -l
total 12
-rw-r--r--. 1 hartky HPCUsers  980 Dec  4 12:25 f.RDS
-rw-r--r--. 1 hartky HPCUsers  174 Dec  4 12:25 params.RDS
-rw-r--r--. 1 hartky HPCUsers   95 Dec  4 12:26 results_0.RDS
-rw-r--r--. 1 hartky HPCUsers   98 Dec  4 12:26 results_1.RDS
-rw-r--r--. 1 hartky HPCUsers  362 Dec  4 12:26 slurm_0.out
-rw-r--r--. 1 hartky HPCUsers  362 Dec  4 12:26 slurm_1.out
-rw-r--r--. 1 hartky HPCUsers 1006 Dec  4 12:25 slurm_run.R
-rw-r--r--. 1 hartky HPCUsers  262 Dec  4 12:25 submit.sh
```

</div>


