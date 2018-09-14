cjson = require "cjson.safe";
function copy()
    ngx.header['Content-Type'] = 'application/json; charset=utf-8';
    local basePath = "/opt/uploadStore/";
	local userToken = ngx.req.get_headers()["token"];
    if ngx.var.request_method ~= "OPTIONS"  then
        --判断是否带了token请求头以及请求是否为POST
		if (ngx.var.request_method ~= "POST"  or userToken == nil or userToken == "") then
			return ngx.say(cjson.encode({code = -1,msg = "非法请求方式!"}));
        end
        ngx.req.read_body();
        local params = ngx.req.get_post_args();
        --判断是否传入需要同步的文件或文件夹路径
        if (params["path"] == nil or params["path"] == "") then
			return ngx.say(cjson.encode({code = -1,msg = "同步的文件(夹)路径不能为空!"}));
        end
        --判断是否传入同步的目的文件夹
        if (params["destPath"] == nil or params["destPath"] == "") then
			return ngx.say(cjson.encode({code = -1,msg = "目的文件(夹)路径不能为空!"}));
        end
	
        if (os.execute("mkdir -p "..basePath..params["destPath"] .." &&\\cp -rf "..basePath..params["path"]..".  "..basePath..params["destPath"]) == 0) then 
		return ngx.say(cjson.encode({code = 0,msg = "文件同步成功"}));            
        else
		return ngx.say(cjson.encode({code = -1,msg = "同步失败，请检查文件服务器日志"}));            
        end
    end
end
copy();
