# Simulate drawdown scenarios for a retirement portfolio
# styler: off
simulate_drawdown <- function(
    initial_portfolio_value = 1000000,  # Initial portfolio value
    expected_return = 0.05,             # Expected yearly return (e.g., 5%)
    drawdown_period = 30,               # Number of years in the drawdown period
    historical_data = c(
        "data/stocks/sp500.csv",
        "data/bonds/10y_us_treasury.csv"
    ), # Path to the historical returns data file(s)
    investment_split = c(0.7, 0.3),     # Investment split between assets (e.g., 70% stocks, 30% bonds)
    max_payout = default_payout,        # Maximum payout function (e.g., $50,000 per year)
    num_simulations = 100000            # Number of simulations to run
) {
    # styler: on
    # Load historical returns data
    historical_returns <- lapply(historical_data, read.csv)

    # Ensure the historical returns are in the correct format
    for (i in seq_along(historical_returns)) {
        if (!"return" %in% colnames(historical_returns[[i]])) {
            stop("Historical data must contain a 'return' column.")
        }
    }

    # Extract the returns as a numeric vector
    returns <- lapply(historical_returns, function(x) x$return)

    # Initialize a matrix to store the simulated portfolio values
    payouts <- matrix(0, nrow = num_simulations, ncol = drawdown_period + 1)

    # Run simulations
    for (i in 1:num_simulations) {
        # Start with the initial portfolio value
        portfolio_value <- initial_portfolio_value * investment_split

        for (year in 1:drawdown_period) {
            total_value <- sum(portfolio_value)
            calc_payout <- total_value * annuity_rate(
                remaining_years = drawdown_period - year + 1,
                interest_rate = expected_return
            )
            payout <- max_payout(year)
            if (payout > 0) {
                calc_payout <- min(calc_payout, payout)
            }
            calc_payout <- round(calc_payout, 2)
            payouts[i, year] <- calc_payout

            # Randomly sample returns from the historical data for each asset class
            random_returns <- sapply(returns, function(x) sample(x, size = 1, replace = TRUE)) / 100

            total_value <- total_value - calc_payout
            portfolio_value <- total_value * investment_split
            portfolio_value <- portfolio_value * (1 + random_returns)
            portfolio_value <- round(portfolio_value, 2)
        }
        payouts[i, drawdown_period + 1] <- sum(portfolio_value)
    }

    payouts
}

# Example of a maximum payout function that adjusts for inflation at 3% per year
default_payout <- function(year) {
    starting_payout <- 66000
    starting_payout * 1.03^(year - 1)
}

annuity_rate <- function(remaining_years = 30, interest_rate = 0.05) {
    if (interest_rate < 0) {
        stop("Interest rate must be non-negative.")
    }

    interest_rate <- 1 + interest_rate
    (interest_rate^(remaining_years - 1) * (interest_rate - 1)) / (interest_rate^(remaining_years) - 1)
}

plot_drawdown <- function(payouts) {
    # sort the payouts by their total sum to get the worst-case scenarios at the top
    payouts <- payouts[order(rowSums(payouts)), ]

    samples <- nrow(payouts)

    # Calculate the median 10% and 90% quantiles of the payouts for each year
    payouts_median <- payouts[samples * 0.5, ]
    payouts_q05 <- payouts[samples * 0.05, ]
    payouts_q10 <- payouts[samples * 0.10, ]
    payouts_q15 <- payouts[samples * 0.15, ]
    payouts_q25 <- payouts[samples * 0.25, ]

    # Create a plot of calculated payouts over time
    jpeg("drawdown_plot.jpg", width = 800, height = 600)
    plot(
        seq_len(length(payouts_median) - 1),
        payouts_median[-length(payouts_median)],
        type = "l", col = "blue",
        xlab = "Year", ylab = "Median Payout", main = "Median Payout Over Time",
        ylim = c(0, max(payouts_median[-length(payouts_median)]) * 1.1)
    )
    lines(seq_len(length(payouts_q05) - 1), payouts_q05[-length(payouts_q05)], col = "darkred", lty = 2)
    lines(seq_len(length(payouts_q10) - 1), payouts_q10[-length(payouts_q10)], col = "red", lty = 2)
    lines(seq_len(length(payouts_q15) - 1), payouts_q15[-length(payouts_q15)], col = "orange", lty = 2)
    lines(seq_len(length(payouts_q25) - 1), payouts_q25[-length(payouts_q25)], col = "yellow", lty = 2)
    legend("topright",
        legend = c("Median", "5th Percentile", "10th Percentile", "15th Percentile", "25th Percentile"),
        col = c("blue", "darkred", "red", "orange", "yellow"), lty = c(1, 2, 2, 2, 2)
    )
    grid()

    # Add info about remaining portfolio value at the end of the drawdown period
    text(
        x = length(payouts_median) * 0.2, y = max(payouts_median[-length(payouts_median)]) * 0.9,
        labels = paste0(
            "Remaining Portfolio Value at Year ", ncol(payouts) - 1, ":\n",
            "Median: $", round(payouts_median[length(payouts_median)], 2), "\n",
            "5th Percentile: $", round(payouts_q05[length(payouts_q05)], 2), "\n",
            "10th Percentile: $", round(payouts_q10[length(payouts_q10)], 2), "\n",
            "15th Percentile: $", round(payouts_q15[length(payouts_q15)], 2), "\n",
            "25th Percentile: $", round(payouts_q25[length(payouts_q25)], 2), "\n"
        ),
        cex = 0.8, col = "black"
    )

    dev.off()
}
