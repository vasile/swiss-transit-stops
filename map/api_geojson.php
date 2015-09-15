<?php

class JsonView {
    public static function dump($data) {
        if (ob_get_contents()) {
            var_dump("Output detected, please remove it before dumping JSON data");
            die;
        }
        
        if (isset($_SERVER['HTTP_ACCEPT_ENCODING']) && substr_count($_SERVER['HTTP_ACCEPT_ENCODING'], 'gzip')) {
            ob_start("ob_gzhandler");
        }  else {
            ob_start();
        }
        
        header(' ', true, 200);
        header('Content-Type: application/json; Charset=utf-8');
        
        header("Cache-Control: max-age=0, no-cache, no-store, must-revalidate");
        header("Pragma: no-cache");
        header("Expires: Thu, 01 Jan 1970 00:00:00 GMT");
        
        echo (is_string($data) ? $data : json_encode($data)) . "\n";
    }
}

define('APP_FOLDER_PATH', dirname(__FILE__));

if (isset($_GET['file'])) {
    $file = APP_FOLDER_PATH . '/' . $_GET['file'];
    if (file_exists($file)) {
        $json = file_get_contents($file);
    } else {
        error_log('GeoJSON error: ' . $file . ' not found !');
        $json = array(
            'error' => 'Cannot load ' . $_GET['file'] . ' !'
        );
    }
} else {
    $json = array(
        'error' => 'Missing file parameter, i.e. file=stations.geojson'
    );
}
JsonView::dump($json);