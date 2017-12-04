library(tibble)
library(trahelyk)
library(rslurm)

####################################################################################################
run_sim <- function(n) {
  sim_df <- data.frame(x = c(rep(0, n/2), rep(1, n/2)),
                       y = batman(n))
  
  sim_df$y <- 240 - (20 * sim_df$x) + rnorm(n=n, mean=0, sd=20)
  
  result <- t.test(sim_df$y ~ sim_df$x)
  
  significant <- ifelse(result$p.value < 0.05, 
                        yes = 1,
                        no = 0)
  
  return(as.integer(significant))
}




####################################################################################################
run_sim <- function(n) {
  sim_df <- data.frame(x = c(rep(0, n/2), rep(1, n/2)),
                       y = batman(n))
  
  sim_df$y <- 240 - (20 * sim_df$x) + rnorm(n=n, mean=0, sd=20)
  
  result <- t.test(sim_df$y ~ sim_df$x)
  
  significant <- ifelse(result$p.value < 0.05, 
                        yes = 1,
                        no = 0)
  
  return(as.integer(significant))
}





####################################################################################################
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

####################################################################################################
(sample_sizes <- seq(10,40, by=2))
(params_df <- data.frame(n = sample_sizes,
                        n_sims = rep(100, length(sample_sizes))))

sjob <- slurm_apply(f=calc_power_base, 
                    params=params_df,
                    jobname = "sample_size_job2",
                    nodes = 4, cpus_per_node = 2)

print_job_status(sjob)

(res <- get_slurm_out(sjob, outtype = "table"))

cbind(sample_sizes, res)




sopt <- list(time = "1:00:00",
             `mail-type` = "END",
             `mail-user` = "hartky@ohsu.edu",
             partition = "exacloud")

sjob <- slurm_apply(f=calc_power_base, 
                    params=data.frame(n = sample_sizes,
                                      n_sims = rep(100, length(sample_sizes))), ## * 
                    jobname = "sample_size_job",
                    nodes = 2, cpus_per_node = 2,
                    slurm_options = sopt)