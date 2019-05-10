<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <title>Editor</title>
  <style type="text/css" media="screen">
    body {
        overflow: hidden;
    }
    #editor {
        margin: 0px;
        position: relative;
    	width: 90%;
    	min-width: 500px;
        max-width: 1000px;
    	height: 400px;
    }
  </style>
</head>

<body>

<%-- Attempted to use the old API but I couldn't figure out the configuration with multiple files
<%@ page import="java.io.*" %>
<%@ page import="com.google.appengine.tools.cloudstorage.*" %>
<%@ page import="java.nio.ByteBuffer" %>
<%! private final GcsService gcsService =
    GcsServiceFactory.createGcsService(
        new RetryParams.Builder()
            .initialRetryDelayMillis(10)
            .retryMaxAttempts(10)
            .totalRetryPeriodMillis(15000)
            .build());
%>
<%! 
 public void createFile(String code, String bucketName, String fileName) throws IOException {
	  String buffer = code;
	  GcsFileOptions instance = GcsFileOptions.getDefaultInstance();
	  GcsFilename bucketAndFile = new GcsFilename(bucketName, fileName);
	  GcsOutputChannel outputChannel;
	  gcsService.createOrReplace(bucketAndFile, instance, ByteBuffer.wrap(buffer.getBytes()));
	} 
%> 
 --%>

<%@ page import="java.io.*" %>
<%@ page import="static java.nio.charset.StandardCharsets.UTF_8" %>
<%@ page import="java.nio.file.*" %>
<%@ page import="com.google.cloud.storage.*" %>
<%! 
 public void createFile(String code, String bucketName, String folder, String fileName) throws IOException {
		// Create your service object
		Storage storage = StorageOptions.getDefaultInstance().getService();

		BlobId blobId = BlobId.of(bucketName, folder + fileName);
		BlobInfo blobInfo = BlobInfo.newBuilder(blobId).setContentType("text/x-python").build();
		Blob blob = storage.create(blobInfo, code.getBytes(UTF_8));
	} 
%> 

<%! 
 public void downloadFile(String bucketName, String folder, String fileName, String destFilePath) throws IOException {
	// The name of the bucket to access
	// String bucketName = "my-bucket";

	// The name of the remote file to download
	// String srcFilename = "file.txt";

	// The path to which the file should be downloaded
	// Path destFilePath = Paths.get("/local/path/to/file.txt");

	// Instantiate a Google Cloud Storage client
	Storage storage = StorageOptions.getDefaultInstance().getService();

	// Get specific file from specified bucket
	Blob blob = storage.get(BlobId.of(bucketName, folder + fileName));

	// Download file to specified path
	blob.downloadTo(Paths.get(destFilePath));
	} 
%> 

<%!
 public void renameFile(String bucketName, String folder, String fileName, String newFileName) throws IOException {
/* 	// Instantiate a Google Cloud Storage client
	Storage storage = StorageOptions.getDefaultInstance().getService();
	Blob blob = storage.get(bucketName, folder + fileName);
	BlobInfo updatedInfo = blob.toBuilder()
		.setBlobId(BlobId.of(bucketName, folder + newFileName))
		.build();
	storage.update(updatedInfo);
	} */
	Storage storage = StorageOptions.getDefaultInstance().getService();
	Blob blob = storage.get(bucketName, folder + fileName);
	CopyWriter copyWriter = blob.copyTo(bucketName, folder + newFileName);
	Blob copiedBlob = copyWriter.getResult();
	boolean deleted = blob.delete();
	}
%>

<%
	session.setAttribute("time", request.getParameter("time"));
	String time = (String) session.getAttribute("time");
	session.setAttribute("code", request.getParameter("code"));
	String code = (String) session.getAttribute("code");
	session.setAttribute("isAudioOn", request.getParameter("isAudioOn"));
	String isAudioOn = (String) session.getAttribute("isAudioOn");
	session.setAttribute("isRecording", request.getParameter("isRecording"));
	String isRecording = (String) session.getAttribute("isRecording");

  	String result = "";
	if (code != null && !code.isEmpty()) {

		String problemNumber = "1";
		String filename = "solution" + problemNumber + ".py";
		createFile(code, "self-pace", "tests/", filename);

		String path = "/Users/kj/git/editor/checker/WebContent/WEB-INF/data/python/solution1.py";
		downloadFile("self-pace", "tests/", filename, path);

		String cmd = "/Users/kj/git/editor/checker/WebContent/WEB-INF/data/python/";
		String py = "test1";
		String run = "python  " + cmd + py + ".py";

		Process p = Runtime.getRuntime().exec(run);
		p.waitFor();
		BufferedReader bri = new BufferedReader(new InputStreamReader(p.getInputStream()));
		BufferedReader bre = new BufferedReader(new InputStreamReader(p.getErrorStream()));
		String line = "";
		while ((line = bri.readLine()) != null) {
			result += "\n" + line;
		}
		bri.close();
		while ((line = bre.readLine()) != null) {
			result += "\n" + line;
		}
		bre.close();
		p.waitFor();
		System.out.println(result);
		System.out.println("<----------------------->\n");
		p.destroy();

		String newFileName = "solution" + problemNumber + " " + time + " " + isAudioOn + ".py";

		//check if the last characters in the result stream are "OK"
		boolean passed = "OK".equals(result.substring(Math.max(result.length() - 2, 0)));
		if (passed) {
			newFileName = "SUCCESS: " + newFileName;
		} else {
			newFileName = "FAILURE: " + newFileName;
		}

		if (isRecording.equals("true")) {
			renameFile("self-pace", "tests/", filename, newFileName);
		} 
	}
	session.setAttribute("result", result);
	result = (String) session.getAttribute("result");
  %>

<audio id="audio" src="audio/white_noise.mp3" autoplay loop>
</audio>

<div>
	<a href="home.jsp" style="font-size: 40px">Home</a>
	<br><br>
</div>

<button onclick="stopRecording()">Opt Out</button>

<div>
<br>
<pre id="editor">
# Write a function that takes a non-empty list of integers,
# returns the largest element of the list
# You may not use any built-in function besides len()
	
def template(lst):
	
</pre>
<br>
</div> 

<form method="post" action="problem.jsp">
<button onclick="updateHiddenInputs()">Submit</button>
<input type="hidden" name="time" id="time" value='<%= time %>'>
<input type="hidden" name="code" id="code" value='<%= code %>'>
<input type="hidden" name="isAudioOn" id="isAudioOn" value='<%= isAudioOn %>'>
<input type="hidden" name="isRecording" id="isRecording" value='<%= isRecording %>'>
</form>

<span style="white-space: pre-line"> <%= result %> </span> 

<script src="ace-builds/src-noconflict/ace.js" type="text/javascript" charset="utf-8"></script>
<script src="js/FileSaver.js" type="text/javascript"></script>
<script>
	var editor = ace.edit("editor");
    editor.setTheme("ace/theme/twilight");
    editor.session.setMode("ace/mode/python"); 
    
	var startTime = Date.now();

	var isRecording = document.getElementById("isRecording").value;
	if (isRecording === 'null') {
		isRecording = true;
	}

	function coinFlip() {
		return (Math.floor(Math.random() * 2) == 0);
	}

	var isAudioOn = document.getElementById("isAudioOn").value;
	if (isAudioOn === 'null') {
		isAudioOn = coinFlip();
	} else {
		// cast to bool
		isAudioOn = (isAudioOn === 'true');
	}
	if (isAudioOn === false) {
		turnOffAudio();
	}

	var code = document.getElementById("code").value;
	if (code !== 'null') {
		editor.setValue(code, 1);
	}

	function stopRecording() {
		turnOffAudio();
		isRecording = false;
	}
	
	function turnOffAudio() {
		isAudioOn = false;
    	document.getElementById("audio").muted = true;
	}

    function updateHiddenInputs() {
    	var timeTaken = Date.now() - startTime;
    	var previousTimeTaken = document.getElementById("time").value;
    	if (previousTimeTaken === 'null') {
    		previousTimeTaken = '0';
    	}
    	document.getElementById("time").value = (timeTaken / 1000) + parseInt(previousTimeTaken);
    	
    	document.getElementById("code").value = editor.getValue();

    	document.getElementById("isAudioOn").value = isAudioOn;

    	document.getElementById("isRecording").value = isRecording;
    }
</script>

</body>
</html>