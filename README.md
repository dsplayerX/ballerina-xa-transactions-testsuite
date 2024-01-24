# Ballerina XA Transactions Test

This Ballerina project is designed to test and debug XA transaction recovery by simulating scenarios like crashing before notifying commit/rollback and database failures.

## Project Structure

- `main.bal` - Main Ballerina file with the XA transaction and logic to simulate crashes.
- `control_sql/control_mysql_service.bal` - Ballerina script with endpoints to stop and start the SQL service.

## Setup

1. Make sure you have Ballerina 2201.8 or newer and MySQL 8.1 or newer installed.
2. Set up the two MySQL databases on ports 3306 and 3308. (create necessary databases)

```sql
CREATE DATABASE m1;
CREATE TABLE m1.test1 (
  id INT NOT NULL AUTO_INCREMENT,
  hello VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
);
```

3. Add the required configuration values to `Config.toml` file.

```toml
hostname = ""
username = ""
password1 = ""
password2 = ""
```

## Running the Tests

1. Open a terminal and navigate to the project directory.
2. Run the Ballerina program:

   ```bat
   bal run
   ```

3. Open another terminal and run the Ballerina script for stopping and starting the SQL service _For Windows only. This Ballerina script should run with admin privilages._:
   ```bat
   bal run control_mysql_service.bal
   ```

## Endpoints

| **Endpoint**          | **Method** | **Parameters**                                                      |
| --------------------- | ---------- | ------------------------------------------------------------------- |
| `/updateToChipiChipi` | `GET`      | - `crashIt` (boolean): Simulate a crash before committing.          |
|                       |            | - `stopSql` (boolean): Stop the SQL service during the transaction. |
|                       |            | - `rollIt` (boolean): Rollback the transaction based on conditions. |
| `/updateToDubiDubi`   | `GET`      | - `crashIt` (boolean): Simulate a crash before committing.          |
|                       |            | - `stopSql` (boolean): Stop the SQL service during the transaction. |
|                       |            | - `rollIt` (boolean): Rollback the transaction based on conditions. |
| `/getCrash`           | `GET`      | Boolean indicating whether a crash is scheduled.                    |
| `/stopSql`            | `GET`      | Boolean indicating whether the SQL service was stopped.             |

### Simulating a Crash

To simulate a crash, the program triggers a crash just before committing a transaction. This is achieved by dividing by zero in a Java function (`divideByZero`) called through Ballerina's external function capability.

### Stopping SQL Service

The SQL service can be stopped using a separate Ballerina script (control_mysql_service.bal). Running the /stopSql endpoint will stop the SQL service, and running the /startSql endpoint will start it again.

## Usage

- Access the endpoints `/updateToChipiChipi` and `/updateToDubiDubi` to initiate transactions with different parameters.
- View the console output for logs on transaction progress and status.
