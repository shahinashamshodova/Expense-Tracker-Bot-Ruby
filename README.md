# Expense tracker bot for Telegram

The bot was built using **Ruby Telegram SDK** and uses a standalone **MySQL** server as the database. The environment is managed using dotenv. 

Here are the available commands:

- `/add <amount> <description> [date]` - Adds a new expense.
  - Example: `/add 50 Dinner 2024-09-15`
  - Example: `/add 50 Dinner`
  - If no date is given, today's date is used.

- `/remove <id>` - Removes an expense by ID.
  - Example: `/remove 3`

- `/last <number>` - Lists the most recent expenses.
  - Example: `/last 5`

- `/budget` - Checks if you are within your monthly budget.
  - Example: `/budget`

- `/update_budget <amount>` - Updates the budget.
  - Example: `/update_budget 1500`

- `/dbudget` - Checks if you are within your daily budget.
  - Example: `/dbudget`

- `/wbudget` - Checks if you are within your weekly budget.
  - Example: `/wbudget`

- `/date <date>` - Lists transactions for a specific date.
  - Example: `/date 2024-09-18`

- `/top <number>` - List the largest expenses.
  - Example: `/top 10`

- `/export` - Export as CSV.
  - Example: `/export`
