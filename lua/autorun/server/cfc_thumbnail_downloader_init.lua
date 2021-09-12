file.CreateDir("maps/thumb/")
local addonsWithoutThumb = {}
local addonFiles = {}
for _, addon in ipairs(engine.GetAddons()) do
    local files, dirs = file.Find("maps/thumb/*", addon.title)
    if #files > 0 then
    	for _, filename in pairs(files) do
			file.AsyncRead( "maps/thumb/"..filename, "GAME", function( fileName, gamePath, status, data )
				if status == FSASYNC_OK then
					file.Write("maps/thumb/"..filename, data)
					resource.AddFile("maps/thumb/"..filename)
					print("maps/thumb/"..filename, #data)
				end
			end)
		end
	else
		local files = file.Find("maps/*.bsp", addon.title)
		if #files > 0 then
			addonFiles[addon.wsid] = string.Replace(files[1], ".bsp", "")
			print(string.format([[resource.AddFile("maps/thumb/%s.png")]], string.Replace(files[1], ".bsp", "")))
			table.insert(addonsWithoutThumb, addon)
		end
	end
end

local body =  {["itemcount"] = tostring(#addonsWithoutThumb)}
for i, addon in ipairs(addonsWithoutThumb) do
	body["publishedfileids["..(i-1).."]"] = tostring(addon.wsid)
end

http.Post( "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", body, function(body) 
	local decodedResponse = util.JSONToTable(body)
	for _, addon in next, decodedResponse.response.publishedfiledetails do
		http.Fetch( addon.preview_url, function( body, length, headers, code )
			local ext = ".png"
			if headers["Content-Type"] == "image/jpeg" then
				ext = ".jpg"
			end
			local filename = addonFiles[addon.publishedfileid] or "default"
			file.Write("maps/thumb/"..filename..ext, body)
			
		end, function(err) print(err) end )
	end
end, onFailure )

