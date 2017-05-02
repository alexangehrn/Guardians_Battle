<?php
require_once __DIR__ . '/vendor/autoload.php';

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Silex\Application;

function guidv4($data)
{
    assert(strlen($data) == 16);

    $data[6] = chr(ord($data[6]) & 0x0f | 0x40); // set version to 0100
    $data[8] = chr(ord($data[8]) & 0x3f | 0x80); // set bits 6-7 to 10

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
}

function generate_token() {
    $d = time();
    return $d."-".sha1("".$d)."-".guidv4(openssl_random_pseudo_bytes(16));
}

function isTokenExpired($app, $token) {
    if(strlen($token) < 10) return true;

    $arrayd = (explode("-", $token));
    $d = $arrayd[0];
    $delta = abs(time() - (int)$d);

    if($delta < (7 * 24 * 3600))
        return false;

    return true;
}

function isTokenValid($app, $token) {
    if(isTokenExpired($app, $token)) return false;

    $pdo = $app["PDO"];
    foreach ($pdo->query("SELECT * FROM tokens INNER JOIN users ON (users.userid = tokens.userid) WHERE token LIKE '$token'") as $row) {
        return true;
    }

    return false;
}

function getUserFromToken($app, $token) {
    $pdo = $app["PDO"];
    foreach ($pdo->query("SELECT * FROM tokens INNER JOIN users ON (users.userid = tokens.userid) WHERE token LIKE '$token'") as $row) {
        return $row['userid'];
    }

    return -1;
}

function getAvailableBeaconIDs($app) {
    $res = array();

    $pdo = $app["PDO"];
    foreach ($pdo->query("SELECT beaconid FROM beacons") as $row) {
        $res[] = $row['beaconid'];
    }

    return $res;
}

function error401() {
    $response = new Response();
    $response->headers->set('WWW-Authenticate', sprintf('Basic realm="%s"', 'WS2016'));
    $response->setStatusCode(401, 'Please sign in.');
    return $response;
}

function error409() {
    $response = new Response();
    $response->setStatusCode(409, 'Conflict');
    return $response;
}

function error404() {
    $response = new Response();
    $response->setStatusCode(404, 'Not found');
    return $response;
}

function error500() {
    $response = new Response();
    $response->setStatusCode(500, 'Internal error');
    return $response;
}

$app = new Silex\Application();


$app->GET('/api/hello', function(Application $app, Request $request) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }

    if (!isTokenExpired($app, $token)) {
        $pdo = $app["PDO"];
        foreach ($pdo->query("SELECT * FROM tokens INNER JOIN users ON (users.userid = tokens.userid) WHERE token LIKE '$token'") as $row) {
            return new Response("Welcome {$row['username']}!");
        }
    }

    return error401();
});


$app->GET('/api/renew', function(Application $app, Request $request) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenExpired($app, $token)) {
        $pdo = $app["PDO"];
        foreach ($pdo->query("SELECT * FROM tokens INNER JOIN users ON (users.userid = tokens.userid) WHERE token LIKE '$token'") as $row) {
            $token2 = generate_token();
            $d = array('uid' => $row['userid'], 'token' => $token2);

            $pdo->exec("INSERT INTO tokens (userid, token) VALUES ({$row['userid']}, '$token2')") or die("DB Error");

            return new Response(json_encode($d));
        }

    }


    return error401();
});

$app->GET('/', function(Application $app, Request $request){
    return new Response('Nothing to see here');
});

$app->POST('/login', function(Application $app, Request $request) {

    $username = $request->get('username');    $password = $request->get('password');

    $pdo = $app["PDO"];
    foreach( $pdo->query("SELECT * FROM users WHERE username LIKE '$username'") as $row) {
        if($row['password'] === $password) {
            $token = generate_token();
            $d = array('uid' => $row['userid'], 'token' => $token);

            $pdo->exec("INSERT INTO tokens (userid, token) VALUES ({$row['userid']}, '$token')") or die("DB Error");

            return new Response(json_encode($d));
        }
    }

    $response = new Response();
    $response->headers->set('WWW-Authenticate', sprintf('Basic realm="%s"', 'WS2016'));
    $response->setStatusCode(401, 'Please sign in.');
    return $response;
});


$app->POST('/register', function(Application $app, Request $request) {

    $username = $request->get('username');    $password = $request->get('password'); $usermail = $request->get('usermail'); $useravatar = $request->get('useravatar');

    $usernameExists = false;
    $pdo = $app["PDO"];
    foreach( $pdo->query("SELECT * FROM users WHERE username LIKE '$username'") as $row) {
        $usernameExists = $usernameExists || true;
    }

    if($usernameExists)
        return error409();

    $pdo->exec("INSERT INTO users (username, password, usermail, useravatar) VALUES ('$username', '$password', '$usermail', '$useravatar')") or die("DB Error");

    foreach( $pdo->query("SELECT * FROM users WHERE username LIKE '$username'") as $row) {
        $token = generate_token();
        $d = array('uid' => $row['userid'], 'token' => $token);

        $pdo->exec("INSERT INTO tokens (userid, token) VALUES ({$row['userid']}, '$token')") or die("DB Error");

        return new Response(json_encode($d), 200, array('Content-Type' => 'application/json'));
    }

    return error500();
});

////////////////////////////////////////// Code spécifiq Guardia's Battle \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

$app->GET('/api/userSettings', function(Application $app, Request $request){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

    $user = array();
    foreach( $pdo->query("SELECT * FROM users WHERE userid = '$userid'") as $row) {
        $user[] = array('username' => $row['username'], 'usermail' => $row['usermail'], 'password' => $row['password'], 'useravatar' => $row["useravatar"]);
    }

    return new Response(json_encode($user), 200, array('Content-Type' => 'application/json'));


});

$app->GET('/api/getMonuments', function(Application $app, Request $request){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $pdo = $app["PDO"];

    $monuments = array();
    foreach( $pdo->query("SELECT * FROM GB_monuments") as $row) {
        $monuments[] = array('monument_level' => $row['monument_level'], 'monument_attack' => $row['monument_attack'], 'monument_name' => $row['monument_name'], 'monument_image' => $row['monument_image'], 'monument_guardian_name' => $row['monument_guardian_name'], 'lattitude' => $row['lattitude'], 'longitude' => $row['longitude'], 'tag' => $row['tag']);
    }

    return new Response(json_encode($monuments), 200, array('Content-Type' => 'application/json'));
});

$app->POST('/api/addMonument/{monumentid}', function(Application $app, Request $request, $monumentid){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

    $pdo->exec("INSERT INTO GB_monumentUser (monumentid, userid) VALUES ('$monumentid','$userid')") or die("DB Error");

    return new Response('{}', 200, array('Content-Type' => 'application/json'));

});

$app->POST('/api/addAttacks/{attackid}', function(Application $app, Request $request, $attackid){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $attackid = filter_var($attackid, FILTER_SANITIZE_NUMBER_INT);

    $row = $app["PDO"];

    $row->query("SELECT * FROM GB_attackUser WHERE userid = '$userid' AND attackid = '$attackid'");

    if(!$row){

        $pdo = $app["PDO"];

        $pdo->exec("INSERT INTO GB_attackUser (attackid, userid) VALUES ($attackid,$userid)") or die("DB Error");

        return new Response('{}', 200, array('Content-Type' => 'application/json'));
    }
    else{

    //    $nombre_attack = $row['nombre_attack'] + 1;

        $update = $app["PDO"];

        $update->exec("UPDATE GB_attackUser SET nombre_attack = nombre_attack + 1 WHERE userid = '$userid' AND attackid = '$attackid'");

        return new Response('{}', 200, array('Content-Type' => 'application/json'));
    }

});

$app->GET('/api/delAttack/{attackid}', function(Application $app, Request $request, $attackid){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $attackid = filter_var($attackid, FILTER_SANITIZE_NUMBER_INT);

    $pdo = $app["PDO"];

    $nombre_attack = array();

    foreach( $pdo->query("SELECT * FROM GB_attackUser WHERE userid = '$userid' AND attackid = '$attackid'") as $row) {

        $nombre_attack[] = array('nombre_attack' => $row['nombre_attack']);
    }

    $pdo2 = $app["PDO"];

    if($nombre_attack[0] != "0"){

   //     $nbre_attack = $nombre_attack[0] - 1;

        $pdo2->exec("UPDATE GB_attackUser SET nombre_attack = nombre_attack - 1 WHERE userid = '$userid' AND attackid = '$attackid'") or die("DB Error");

        return new Response('{}', 200, array('Content-Type' => 'application/json'));
    }
    else{

        return error401();
    }


});

/*$app->GET('/api/countAttacks/{monumentid}', function(Application $app, Request $request, $monumentid){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $monumentid = filter_var($monumentid, FILTER_SANITIZE_NUMBER_INT);

    $pdo = $app["PDO"];
    $pdo->query("SELECT count(*) FROM GB_monumentAttack WHERE monumentid = '$monumentid'");

    return new Response(json_encode($pdo), 200, array('Content-Type' => 'application/json'));

});*/

$app->GET('/api/monumentAttacks/{monumentid}', function(Application $app, Request $request, $monumentid){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $monumentid = filter_var($monumentid, FILTER_SANITIZE_NUMBER_INT);

    $pdo = $app["PDO"];
    $res = array();

    foreach( $pdo->query("SELECT * FROM GB_monumentAttack WHERE monumentid = '$monumentid'") as $row) {

        $res[] = array('attackid' => $row['attackid']);
    }

    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));

});


$app->GET('/api/getAttacks', function(Application $app, Request $request){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $pdo = $app["PDO"];

    $res = array();

    foreach( $pdo->query("SELECT * FROM GB_attacks") as $row) {

        $res[] = array('attack_name' => $row['attack_name'], 'attack_damage' => $row['attack_damage'], 'attack_image' => $row['attack_image']);
    }
    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));

});

$app->GET('/api/getAttacksUser', function(Application $app, Request $request){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

    $res = array();

    foreach( $pdo->query("SELECT * FROM GB_attacks, GB_attackUser WHERE userid = '$userid' AND ID_attack = attackid") as $row) {

        $res[] = array('attack_name' => $row['attack_name'], 'attack_damage' => $row['attack_damage'], 'attack_image' => $row['attack_image'], 'nombre_attack' =>$row["nombre_attack"], 'attackid' => $row["attackid"]);

    }

    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));

});

$app->GET('/api/getMonumentsUser', function(Application $app, Request $request){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

    $res = array();

    foreach( $pdo->query("SELECT * FROM GB_monuments, GB_monumentUser WHERE userid = '$userid' AND ID_monument = monumentid") as $row) {

        $res[] = array('monument_level' => $row['monument_level'], 'monument_attack' => $row['monument_attack'], 'monument_name' => $row['monument_name'], 'monument_image' => $row['monument_image']);
    }

    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));

});

$app->DELETE('/api/deleteUser', function(Application $app, Request $request){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

    $pdo->exec("DELETE FROM users WHERE userid = '$userid'");

    return new Response('Delete ok', 200, array('Content-Type' => 'application/json'));

});

$app->POST('/api/updateUser', function(Application $app, Request $request){


    if (null === $token = $request->headers->get('S-Token')) {
      return "testsdfsdfs";exit;

        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }
    $username = $request->get('username');  $password = $request->get('password'); $usermail = $request->get('usermail'); $useravatar = $request->get('useravatar');

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

    $pdo->exec("UPDATE users SET username = '$username', password = '$password', usermail = '$usermail', useravatar = '$useravatar' WHERE userid = '$userid' ");

    $user = array();
    foreach( $pdo->query("SELECT * FROM users WHERE userid = '$userid'") as $row) {
        $user[] = array('username' => $row['username'], 'usermail' => $row['usermail'], 'password' => $row['password'], 'useravatar' => $row["useravatar"]);
    }

    return new Response(json_encode($user), 200, array('Content-Type' => 'application/json'));



});

$app->GET('/api/getMonument/{beaconid}', function(Application $app, Request $request, $beaconid){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $pdo = $app["PDO"];

    foreach( $pdo->query("SELECT * FROM GB_monuments WHERE monument_beacon = '$beaconid'") as $row) {

        $res = array('ID_monument' => $row['ID_monument'], 'monument_level' => $row['monument_level'], 'monument_attack' => $row['monument_attack'], 'monument_name' => $row['monument_name'], 'monument_image' => $row['monument_image'], 'monument_guardian_name' => $row['monument_guardian_name'], 'monument_guardian_image' => $row['monument_guardian_image'], 'monument_guardian_damage' => $row['monument_guardian_damage'], 'lattitude' => $row['lattitude'], 'longitude' => $row['longitude'], 'tag' => $row['tag']);
    }
    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));

});

$app->GET('/api/getAvatar', function(Application $app, Request $request){
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $pdo = $app["PDO"];

    $res = array();

    foreach( $pdo->query("SELECT * FROM GB_avatars") as $row) {

        $res[] = array('avatar_image' => $row['avatar_image']);

    }

    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));

});

///////////////////////////////////////// Fin code spé \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

$app->GET('/api/beacons', function(Application $app, Request $request) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $pdo = $app["PDO"];

    $beacons = array();
    foreach( $pdo->query("SELECT * FROM beacons") as $row) {
        $beacons[] = array( 'major' => $row['major'], 'minor' => $row['minor'], 'id' => $row['beaconid']);
    }

    return new Response(json_encode($beacons), 200, array('Content-Type' => 'application/json'));
});


$app->POST('/api/beacons', function(Application $app, Request $request) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $beaconid = filter_var($request->get('beaconid'), FILTER_SANITIZE_NUMBER_INT);
    $date = $request->get('date');
    $pdo = $app["PDO"];
    $sanitized = null;
    if($date != null && strlen($date) > 0)
        $sanitized = new DateTime($date);

    $pdo->exec("INSERT INTO encounters (beaconid, userid, encounterdate) VALUES ($beaconid,$userid, '{$sanitized->format(DATE_ISO8601)}')") or die("DB Error");

    return new Response('{}', 200, array('Content-Type' => 'application/json'));
});


$app->DELETE('/api/beacons', function(Application $app, Request $request) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }
    $start = $request->get('start');    $end = $request->get('end');

    $datestart = null;
    if($start != null && strlen($start) > 0)
        $datestart = new DateTime($start);
    $datesend = null;
    if($end != null && strlen($end) > 0)
        $datesend = new DateTime($end);

    $query = "DELETE FROM encounters WHERE userid = $userid";
    if($datestart != null)
        $query = $query." AND encounterdate > '{$datestart->format(DATE_ISO8601)}'";
    if($datesend != null)
        $query = $query." AND encounterdate < '{$datesend->format(DATE_ISO8601)}'";

    $pdo = $app["PDO"];
    $pdo->exec($query) or die("DB Error");

    return new Response('{}', 200, array('Content-Type' => 'application/json'));
});


$app->POST('/api/beacons/{userid}', function(Application $app, Request $request, $userid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = filter_var($userid, FILTER_SANITIZE_NUMBER_INT);
    $start = $request->get('start');    $end = $request->get('end');
    $datestart = null;
    if($start != null && strlen($start) > 0)
        $datestart = new DateTime($start);
    $datesend = null;
    if($end != null && strlen($end) > 0)
        $datesend = new DateTime($end);

    $whereBidClause = "";
    foreach ( getAvailableBeaconIDs($app) as $bid) {
        if(strlen($whereBidClause) > 0) $whereBidClause = $whereBidClause." OR ";
        $whereBidClause = $whereBidClause."beaconid = $bid";
    }

    $query = "SELECT * FROM encounters WHERE userid = $userid AND ($whereBidClause)";
    if($datestart != null)
        $query = $query." AND encounterdate > '{$datestart->format(DATE_ISO8601)}'";
    if($datesend != null)
        $query = $query." AND encounterdate < '{$datesend->format(DATE_ISO8601)}'";

    $pdo = $app["PDO"];
    $res = array();

    foreach($pdo->query($query) as $row) {
        $jsondate = new DateTime($row['encounterdate']);
        $res[] = array('beaconid' => $row['beaconid'], 'userid' => $row['userid'], 'date' => $jsondate->format(DATE_ISO8601));
    }
    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));
});

$app->POST('/api/beacons/{beaconid}/encounters', function(Application $app, Request $request, $beaconid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $beaconid = filter_var($beaconid, FILTER_SANITIZE_NUMBER_INT);
    $start = $request->get('start');    $end = $request->get('end');
    $datestart = null;
    if($start != null && strlen($start) > 0)
        $datestart = new DateTime($start);
    $datesend = null;
    if($end != null && strlen($end) > 0)
        $datesend = new DateTime($end);

    $query = "SELECT * FROM encounters WHERE beaconid = $beaconid";
    if($datestart != null)
        $query = $query." AND encounterdate > '{$datestart->format(DATE_ISO8601)}'";
    if($datesend != null)
        $query = $query." AND encounterdate < '{$datesend->format(DATE_ISO8601)}'";

    $pdo = $app["PDO"];
    $res = array();

    foreach($pdo->query($query) as $row) {
        $jsondate = new DateTime($row['encounterdate']);
        $res[] = array('beaconid' => $row['beaconid'], 'userid' => $row['userid'], 'date' => $jsondate->format(DATE_ISO8601));
    }
    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));
});

$app->POST('/api/games', function(Application $app, Request $request) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $start = $request->get('start');    $end = $request->get('end');

    $datestart = null;
    if($start != null && strlen($start) > 0)
        $datestart = new DateTime($start);
    $datesend = null;
    if($end != null && strlen($end) > 0)
        $datesend = new DateTime($end);

    $query = "SELECT * FROM games WHERE enddate IS NULL";

    if($datestart != null)
        $query = $query." AND creationdate > '{$datestart->format(DATE_ISO8601)}'";
    if($datesend != null)
        $query = $query." AND creationdate < '{$datesend->format(DATE_ISO8601)}'";

    $pdo = $app["PDO"];
    $res = array();

    foreach($pdo->query($query) as $row) {
        if($row['startdate'] != null)
            $jsondateS = new DateTime($row['startdate']);
        else
            $jsondateS = null;
        if($row['enddate'] != null)
            $jsondateE = new DateTime($row['enddate']);
        else
            $jsondateE = null;
        $participants = array();
        foreach ($pdo->query("SELECT * FROM participants WHERE stillingame AND gameid = {$row['gameid']}") as $prow) {
            $participants[] = $prow['userid'];
        }
        $gamedic = array('id' => $row['gameid'], 'initiator' => $row['initiator'],
            'participants' => $participants
        );
        if($jsondateS != null)
            $gamedic['startDate'] = $jsondateS->format(DATE_ISO8601);
        if($jsondateE != null)
            $gamedic['endDate'] = $jsondateE->format(DATE_ISO8601);

        $res[] = $gamedic;
    }
    return new Response(json_encode($res), 200, array('Content-Type' => 'application/json'));
});

$app->POST('/api/games/new', function(Application $app, Request $request) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

    // close any active game
    $now = new DateTime();
    foreach( $pdo->query("UPDATE games SET enddate = '{$now->format(DATE_ISO8601)}' WHERE initiator = {$userid} AND enddate IS NULL") as $row) {

    }

    $pdo->exec("INSERT INTO games (initiator) VALUES ({$userid})");

    $game = null;
    $dtrecentPast = new DateTime("2 hours ago");
    foreach( $pdo->query("SELECT * FROM games WHERE initiator = {$userid} AND creationdate > '{$dtrecentPast->format(DATE_ISO8601)}' ORDER BY creationdate") as $row) {
        $game = $row;
    }

    if($game == null)
        return error500();

    $pdo->exec("INSERT INTO participants (gameid,userid) VALUES ({$game['gameid']}, {$userid})");

    if($game['startdate'] != null)
        $jsondateS = new DateTime($game['startdate']);
    else
        $jsondateS = null;
    if($game['enddate'] != null)
        $jsondateE = new DateTime($game['enddate']);
    else
        $jsondateE = null;
    $participants = array($userid);
    $gamedic = array('id' => $game['gameid'], 'initiator' => $game['initiator'],
        'participants' => $participants
    );
    if($jsondateS != null)
        $gamedic['startDate'] = $jsondateS->format(DATE_ISO8601);
    if($jsondateE != null)
        $gamedic['endDate'] = $jsondateE->format(DATE_ISO8601);

    return new Response(json_encode($gamedic), 200, array('Content-Type' => 'application/json'));
});


$app->POST('/api/games/{gameid}/join', function(Application $app, Request $request, $gameid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }
    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);

    $pdo = $app["PDO"];


// TODO
    return new Response('How about implementing apiGamesGameidJoinPost as a POST method ?');
});


$app->POST('/api/games/{gameid}/leave', function(Application $app, Request $request, $gameid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);

    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidLeavePost as a POST method ?');
});


$app->POST('/api/games/{gameid}/start', function(Application $app, Request $request, $gameid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);

    $pdo = $app["PDO"];

    $game = null;
    $dtrecentPast = new DateTime("2 hours ago");
    foreach( $pdo->query("SELECT * FROM games WHERE gameid = {$gameid} AND initiator = {$userid} ORDER BY creationdate") as $row) {
        $game = $row;
    }

    if($game == null)
        return error404();


// TODO
    return new Response('How about implementing apiGamesGameidStartPost as a POST method ?');
});


$app->POST('/api/games/{gameid}/stop', function(Application $app, Request $request, $gameid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $userid = getUserFromToken($app,$token);
    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);

// TODO
    return new Response('How about implementing apiGamesGameidStopPost as a POST method ?');
});
$app->GET('/api/games/{gameid}', function(Application $app, Request $request, $gameid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);
    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidGet as a GET method ?');
});

$app->POST('/api/games/{gameid}/{teamid}/join', function(Application $app, Request $request, $gameid, $teamid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }
    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);
    $teamid = filter_var($teamid, FILTER_SANITIZE_NUMBER_INT);
    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidTeamidJoinPost as a POST method ?');
});


$app->POST('/api/games/{gameid}/{teamid}/leave', function(Application $app, Request $request, $gameid, $teamid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);
    $teamid = filter_var($teamid, FILTER_SANITIZE_NUMBER_INT);
    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidTeamidLeavePost as a POST method ?');
});


$app->GET('/api/games/{gameid}/teams', function(Application $app, Request $request, $gameid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }
    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);
    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidTeamsGet as a GET method ?');
});

$app->POST('/api/games/{gameid}/{teamid}/join', function(Application $app, Request $request, $gameid, $teamid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);
    $teamid = filter_var($teamid, FILTER_SANITIZE_NUMBER_INT);
    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidTeamidJoinPost as a POST method ?');
});


$app->POST('/api/games/{gameid}/{teamid}/leave', function(Application $app, Request $request, $gameid, $teamid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);
    $teamid = filter_var($teamid, FILTER_SANITIZE_NUMBER_INT);
    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidTeamidLeavePost as a POST method ?');
});


$app->GET('/api/games/{gameid}/teams', function(Application $app, Request $request, $gameid) {
    if (null === $token = $request->headers->get('S-Token')) {
        return error401();
    }
    if(!isTokenValid($app, $token)) {
        return error401();
    }

    $gameid = filter_var($gameid, FILTER_SANITIZE_NUMBER_INT);
    $userid = getUserFromToken($app,$token);
    if($userid < 0) {
        return error401();
    }

    $pdo = $app["PDO"];

// TODO
    return new Response('How about implementing apiGamesGameidTeamsGet as a GET method ?');
});

$dbuser = "root";
$dbpass = "root";
$app['PDO'] = new PDO("mysql:host=localhost;dbname=webservice", $dbuser, $dbpass);

$app->run();
