<?php
/**
 * Backend Bridge para ITI-BB - Versión DOCKERIZADA v2.3.0
 * Desarrollador: Adrian Siani Arellano
 * NOTA CRÍTICA: El host ahora es 'db', no 'localhost'.
 */

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// En Docker, usamos el nombre del servicio definido en docker-compose.yml
$host = "db"; 
$db_name = "itibb_db";
$username = "root";
$password = "root"; // Coincide con MYSQL_ROOT_PASSWORD del YAML

try {
    // La conexión se realiza a través de la red interna de Docker
    $conn = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $content = file_get_contents("php://input");
    $data = json_decode($content);

    if(!empty($data->id_activo)) {
        $rawDate = $data->fecha_reg ?? date("Y-m-d H:i:s");
        $formattedDate = date("Y-m-d H:i:s", strtotime($rawDate));

        $query = "INSERT INTO inventario_registros 
                  (id, id_institucional, nombre_equipo, categoria, marca_modelo, nro_serie, origen, estado, estado_documentacion, laboratorio, registrante, fecha_censo, observaciones, foto_url, gps_lat, gps_long) 
                  VALUES (:id, :id_inst, :nom, :cat, :mm, :ns, :ori, :est, :doc, :lab, :reg, :fc, :obs, :foto, :lat, :lon)";
        
        $stmt = $conn->prepare($query);

        $stmt->bindValue(":id", $data->id_activo); 
        $stmt->bindValue(":id_inst", $data->id_institucional ?? "N/A"); 
        $stmt->bindValue(":nom", $data->nombre_equipo);
        $stmt->bindValue(":cat", $data->categoria ?? "Informática");
        $stmt->bindValue(":mm", $data->marca_modelo);
        $stmt->bindValue(":ns", $data->nro_serie);
        $stmt->bindValue(":ori", $data->origen);
        $stmt->bindValue(":est", $data->estado);
        $stmt->bindValue(":doc", $data->estado_documentacion);
        $stmt->bindValue(":lab", $data->id_lab);
        $stmt->bindValue(":reg", $data->registrado_por);
        $stmt->bindValue(":fc", $formattedDate);
        $stmt->bindValue(":obs", $data->observaciones);
        $stmt->bindValue(":foto", $data->foto_url);
        $stmt->bindValue(":lat", $data->gps_lat);
        $stmt->bindValue(":lon", $data->gps_long);

        if($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["status" => "success", "message" => "Sincro Docker v2.3.0 Exitosa"]);
        }
    }
} catch(PDOException $e) {
    http_response_code(200); 
    if ($e->getCode() == 23000) {
        echo json_encode(["status" => "error", "message" => "El registro ya existe en el contenedor de DB."]);
    } else {
        echo json_encode(["status" => "error", "message" => "Fallo de conexión Docker-DB: " . $e->getMessage()]);
    }
}
?>