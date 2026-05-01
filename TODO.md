# Ideas for extending the drawdown simulation

- Add ability to split portfolio into different asset classes (e.g., stocks, bonds, cash) and simulate returns for each
  class separately. (e.g. 70% stocks, 30% bonds).
  - The money is always taken out in a way to get closest to the target distribution of the portfolio. For example, if
    the target distribution is 70% stocks and 30% bonds, and the portfolio is currently at 80% stocks and 20% bonds,
    then the money will be taken out from the stocks first to get closer to the target distribution.
