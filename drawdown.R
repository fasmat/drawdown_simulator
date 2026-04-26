# Simulate drawdown scenarios for a retirement portfolio
simulate_drawdown <- function(
  initial_portfolio_value = 1000000,        # Initial portfolio value
  expected_return = 0.05,                   # Expected yearly return (e.g., 5%)
  drawdown_period = 30,                     # Number of years in the drawdown period
  historical_data_file = "sp500.csv",       # Path to the historical returns data file
  max_payout = default_payout,              # Maximum payout function (e.g., $50,000 per year)
  num_simulations = 10000                   # Number of simulations to run
) {
    # Load historical returns data
    historical_returns <- read.csv(historical_data_file)
    
    # Ensure the historical returns are in the correct format
    if (!"return" %in% colnames(historical_returns)) {
        stop("Historical data must contain a 'return' column.")
    }
    
    # Extract the returns as a numeric vector
    returns <- historical_returns$return
    
    # Initialize a matrix to store the simulated portfolio values
    payouts <- matrix(0, nrow = num_simulations, ncol = drawdown_period+1)
    
    # Run simulations
    for (i in 1:num_simulations) {
        # Start with the initial portfolio value
        portfolio_value <- initial_portfolio_value
        
        for (year in 1:drawdown_period) {
            calc_payout <- portfolio_value * annuity_rate(
                remaining_years = drawdown_period - year + 1,
                interest_rate = expected_return
            )
            payout <- max_payout(year)
            if (payout > 0) {
                calc_payout <- min(calc_payout, payout)
            }
            calc_payout <- round(calc_payout, 2)
            payouts[i, year] <- calc_payout

            # Randomly sample a return from the historical returns
            random_return <- sample(returns, size = 1, replace = TRUE)/100
            
            portfolio_value <- portfolio_value - calc_payout
            portfolio_value <- portfolio_value * (1 + random_return)
            portfolio_value <- round(portfolio_value, 2)
        }
        payouts[i, drawdown_period+1] <- portfolio_value
    }
    
    return(payouts)
}

# Example of a maximum payout function that adjusts for inflation at 3% per year
default_payout <- function(year) {
    starting_payout <- 65000
    return(starting_payout * 1.03^(year-1))
}

annuity_rate <- function(remaining_years = 30, interest_rate = 0.05) {
    if (interest_rate < 0) {
        stop("Interest rate must be non-negative.")
    }

    interest_rate <- 1 + interest_rate
    return((interest_rate^(remaining_years - 1) * (interest_rate-1)) / (interest_rate^(remaining_years)-1))
}

plot_drawdown <- function(payouts) {
    # Calculate the median 10% and 90% quantiles of the payouts for each year
    payouts_median <- apply(payouts[,1:(ncol(payouts)-1)], 2, median)
    payouts_q05 <- apply(payouts[,1:(ncol(payouts)-1)], 2, quantile, probs = 0.05)
    payouts_q10 <- apply(payouts[,1:(ncol(payouts)-1)], 2, quantile, probs = 0.10)
    payouts_q15 <- apply(payouts[,1:(ncol(payouts)-1)], 2, quantile, probs = 0.15)

    remaining_values <- payouts[, ncol(payouts)]
    remaining_median <- median(remaining_values)
    remaining_q05 <- quantile(remaining_values, probs = 0.05)
    remaining_q10 <- quantile(remaining_values, probs = 0.10)
    remaining_q15 <- quantile(remaining_values, probs = 0.15)
    
    # Create a plot of calculated payouts over time
    jpeg("drawdown_plot.jpg", width = 800, height = 600)
    plot(1:length(payouts_median), payouts_median, type = "l", col = "blue",
        xlab = "Year", ylab = "Median Payout", main = "Median Payout Over Time",
        ylim = c(0, max(payouts_median) * 1.1)
    )
    lines(1:length(payouts_q05), payouts_q05, col = "darkred", lty = 2)
    lines(1:length(payouts_q10), payouts_q10, col = "red", lty = 2)
    lines(1:length(payouts_q15), payouts_q15, col = "orange", lty = 2)
    legend("topright", legend = c("Median", "5th Percentile", "10th Percentile", "15th Percentile"),
           col = c("blue", "darkred", "red", "orange"), lty = c(1, 2, 2, 2))
    grid()

    # Add info about remaining portfolio value at the end of the drawdown period
    text(x = length(payouts_median) * 0.8, y = max(payouts_median) * 0.9, 
         labels = paste0("Remaining Portfolio Value at Year ", ncol(payouts)-1, ":\n",
                         "Median: $", round(remaining_median, 2), "\n",
                         "5th Percentile: $", round(remaining_q05, 2), "\n",
                         "10th Percentile: $", round(remaining_q10, 2), "\n",
                         "15th Percentile: $", round(remaining_q15, 2)), 
         cex = 0.8, col = "black")    

    dev.off()
}
