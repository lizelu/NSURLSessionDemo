<?php

function receiveStreamFile($receiveFile){   
    $streamData = isset($GLOBALS['HTTP_RAW_POST_DATA'])? $GLOBALS['HTTP_RAW_POST_DATA'] : ''; 
   
    if(empty($streamData)){ 
        $streamData = file_get_contents('php://input'); 
    } 
   
    if($streamData!=''){ 
        $ret = file_put_contents($receiveFile, $streamData, true); 
    }else{ 
        $ret = false; 
    } 
    return $ret;   
} 
 
//定义服务器存储路径和文件名

$receiveFile = "uploads/".time().".png"; 
echo $receiveFile;
$ret = receiveStreamFile($receiveFile); 
echo json_encode(array('success'=>(bool)$ret)); 


	// $file_name = $_FILES['myfile']['name'];
	// if ($file_name != '') {
	// 	echo $file_name;

	// 	$error = $_FILES['myfile']['error'];
	// 	if ($error > 0) {
	// 		echo 'upload_failure000';
	// 	} else {
	// 		move_uploaded_file($_FILES['myfile']['tmp_name'], "uploads/".$file_name);
	// 		echo 'upload_success';
	// 	}
	// } else {
	// 	echo 'upload_failure111';
	// }
	// echo 'upload_failure------';
?>