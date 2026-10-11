# DATABASE.md - Database Schema Reference

Database: SQLite (`app_database.db`), version: 3

## Tables

### User

| Column       | Type     | Constraints                |
| ------------ | -------- | -------------------------- |
| id           | TEXT     | PRIMARY KEY, NOT NULL      |
| email        | TEXT     |                            |
| phone        | TEXT     |                            |
| name         | TEXT     |                            |
| gender       | TEXT     |                            |
| birthdate    | TEXT     |                            |
| imageUrl     | TEXT     |                            |
| authProvider | TEXT     |                            |
| createdAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP  |
| updatedAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP  |

### Product

| Column      | Type     | Constraints                       |
| ----------- | -------- | --------------------------------- |
| id          | INTEGER  | PRIMARY KEY, NOT NULL             |
| createdById | TEXT     | FK → User(id)                     |
| name        | TEXT     |                                   |
| imageUrl    | TEXT     |                                   |
| stock       | INTEGER  |                                   |
| sold        | INTEGER  |                                   |
| price       | INTEGER  |                                   |
| description | TEXT     |                                   |
| createdAt   | DATETIME | DEFAULT CURRENT_TIMESTAMP         |
| updatedAt   | DATETIME | DEFAULT CURRENT_TIMESTAMP         |

### Transaction

| Column              | Type     | Constraints               |
| ------------------- | -------- | ------------------------- |
| id                  | INTEGER  | PRIMARY KEY, NOT NULL     |
| paymentMethod       | TEXT     |                           |
| customerName        | TEXT     |                           |
| description         | TEXT     |                           |
| createdById         | TEXT     | FK → User(id)             |
| receivedAmount      | INTEGER  |                           |
| returnAmount        | INTEGER  |                           |
| totalAmount         | INTEGER  |                           |
| totalOrderedProduct | INTEGER  |                           |
| createdAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### OrderedProduct

| Column        | Type     | Constraints               |
| ------------- | -------- | ------------------------- |
| id            | INTEGER  | PRIMARY KEY, NOT NULL     |
| transactionId | INTEGER  | FK → Transaction(id)      |
| productId     | INTEGER  | FK → Product(id)          |
| quantity      | INTEGER  |                           |
| stock         | INTEGER  |                           |
| name          | TEXT     |                           |
| imageUrl      | TEXT     |                           |
| price         | INTEGER  |                           |
| createdAt     | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt     | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### Record

Menyimpan data fitur: karyawan, absensi, shift kasir, HPP, dan pengeluaran. Kolom `store` berisi `employees`,
`attendance`, `shifts`, `hpp`, atau `expenses`; kolom `data` berisi JSON.

| Column    | Type     | Constraints                           |
| --------- | -------- | ------------------------------------- |
| userId    | TEXT     | NOT NULL, bagian dari PRIMARY KEY     |
| store     | TEXT     | NOT NULL, bagian dari PRIMARY KEY     |
| id        | TEXT     | NOT NULL, bagian dari PRIMARY KEY     |
| data      | TEXT     | NOT NULL                              |
| createdAt | DATETIME | DEFAULT CURRENT_TIMESTAMP             |
| updatedAt | DATETIME | DEFAULT CURRENT_TIMESTAMP             |

## Migrations

| Version | Changes                  |
| ------- | ------------------------ |
| 2       | Drop `QueuedAction` table |
| 3       | Add `Record` table        |
