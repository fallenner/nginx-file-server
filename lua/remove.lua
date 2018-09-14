cjson = require "cjson.safe";
http = require "resty.http";
function removeFile()
	ngx.header['Content-Type'] = 'application/json; charset=utf-8';
	local userToken = ngx.req.get_headers()["token"];
	if ngx.var.request_method ~= "OPTIONS"  then
		--判断是否带了token请求头以及请求是否为POST
		if (ngx.var.request_method ~= "POST"  or userToken == nil or userToken == "") then
			return ngx.say(cjson.encode({code = -1,msg = "非法请求方式!"}));
        end
		ngx.req.read_body();
        local params = ngx.req.get_post_args();
		--判断是否传入了需要删除的文件路径参数path
        if (params["path"] == nil or params["path"] == "") then
			return ngx.say(cjson.encode({code = -1,msg = "请传入需要删除的文件路径"}));
        end
		--判断是否传入了后端回调程序路径
		if (string.match(params["callback"],"http://") == nil) then
			 return ngx.say(cjson.encode({code=-1,msg=callback.."不是合法的url"}))
		end
		local httpc = http.new();
		httpc:set_timeout(10000);
		local res, err = httpc:request_uri(params["callback"], {
			method = "POST",
			query = params,
			headers = {
			  ["Content-Type"] = "application/x-www-form-urlencoded",
			  ["token"] = userToken
			}
		  });
		if (res) then
			local resultTable = cjson.decode(res.body); --将后端返回的json数据转换成table	
			if(resultTable ~= nil and resultTable["code"] == 0) then
				if (os.execute("rm -rf /opt/uploadStore/"..params["path"]) == 0) then
					return ngx.say(cjson.encode({code=0,msg = "文件删除成功"}));
				else
					return ngx.say(cjson.encode({code=-1,msg="文件记录已经删除，但文件删除失败"}));
				end	
			else
				return ngx.say(cjson.encode({code=-1,msg="服务端删除文件记录出错,请检查callback参数和服务端请求日志"}));	
			end
		else
			return ngx.say(cjson.encode({code=-1,msg="服务端请求出错，错误信息为："..err}))
		end;
	end
end
removeFile();
