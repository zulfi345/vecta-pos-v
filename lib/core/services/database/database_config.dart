class DatabaseConfig {
  // Prevents instantiation and extension
  DatabaseConfig._();

  static const String dbPath = 'app_database.db';
  static const int version = 2;

  static const String userTableName = 'User';
  static const String productTableName = 'Product';
  static const String transactionTableName = 'Transaction';
  static const String orderedProductTableName = 'OrderedProduct';

  static const String createUserTable =
      '''
CREATE TABLE IF NOT EXISTS '$userTableName' (
    'id' TEXT NOT NULL,
    'email' TEXT,
    'phone' TEXT,
    'name' TEXT,
    'gender' TEXT,
    'birthdate' TEXT,
    'imageUrl' TEXT,
    'authProvider' TEXT,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id')
);
''';

  static const String createProductTable =
      '''
CREATE TABLE IF NOT EXISTS '$productTableName' (
    'id' INTEGER NOT NULL,
    'createdById' TEXT,
    'name' TEXT,
    'imageUrl' TEXT,
    'stock' INTEGER,
    'sold' INTEGER,
    'price' INTEGER,
    'description' TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('createdById') REFERENCES 'User' ('id')
);
''';

  static const String createTransactionTable =
      '''
CREATE TABLE IF NOT EXISTS '$transactionTableName' (
    'id' INTEGER NOT NULL,
    'paymentMethod' TEXT,
    'customerName' TEXT,
    'description' TEXT,
    'createdById' TEXT,
    'receivedAmount' INTEGER,
    'returnAmount' INTEGER,
    'totalAmount' INTEGER,
    'totalOrderedProduct' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('createdById') REFERENCES 'User' ('id')
);
''';

  static const String createOrderedProductTable =
      '''
CREATE TABLE IF NOT EXISTS '$orderedProductTableName' (
    'id' INTEGER NOT NULL,
    'transactionId' INTEGER,
    'productId' INTEGER,
    'quantity' INTEGER,
    'stock' INTEGER,
    'name' TEXT,
    'imageUrl' TEXT,
    'price' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('transactionId') REFERENCES 'Transaction' ('id'),
    FOREIGN KEY ('productId') REFERENCES 'Product' ('id')
);
''';

  static const List<String> createStatements = [
    createUserTable,
    createProductTable,
    createTransactionTable,
    createOrderedProductTable,
  ];

  static const String dropQueuedActionTable = 'DROP TABLE IF EXISTS QueuedAction';
}
