cjson = require "cjson"
function removeFile()
    ngx.header["Content-Type"] = "application/json; charset=utf-8"
    if ngx.var.request_method ~= "OPTIONS" then
        local basePath = "/home/uploadStore/"
        --判断是否带了token请求头以及请求是否为POST
        if
            (ngx.var.request_method ~= "POST" or ngx.req.get_headers()["token"] == nil or
                ngx.req.get_headers()["token"] == "")
         then
            return ngx.say(cjson.encode({code = -1, msg = "非法请求方式!"}))
        end
        ngx.req.read_body()
        local params = ngx.req.get_post_args()
        --判断是否传入了需要删除的文件路径参数path
        if (params["path"] == nil or params["path"] == "") then
            return ngx.say(cjson.encode({code = -1, msg = "请传入需要删除的文件路径"}))
        end
        --判断是否传入了后端回调程序路径
        if (params["callback"] == nil or params["callback"] == "") then
            if (os.execute("rm -rf " .. basePath .. params["path"]) == 0) then
                ngx.say(cjson.encode({code = 0, msg = "文件删除成功"}))
            else
                ngx.say(cjson.encode({code = -1, msg = "文件服务器删除文件失败"}))
            end
        else
            res = ngx.location.capture(params["callback"], {method = ngx.HTTP_POST, args = params})
            if (res.status == ngx.HTTP_OK) then
                local resultTable = cjson.decode(res.body)
                if (resultTable["code"] == 0) then
                    if (os.execute("rm -rf " .. basePath .. params["path"]) == 0) then
                        ngx.say(res.body)
                    else
                        ngx.say(cjson.encode({code = -1, msg = resultTable["msg"]}))
                    end
                end
            else
                ngx.say(cjson.encode({code = -1, msg = resultTable["msg"]}))
            end
        end
    end
end
removeFile()
