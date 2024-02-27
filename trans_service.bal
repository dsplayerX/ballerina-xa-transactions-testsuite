import ballerina/http;
// import ballerina/io;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

service / on new http:Listener(9896) {
    final mysql:Client testDB;
    function init() returns error? {
        self.testDB = check new (host = "localhost", user = "root", password = "root", port = 3306, database = "test", connectionPool = pool, options = {useXADatasource: true});
    }

    transactional resource function get hola(http:Caller caller, string name) {
        http:Response res = new;
        res.setTextPayload("Hola, " + name + "!");
        checkpanic caller->respond(res);
    }
}

