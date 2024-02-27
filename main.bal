import ballerina/http;
import ballerina/io;
import ballerina/jballerina.java;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string hostname = ?;
configurable string username = ?;
configurable string password1 = ?;
configurable string password2 = ?;
configurable int port1 = 3306;
configurable int port2 = 3308;
configurable string database1 = "xaLocalDB";
configurable string database2 = "xaDockerDB";

sql:ConnectionPool pool = {
    maxOpenConnections: 5,
    maxConnectionLifeTime: 300,
    minIdleConnections: 0
};

boolean crashBeforeCommit = false;
boolean stopSqlServer = false;

int cellId = 1;

service / on new http:Listener(9090) {
    final mysql:Client localDB;
    final mysql:Client dockerDB;

    function init() returns error? {
        _ = check startServ();

        self.localDB = check new (host = hostname,
            user = username, password = password1,
            port = port1, database = database1,
            connectionPool = pool,
            options = {useXADatasource: true,
            ssl: {
                allowPublicKeyRetrieval: true
            }
            }
        );
        io:println("> Local database initialized.");

        self.dockerDB = check new (host = "localhost",
            user = username, password = password2,
            port = port2, database = database2,
            connectionPool = pool,
            options = {useXADatasource: true,
            ssl: {
            allowPublicKeyRetrieval: true
            }
            }
        );
        io:println("> Docker database initialized.");
    }

    // rollIt - forcefully rollback the transaction
    // crashIt - crash the transaction manager before notifyCommit
    // stopSql - stop the sql server before notifyCommit
    resource function get updateToChipiChipi(boolean crashIt = false, boolean stopSql = false, boolean rollIt = false) returns string|error {
        stopSqlServer = stopSql;
        if (!stopSqlServer) {
            _ = check startServ();
        }
        crashBeforeCommit = crashIt;
        io:println(" + Crash before commit: ", crashBeforeCommit);
        io:println(" + Stop SQL server: ", stopSqlServer);

        sql:ParameterizedQuery updateQuery1 = `UPDATE xaTesting SET hello = 'chipichipi' WHERE id = ${cellId}`;
        sql:ParameterizedQuery updateQuery2 = `UPDATE xaTesting SET hello = 'chipichipi' WHERE id = ${cellId}`;

        io:println("~ Start of transaction block");
        retry transaction {
            transaction:onCommit(commitHanlder);
            transaction:onRollback(rollbackHandler);
            sql:ExecutionResult execResult1 = check self.localDB->execute(updateQuery1);
            io:println("Affected row count: ", execResult1.affectedRowCount);
            sql:ExecutionResult execResult2 = check self.dockerDB->execute(updateQuery2);
            io:println("Affected row count: ", execResult2.affectedRowCount);

            // call transaldb from here
            http:Client httpClient = check new ("http://localhost:9896");
            http:Response response = check httpClient->get("/hola?name=chipi");
            if (response.statusCode != 200 && response.statusCode != 202) {
                io:println("Error: ", response.statusCode, " - ", response.reasonPhrase);
                io:println("> Rolling back...");
                rollback;
                return "transaction chipi failed";
            } else {
                io:println("Response: ", response.statusCode, " - ", response.reasonPhrase);
            }

            if (rollIt == true || execResult1.affectedRowCount == 0 || execResult2.affectedRowCount == 0) {
                io:println("> Rolling back...");
                rollback;
            } else {
                io:println("> Committing...");
                check commit;
            }
        }
        io:println("~ End of transaction block");
        _ = check startServ();
        io:println("Done.");

        return "transaction chipi completed";
    }

    resource function get updateToDubiDubi(boolean crashIt = false, boolean stopSql = false, boolean rollIt = false) returns string|error {
        stopSqlServer = stopSql;
        if (!stopSqlServer) {
            _ = check startServ();
        }
        crashBeforeCommit = crashIt;
        io:println(" + Crash before commit: ", crashBeforeCommit);
        io:println(" + Stop SQL server: ", stopSqlServer);

        sql:ParameterizedQuery updateQuery1 = `UPDATE xaTesting SET hello = 'dubidubi' WHERE id = ${cellId}`;
        sql:ParameterizedQuery updateQuery2 = `UPDATE xaTesting SET hello = 'dubidubi' WHERE id = ${cellId}`;

        io:println("~ Start of transaction block");
        retry transaction {
            transaction:onCommit(commitHanlder);
            transaction:onRollback(rollbackHandler);
            sql:ExecutionResult execResult1 = check self.localDB->execute(updateQuery1);
            io:println("Affected row count: ", execResult1.affectedRowCount);
            sql:ExecutionResult execResult2 = check self.dockerDB->execute(updateQuery2);
            io:println("Affected row count: ", execResult2.affectedRowCount);

            if (rollIt == true || execResult1.affectedRowCount == 0 || execResult2.affectedRowCount == 0) {
                io:println("> Rolling back...");
                rollback;
            } else {
                io:println("> Committing...");
                check commit;
            }
        }
        io:println("~ End of transaction block");
        _ = check startServ();
        io:println("> Done.");

        return "transaction dubi completed";
    }

    resource function get getCrash() returns boolean|error {
        return crashBeforeCommit;
    }

    resource function get stopSql() returns boolean|error {
        return stopSqlServer;
    }

}

isolated function commitHanlder('transaction:Info info) {
    http:Client crasherClient = checkpanic new ("http://localhost:9090");
    boolean crasher = checkpanic crasherClient->get("/getCrash");
    io:println(" + Crasher value: ", crasher);

    http:Client stopperClient = checkpanic new ("http://localhost:9090");
    boolean stopper = checkpanic stopperClient->get("/stopSql");
    io:println(" + Stopper value: ", stopper);

    if (crasher) {
        io:println("[Crash. No Stop.]");
        divideByZero(); // crashes here
    }
    if (stopper) {
        io:println("[No Crash. Stop Sql.]");
        _ = checkpanic stopServ();
    }
    io:println("[No Crash. No Stop.]");

    io:println("> TM committed.");
}

isolated function rollbackHandler(transaction:Info info, error? cause, boolean willRetry = false) {
    http:Client crasherClient = checkpanic new ("http://localhost:9090");
    boolean crasher = checkpanic crasherClient->get("/getCrash");
    io:println(" + Crasher value: ", crasher);

    http:Client stopperClient = checkpanic new ("http://localhost:9090");
    boolean stopper = checkpanic stopperClient->get("/stopSql");
    io:println(" + Stopper value: ", stopper);

    if (crasher) {
        io:println("[Crash. No Stop.]");
        divideByZero(); // crashes here
    }
    if (stopper) {
        io:println("[No crash. Stop Sql.]");
        _ = checkpanic stopServ();
    }
    io:println("[No crash. No Stop.]");

    io:println("> TM rollbacked.");
}

isolated function stopServ() returns boolean|error {
    io:println("> Stopping SQL...");
    http:Client stopClient = check new ("http://localhost:9292");
    boolean stopped = check stopClient->get("/stopSql");
    if (stopped) {
        io:println("> Stopped SQL server.");
    } else {
        io:println("> Failed to stop SQL server.");
    }
    return stopped;
}

isolated function startServ() returns boolean|error {
    io:println("> Starting SQL...");
    http:Client startClient = check new ("http://localhost:9292");
    boolean started = check startClient->get("/startSql");
    if (started) {
        io:println("> Started SQL server.");
    } else {
        io:println("> Failed to start SQL server.");
    }
    return started;
}

isolated function divideByZero() = @java:Method {
                        name: "divideByZero",
'class: "a.b.c.Foo"
} external;
