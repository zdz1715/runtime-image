<?php

$server = "";
$database = "";

$user = "";
$password = "";

$dsn = "sqlsrv:server=$server;Database=$database;Encrypt=no";

$pdo = new PDO($dsn,$user, $password);

$pdo->setAttribute(pdo::ATTR_ERRMODE, pdo::ERRMODE_EXCEPTION);

$sql="select 1";

$stmt=$pdo->prepare($sql);

try {
    $stmt->execute();
} catch (PDOException $e){
    echo $e->getMessage();
}

$res = $pdo->query($sql);

while ($row = $res->fetch()){
    print_r($row);
}
