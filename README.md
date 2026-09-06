For my function 1 ~ 3
1. status check
2. input
3. input check
4. process
5. process check
6. update
7. display form
8. exit
9. status change


Core System & Menu Functions
1. MAIN             : The main entry point of the program; handles screen routing, login, and the main menu switch case.
2. REGISTER_MEMBER  : Handles new user registration, validates ID format (Mxxxx), checks for duplicates, and initializes records.
3. BORROW_BOOK      : Manages book catalog display, stock decrement, borrowing eligibility, and records the transaction.
4. SUBSCRIBE_TIER   : Processes membership purchases (Bronze, Silver, Gold), deducts balance, and sets the 30-day expiry.
5. RETURN_BOOK      : Scans for borrowed books, calculates overdue days, deducts late fines, restores book stock, and clears the borrow record.
6. TOP_UP           : Handles wallet balance top-ups and validates numeric input to prevent overflow.
7. PRINT_REPORT     : Parses REPORT.TXT to display the user's lifetime borrowed books, total fines, and total spending.

File & Data Management Helpers
1. UPDATE_REPORT_SPEND : Helper to add expenses (subscriptions/fines) to the user's total spend record.
2. UPDATE_REPORT_BOOKS : Helper to increment the user's total borrowed books count.
3. UPDATE_REPORT_FINE  : Helper to add paid fines to the user's historical fine record.
4. CHECK_EXPIRY_STATUS : Compares the system date against the user's expiry date and resets the tier to 'NONE' if expired.
5. SAVE_USER_DATA      : Locates the current user in ACCOUNT.TXT and overwrites their balance, tier, and expiry date with updated values.

UI & Utility Helpers
1. PRINT_USER_STATUS : Displays the active user's current balance, tier name, and expiry date on the main menu.
2. PRINT_BALANCE     : Fetches and prints the user's current wallet balance (RM).
3. PRINT_NUM         : Converts numeric data into ASCII characters and prints up to 3 digits (e.g., balances).
4. PRINT_2DIGIT      : Specifically formats and prints 2-digit numbers (used for DD/MM formatting).
5. READ_USERNAME     : Safely captures exactly 5 characters for the Member ID and clears keyboard buffers.
6. READ_PASSWORD     : Safely captures exactly 5 characters for the password, ignoring accidental Enter presses.
7. WAIT_KEY          : Prompts "Press any key to continue..." and pauses program execution.
8. CLEAR_SCREEN      : Triggers BIOS interrupt 10H to clear the console and reset the cursor to the top-left corner.


open windows cmd

=============== clone ===============

;for me

cd /d D:\System\Documents\assignment

git clone https://github.com/yuhang0824/DFT2S1G3_COMPUTER_ARCHITECTURE.git .

=============== branch ===============

;open branch

git branch

;change branch

git checkout

git merge main

=============== commit ===============

make sure you are in the branch, not in the main branch

git add .

git commit -m "<comment>"

git push
