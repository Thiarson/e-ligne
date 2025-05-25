// Sqlite database name
const dbName = 'finance.db';

// Table car and related fields
const carTable = 'car';

const carIdColumn = 'id';
const carRegistrationColumn = 'registration';

// Table income and related fields
const incomeTable = 'income';

const incomeIdColumn = 'id';
const incomeCarIdColumn = 'car_id';
const incomeDescriptionColumn ='description';
const incomeAmountColumn = 'amount';
const incomeSourceColumn = 'source';
const incomeDateColumn = 'date';

// Table expense and related fields
const expenseTable = 'expense';

const expenseIdColum = 'id';
const expenseCarIdColumn = 'car_id';
const expenseDescriptionColumn ='description';
const expenseAmountColumn = 'amount';
const expenseSourceColumn = 'source';
const expenseDateColumn = 'date';

// SQL statement to create table car
const createCarTable = '''CREATE TABLE IF NOT EXISTS "car" (
  "id" INTEGER NOT NULL,
  "registration" TEXT NOT NULL UNIQUE,
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

// SQL statement to create table income
const createIncomeTable = '''CREATE TABLE IF NOT EXISTS "income" (
  "id" INTEGER NOT NULL,
  "car_id" INTEGER NOT NULL,
  "description" TEXT NOT NULL,
  "amount" TEXT NOT NULL,
  "source" TEXT NOT NULL,
  "date" TEXT NOT NULL,
  FOREIGN KEY("car_id") REFERENCES "car"("id"),
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

// SQL statement to create table expense
const createExpenseTable = '''CREATE TABLE IF NOT EXISTS "expense" (
  "id" INTEGER NOT NULL,
  "car_id" INTEGER NOT NULL,
  "description" TEXT NOT NULL,
  "amount" TEXT NOT NULL,
  "source" TEXT NOT NULL,
  "date" TEXT NOT NULL,
  FOREIGN KEY("car_id") REFERENCES "car"("id"),
  PRIMARY KEY("id" AUTOINCREMENT)
);''';
