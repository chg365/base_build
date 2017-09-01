<?php
$server = 'tls://github.com';
$port = 443;
$errno = 0;
$errstr = '';
$fp = fsockopen($server, $port, $errno, $errstr);
$flag = 1;
if ($fp) {
    $flag = 0;
    fclose($fp);
}
exit($flag);
