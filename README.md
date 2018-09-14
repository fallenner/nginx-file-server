## A file Server base on nginx.

### Describe
This is a file-server base on nginx-upload-module.

- Features:
    - Support storage file with custom path.
    - Automatic transcoding audio file to .mp3 file, video file to .mp4 file.
    - Automatic clean upload file when error Occurred.
    
### Install
1. Login with root user;
2. cd nginx-file-server/;
3. chmod +x upload.sh
4. ./upload.sh

### Document
---
- FrontEnd
    1. upload
        * API:
            http://fileServer:8090/upload
            
        * Method: POST
        
        * Header:
        
            | Key| Value | Required |
            | - | :-: | :-: |
            | token | 'custom by yourself' | true |
            
            
        * Params:
            The params must be passed by formData.it can pass some extra params to the callback handle program. like privateKey...
        
           | Name | Type | Required | Describe | Example |
           | - | :-: | :-: | :-: | :-: | 
           | pathRule | String | false | Define a storage path for upload file | other/1/2/3/
           | callback | String | false | Define a backend Handle program API path, it will trriger a http request(include the file information ) after upload finish. | http://backend/a/b/ |
           | targetFileName | String | false | Define a path(include fileName), if the file  exits on file server, it will be repalce by new upload file | other/1/2/3/1.jpg |
       
    2. Remove
        * API:
            http://fileServer:8090/remove
            
        * Method: POST
        
        * Header:
        
            | Key| Value | Required |
            | - | :-: | :-: |
            | token | 'custom by yourself' | true |
            
            
        * Params:
            The params must be passed by formData. it can pass some extra params to the callback handle program. like privateKey...
        
           | Name | Type | Required | Describe | Example |
           | - | :-: | :-: | :-: | :-: | 
           | path | String | true | the filepath that is needed remove file | other/1/2/3/1.jpg
           | callback | String | false | Define a backend Handle API path, it will trriger a http request after remove file finish. | http://backend/a/b/ |
           
- BackEnd
    1. upload
       * Params
          backend handle program will receive these params after fileServer trriger a http request.
          
          | Name | Type | Describe | Example |
           | - | :-: | :-: | :-: | 
           | filePath | String | the upload file storage path | other/a/b/c/ |
           | fileSuffix | String | the upload file extension name  | .png |
           | fileName | String | the upload file name  | asdad123123dsads.png |
           
    2. remove
       * Params
          backend handle program will receive these params after fileServer trriger a http request. 
          
          remove API will receive some custom params. 
           
