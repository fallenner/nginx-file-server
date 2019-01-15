cjson = require "cjson.safe"
http = require "resty.http"
function onupload()
    ngx.header["Content-Type"] = "application/json; charset=utf-8"
    ngx.header["Access-Control-Allow-Origin"] = ngx.var.http_origin
    ngx.req.read_body() --读取ngx的请求头的body
    callback = "" --设置全局后端上传接口路径
    params, file_tab_arr = getFormParams_FixBug(ngx.req.get_post_args()) --获取上传的请求参数（上传模块处理后的参数）
    fileStore = "/home/uploadStore/" --文件存储仓库
    if (ngx.req.get_headers()["token"] == nil or ngx.req.get_headers()["token"] == "") then
        os.execute("rm -rf " .. params["filePath"])
        return ngx.say(cjson.encode({code = -1, msg = "您是非法用户!"}))
    end
    --params["fileSuffix"] = getFileSuffix(params["fileName"])
    -- buildFilePath(params["filePath"]) --拼装文件路径
    for i, file_tab in ipairs(file_tab_arr) do
        local temp = convertMedia(buildFilePath(file_tab))
        if (temp == nil) then
            file_tab_arr[i] = nil
        else
            file_tab_arr[i] = temp
        end
    end
    return handleCallBack()
    --buildFilePath(params["filePath"]) --拼装文件路径
    --return convertMedia() --转换视频格式并转发请求到服务端
end

-- 获取上传的文件参数
function getFormParams_FixBug(formData)
    local str_params
    if (formData) then
        for key, val in pairs(formData) do
            str_params = key .. val
        end
    else
        return nil
    end
    local tab_params = {}
    local file_tab_arr = {}
    local file_tab = {}
    local str_start = " name"
    local str_start_len = string.len(str_start)
    local str_end = "%-%-"
    local str_sign = '"'
    local idx, idx_end = string.find(str_params, str_start)
    local i = 0
    while idx do
        str_params = string.sub(str_params, idx_end) -- 截取开始标记后所有字符待用
        --ngx.log(ngx.ERR, str_params);
        i = string.find(str_params, str_sign) -- 查找字段名开始处的引号索引
        str_params = string.sub(str_params, i + 1) -- 去掉开始处的引号
        i = string.find(str_params, str_sign) -- 查找字段名结束位置的索引
        --ngx.log(ngx.ERR, str_params);
        f_name = string.sub(str_params, 0, i - 1) -- 截取到字段名称
        --ngx.log(ngx.ERR, f_name);
        str_params = string.sub(str_params, i + 1) -- 去掉名称字段以及结束时的引号
        --ngx.log(ngx.ERR, str_params);
        i, i2 = string.find(str_params, str_end) -- 查找字段值结尾标识的索引
        f_value = string.sub(str_params, 1, i - 1) -- 截取到字段值
        --ngx.log(ngx.ERR, trim(f_value));
        if (f_name == "fileName") then
            file_tab = {}
            file_tab[f_name] = trim(f_value)
        elseif (f_name == "fileSize") then
            file_tab[f_name] = trim(f_value)
            file_tab["fileSuffix"] = getFileSuffix(file_tab["fileName"])
            table.insert(file_tab_arr, file_tab)
        elseif (f_name == "fileType" or f_name == "fileMD5" or f_name == "filePath") then
            --ngx.log(ngx.ERR, file_tab[f_name])
            file_tab[f_name] = trim(f_value)
        elseif (f_name == "callback") then
            callback = trim(f_value)
        else
            tab_params[f_name] = trim(f_value)
        end
        idx = string.find(str_params, str_start, 0) -- 查找判断下一个字段是否存在的
    end
    return tab_params, file_tab_arr
end

-- 获取文件的后缀名
function getFileSuffix(fname)
    return "." .. string.lower(fname:match(".+%.(%w+)$"))
end
-- 去除字符串里的空格
function trim(str)
    if (str ~= nil) then
        return string.gsub(str, "%s+", "")
    else
        return nil
    end
end

-- 拼接文件保存地址
function buildFilePath(file_tab)
    local oldFilePath = file_tab["filePath"]
    local date = os.date("%Y%m%d")
    local year = string.sub(date, 1, 4)
    file_tab["filePath"] = year .. "/"
    -- 判断是否传入存储规则
    if (params["pathRule"] == nil or params["pathRule"] == "") then
        file_tab["filePath"] = file_tab["filePath"] .. "other/" .. date .. "/" --未传入存储路径规则按照默认存储规则
    else
        file_tab["filePath"] = file_tab["filePath"] .. params["pathRule"] --按照传入的存储路径来存储文件
    end

    if (os.execute("mkdir -p " .. fileStore .. file_tab["filePath"]) ~= 0) then
        return ngx.exec("/50x.html")
    end

    --判断是否传入指定文件名
    if (params["destFileName"] == nil or params["destFileName"] == "") then
        --	ngx.log(ngx.ERR,math.randomseed(tostring(ngx.time()):reverse():sub(1, 6)));
        file_tab["fileName"] = ngx.md5(math.random(tostring(ngx.time()):reverse():sub(1, 6))) --未传入文件名参数，则md5随机生成文件名
    else
        local i, j = string.find(params["destFileName"], "%.")
        file_tab["fileSuffix"] = string.sub(params["destFileName"], j) -- 存储传入的文件的后缀名
        file_tab["fileName"] = string.sub(params["destFileName"], 0, j - 1) -- 存储传入的文件名
    end

    if
        (os.execute(
            "mv -f " ..
                oldFilePath ..
                    " " .. fileStore .. file_tab["filePath"] .. file_tab["fileName"] .. file_tab["fileSuffix"]
        ) == 0)
     then
        return file_tab
    end
end

-- 转换视频格式
function convertMedia(file_tab)
    if (file_tab == nil) then
        return
    end
    if (string.find(".mov.flv.avi.3gp.mp4", file_tab["fileSuffix"]) ~= nil) then
        local sh_ffmpeg =
            "ffmpeg -i " ..
            fileStore ..
                file_tab["filePath"] ..
                    file_tab["fileName"] ..
                        file_tab["fileSuffix"] ..
                            " -y -acodec copy -vcodec copy -preset ultrafast -threads 2 " ..
                                fileStore .. file_tab["filePath"] .. file_tab["fileName"] .. "_format.mp4"
        local sh_ffmpeg1 =
            "ffmpeg -i " ..
            fileStore ..
                file_tab["filePath"] ..
                    file_tab["fileName"] ..
                        file_tab["fileSuffix"] ..
                            " -y -c:v libx264  -preset ultrafast -threads 2 " ..
                                fileStore .. file_tab["filePath"] .. file_tab["fileName"] .. "_format.mp4"
        local sh_rmOldFile =
            "rm -rf " .. fileStore .. file_tab["filePath"] .. file_tab["fileName"] .. file_tab["fileSuffix"]
        file_tab["fileName"] = file_tab["fileName"] .. "_format" --若文件为mp4文件的则添加_format，防止格式转换输出文件和输入文件名一样导致格式转换失败。
        if (os.execute(sh_ffmpeg) == 0 or os.execute(sh_ffmpeg1) == 0) then
            if (os.execute(sh_rmOldFile) == 0) then --删除转换格式前的文件
                file_tab["fileSuffix"] = ".mp4"
                return file_tab
            -- else
            --     --return ngx.say(cjson.encode({code = -1, msg = "文件转码失败,文件回滚删除失败，请检查上传的文件是否已损坏。"}))
            --     return {code = -1, msg = "文件转码失败,文件回滚删除失败，请检查上传的文件是否已损坏。"}
            end
        -- else
        -- return ngx.say(cjson.encode({code = -1, msg = "文件转码失败,文件回滚删除成功，请检查上传的文件是否已损坏。"}))
        -- return {code = -1, msg = "文件转码失败,文件回滚删除成功，请检查上传的文件是否已损坏。"}
        end
    else
        return file_tab
    end
end

-- 处理后端返回数据
function handleCallBack()
    if (callback == "") then
        return ngx.say(cjson.encode({code = 0, result = file_tab_arr}))
    else
        if (string.match(callback, "http://") == nil) then
            return ngx.say(cjson.encode({code = -1, msg = callback .. "不是合法的url"}))
        end
        params["files"] = cjson.encode(file_tab_arr)
        local httpc = http.new()
        httpc:set_timeout(10000)
        local res, err =
            httpc:request_uri(
            callback,
            {
                method = "POST",
                query = params,
                headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded"
                }
            }
        )
        if (res) then
            local resultTable = cjson.decode(res.body) --将后端返回的json数据转换成table
            if (resultTable ~= nil and resultTable["code"] == 0) then
                return ngx.say(res.body)
            else
                for i, file_tab in ipairs(file_tab_arr) do
                    if
                        (os.execute(
                            "rm -rf " ..
                                fileStore .. file_tab["filePath"] .. file_tab["fileName"] .. file_tab["fileSuffix"]
                        ) ~= 0)
                     then
                        return ngx.say(cjson.encode({code = -1, msg = "服务端保存文件信息失败,请检查callback参数和服务端请求日志，文件回滚删除失败"}))
                    end
                end
                return ngx.say(cjson.encode({code = -1, msg = "服务端保存文件信息失败,请检查callback参数和服务端请求日志，文件回滚删除成功"}))
            end
        else
            for i, file_tab in ipairs(file_tab_arr) do
                if
                    (os.execute(
                        "rm -rf " .. fileStore .. file_tab["filePath"] .. file_tab["fileName"] .. file_tab["fileSuffix"]
                    ) ~= 0)
                 then
                    return ngx.say(cjson.encode({code = -1, msg = "服务端请求出错，文件回滚失败。错误信息为：" .. err}))
                end
            end
            return ngx.say(cjson.encode({code = -1, msg = "服务端请求出错，错误信息为：" .. err}))
        end
    end
end

onupload() --执行onupload函数
