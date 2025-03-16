VERSION = "1.0.0"
local micro = import("micro")
local buffer = import("micro/buffer")
local config = import("micro/config")
local util = import("micro/util")

local current_bp = nil

local tree = nil
local multi_trees = {}
local multi_words = {}
local words = {}
local abc = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789äöüÄÖÜ_./"
local possible_breakpoints = "./"
local add_function_parentesis = true

function add_to_tree(term)
	local breakingpoint = term:find(".",1,true)
	if breakingpoint == nil then breakingpoint = term:find("/",1,true) end
	if breakingpoint ~= nil then
		add_to_tree(term:sub(1,breakingpoint-1))
		add_to_tree(term:sub(breakingpoint+1))		
	end
	if #term < 3 then return false end
	if words[term] ~= nil then return false end
    local node = tree
    for i = 1, #term do
    	local char = string.sub(term, i, i)
    	-- micro.TermError("char",i,char)
        if node[char] == nil then        	        	
            node[char] = {leaf = true, value = term}
			words[term] = i
            return true
        elseif node[char].value == term then
            return false -- should never occur as words check prevents it?
        elseif node[char].leaf then
            local old_leaf = node[char]
            local wayp = {}
            wayp[string.sub(old_leaf.value,i+1,i+1)] = old_leaf
            node[char] = wayp
        end
        node = node[char]
    end
end

function get_all_sub_values(node)
    local result = {}
    if node.value then table.insert(result, node.value) end
    for key, _ in pairs(node) do
        if key == "leaf" or key == "value" then 
        	-- goto continue
		else
	        for _, sub_value in ipairs(get_all_sub_values(node[key])) do
	            table.insert(result, sub_value)
	        end
        end
        
    end
    return result
end
-- search function searches in tree:
function search_in_tree(term)
    local node = tree
    local result = {}
    for i = 1, #term do
        node = node[string.sub(term,i,i)]
        if node == nil then return nil end
        if node.leaf and node.value and node.value:find(term, 1, true) then
            break
        end
    end
    if node and node.leaf == nil then
        for _, sub_value in ipairs(get_all_sub_values(node)) do
            table.insert(result, sub_value)
        end
    elseif node.value then
        table.insert(result, node.value)
    end
    return result
end





function parse_content(text)
    -- print('parse content with length:', #text)
    -- local start = os.clock()
    local char, term = "", ""
    local last_breakpoint = 1
    for i = 1, #text do
        char = text:sub(i, i)
        if abc:find(char, 1, true) then
            -- if possible_breakpoints:find(char,1,true) then
            	-- local partial_term = term:sub(last_breakpoint,i-1)
			    -- micro.TermError('partial_term:', i, partial_term .. '|'..term .. '|'..char)
            	-- if #partial_term > 1 then
					-- add_to_tree(partial_term)
				-- end
				-- last_breakpoint = i + 1
            -- end
            term = term .. char       
        elseif #term > 1 then
        	if char == "(" and add_function_parentesis then term = term .. '()' end
            add_to_tree(term)
            -- if last_breakpoint > 1 then
            	-- add_to_tree(term:sub(last_breakpoint,#term))
            -- end
            term = ""
        else
        	term = "" -- delete term as we start a new one and discard the old
        end
    end
    if #term > 0 then 
    	add_to_tree(term) 
    	-- if last_breakpoint > 1 then
           	-- add_to_tree(term:sub(last_breakpoint,#term))
    	-- end
    end
    -- micro.TermError('parsing needed', os.clock() - start, 'seconds')
    
end

function get_text(view)
    --grab text from view.buffer (in one string)
    local epos = view.Buf:End()
    local lines = epos.Y
    local textblock = ''
    for i=0, lines do 
		textblock = textblock .. view.Buf:Line(i)
		textblock = textblock .. '\n'		
    end
    return textblock
end

function refresh_tree(bp, args)
	tree = {}
	words = {}
	-- let bp = buffer:Current()
	local txt = get_text(bp)
	parse_content(txt)
	local name = bp.Buf:GetName()
	
	multi_trees[name] = tree
	multi_words[name] = words	
	local open_files = ""
	local count = 0
  	-- micro.TermError('refresh multiwords',0,dump(multi_words))
	for key,v in pairs(multi_words) do
	  count = 0
	  if key ~= name then 
	  	for term, _ in pairs(multi_words[key]) do
			add_to_tree(term)
			count = count + 1
	  	end
	  	open_files = open_files .. name .. ' #'..count .. '  '
	  end
	end
	-- micro.InfoBar():Message('parsed '..name .. '->' .. open_files)
	-- micro.TermError("refresh",0,dump(tree))
end


local function CursorWord(bp)
	-- debug1("CursorWord(bp)",bp)
	local c = bp.Cursor
	local x = c.X-1 -- start one rune before the cursor
	local result = ""
	while x >= 0 do
		local r = util.RuneStr(c:RuneUnder(x))
		-- if (r == " " or r == "\t") then    -- IsWordChar(r) then
		if not abc:find(r,1,true) then    -- IsWordChar(r) then
			break
		else
			result = r .. result
		end
		x = x-1
	end
	-- consoleLog(result, "cursorWord")
	return result
end

function reduce_to_one_result(term, list)
	local res = nil
	local max = 0
	local a = ""
	local b = ""
	for i=1, #list do 
		if #list[i] > #term then
			if res == nil then 
				res = list[i] 
				-- micro.TermError("first res",i,res)
			else
				max = #res
				if #list[i]<max then max = #list[i] end
				for ii = #term , max do
					a = string.sub(res, 1, ii)
					b = string.sub(list[i],1,ii)
					if a == b then 
						-- res = a
						-- micro.TermError("all good:",ii,a)
					else 
						res = string.sub(res,1,ii-1)
						-- micro.TermError("a != b",ii,a..' '..b ..'->'.. res)
						break
					end	
				end
			end
			
		end
	end
	if res == nil then res = "" end
	return res
end
-- test_1 test_2 test_3 test_10



function autocomplete(view, args)
	-- local term = args[1]
	local term = CursorWord(view)
	if term == nil or term == false or #term == 0 then
		return false
	end
	-- micro.TermError("autocomplete",1, term)
	-- TODO: find better moment to refresh as refresh here always has the begin-word parsed
	if tree == nil then refresh_tree(view) end
		
	local list = search_in_tree(term)
	local result
	-- micro.TermError("autocomplete",1, dump(args[1]))
	-- micro.TermError("search", 0, dump(list))
	if list == nil then 
		local pos = term:find('.',1,true)
		if pos == nil then pos = term:find('/',1,true) end
		if pos ~= nil then
			list = search_in_tree(term:sub(pos))
		end
	end
	-- micro.TermError("search", 0, dump(tree))
	if list == nil then
		return false
	else
		result = list[1]
		if #list > 1 then
			result = reduce_to_one_result(term, list)
			resstring = ""
			shortstring = ""
			local usedwords = {}			
			for i=1,#list do
				if i > 1 then 
					resstring = resstring .. ', ' 
					-- shortstring = shortstring .. ', '
				end
				-- if #list > 10 then
					-- local tmp =  string.sub(list[i],#term,#term + 5)
					local tmp = list[i]
					if #tmp>10 then tmp =  string.sub(list[i],1,#result + 5) end
					if usedwords[tmp]==nil then
						-- micro.TermError('usedwords',0,dump(usedwords))
						-- resstring = resstring ..tmp..'...'
						shortstring = shortstring .. tmp .. '...'
						if i > 1 then shortstring = shortstring .. ', ' end
						usedwords[tmp] = tmp
					else
						
					end
				-- else
					resstring = resstring .. list[i]
				-- end
			end
			if #resstring > 200 then 
				micro.InfoBar():Message(shortstring)
			else
				micro.InfoBar():Message(resstring)
			end
		end	
		-- micro.TermError("result",0,result)
	end
	if #result - #term >=1 then
		result = string.sub(result, #term+1, #result)
		local ins_pos = buffer.Loc(view.Cursor.X, view.Cursor.Y)
		view.Buf:Insert(ins_pos, result)	
		-- go cursor one to the left if we inserted ()
		if result:sub(#result) == ')' then 
			view.Cursor.X = view.Cursor.X - 1			
		end
		refresh_tree(view) -- refresh tree to get rid of stub
		return true
	end
	if #result - #term == 0 and #list > 1 then 
		return true
	end
	return false
end

function print_tree(view, args)
	refresh_tree(view)
	micro.TermError("tree",0,dump(tree))
end


function init()
	config.MakeCommand("autocomplete_refresh", refresh_tree, config.NoComplete)
	config.MakeCommand("autocomplete", autocomplete, config.NoComplete)
	config.MakeCommand("autocomplete_print_tree", print_tree, config.NoComplete)

	config.AddRuntimeFile("autocomplete", config.RTHelp, "help/autocomplete.md")
	
	config.RegisterCommonOption("autocomplete", "abc", abc)
	config.RegisterCommonOption("autocomplete", "add_function_parentesis", add_function_parentesis)
	abc = config.GetGlobalOption("autocomplete.abc")
	add_function_parentesis = config.GetGlobalOption("autocomplete.add_function_parentesis")
end


function onNextSplit(bp)
	refresh_tree(bp)
end

function onSave(bp)
	refresh_tree(bp)
end

function onQuit(bp)
	local name = bp.Buf:GetName()
	if multi_words[name] ~= nil then 
		multi_words[name] = nil
	end
end



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- dirty little helpers
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


function dump(o)
   if type(o) == 'table' then
      local s = '{ \n'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ',\n'
      end
      return s .. '} \n'
   else
      return tostring(o)
   end
end