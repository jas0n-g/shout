function printMsg(msg) print("Shout (Message): " .. msg or "") end
function printWarn(msg) print("\27[33mShout (Warning):\27[0m " .. msg or "") end
function printErr(msg) io.stderr:write("\27[31mShout (Error): \27[0m" .. (msg or "") .. "\n") end

print("Printing Tests:")
printMsg("This is a message.")
printWarn("This is a warning.")
printErr("This is an error.")
print("=====")
function strifyTbl(tbl) -- for debug purposes
    if type(tbl) ~= "table" then return "" end
    tblStr = "{"
    for k, v in pairs(tbl) do
        if type(k) == "number" then
            if type(v) == "table" then
                tblStr = tblStr .. strifyTbl(v)
            else
                tblStr = tblStr .. tostring(v) 
            end
        else
            tblStr = tblStr .. "[\"" .. tostring(k) .. "\"] = "
            if type(v) == "table" then
                tblStr = tblStr .. strifyTbl(v)
            else
                tblStr = tblStr .. tostring(v) 
            end
        end
        if next(tbl, k) ~= nil then tblStr = tblStr .. ", " end
    end
    tblStr = tblStr .. "}"
    return tblStr
end

function tblEq(xs, ys) -- O(n) is fast enough, ig
    if type(xs) ~= type(ys) or type(xs) ~= "table" then return nil end
    if #xs ~= #ys then return false end
    for i, _ in pairs(xs) do
        if type(xs[i]) ~= type(ys[i]) then return false end
        if type(xs[i]) == "table" then
            if not tblEq(xs[i], ys[i]) then return false end
        else
            if xs[i] ~= ys[i] then return false end
        end
    end
    return true
end

print("Misc Table Funcs Tests:")
local miscTableFuncTblOne = {1, true, {"a", "sub", "table"}}
local miscTableFuncTblTwo = {1, true, {"a", "sub", "table"}}
printMsg("miscTableFuncTblOne: " .. strifyTbl(miscTableFuncTblOne))
printMsg("miscTableFuncTblTwo: " .. strifyTbl(miscTableFuncTblTwo))
if tblEq(miscTableFuncTblOne, miscTableFuncTblTwo) then
    printMsg("✅ miscTableFuncTblOne == miscTableFuncTblTwo")
else
    printErr("❌ miscTableFuncTblOne != miscTableFuncTblTwo")
end
miscTableFuncTblTwo = {2, true, {"a", "sub", "table"}}
printMsg("miscTableFuncTblOne: " .. strifyTbl(miscTableFuncTblOne))
printMsg("miscTableFuncTblTwo: " .. strifyTbl(miscTableFuncTblTwo))
if tblEq(miscTableFuncTblOne, miscTableFuncTblTwo) then
    printErr("❌ miscTableFuncTblOne == miscTableFuncTblTwo")
else
    printMsg("✅ miscTableFuncTblOne != miscTableFuncTblTwo")
end
print("=====")
function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

print("Deepcopy Tests:")
local deepcopyList = {1, true, {"a", "sub", "table"}}
local deepcopyListCopy = deepcopy(deepcopyList)
printMsg("deepcopyList: " .. strifyTbl(deepcopyList))
printMsg("deepcopyListCopy: " .. strifyTbl(deepcopyListCopy))
if tblEq(deepcopyList, deepcopyListCopy) then 
    printMsg("✅ deepcopyList == deepcopyListCopy")
else
    printErr("❌ deepcopyList != deepcopyListCopy")
end
deepcopyListCopy[1] = 2
printMsg("deepcopyList: " .. strifyTbl(deepcopyList))
printMsg("deepcopyListCopy: " .. strifyTbl(deepcopyListCopy))
if tblEq(deepcopyList, deepcopyListCopy) then 
    printErr("❌ deepcopyList == deepcopyListCopy")
else
    printMsg("✅ deepcopyList != deepcopyListCopy")
end
print("=====")
function tail(xs, n)
    ys = {}
    cnt = 1
    n = n or 1
    if type(xs) ~= "table" or type(n) ~= "number" then return nil end
    if n >= #xs then return {} end
    if n < 1 then return deepcopy(xs) end

    for _, x in pairs(xs) do
        if cnt > n then ys[#ys + 1] = deepcopy(x) end
        cnt = cnt + 1
    end
    return ys
end

print("Tail Tests:")
local tailList = {1, 2, 3, 4, 5}
printMsg("tailList: " .. strifyTbl(tailList))
if tblEq(tail(tailList), {2, 3, 4, 5}) then
    printMsg("✅ tail(tailList) == {2, 3, 4, 5}")
else
    printErr("❌ tail(tailList) != {2, 3, 4, 5}")
    printErr("tail(tailList) = " .. strifyTbl(tail(tailList)))
end
if tblEq(tail(tailList, 3), {4, 5}) then
    printMsg("✅ tail(tailList, 3) == {4, 5}")
else
    printErr("❌ tail(tailList, 3) == {4, 5}")
    printErr("tail(tailList, 3) = " .. strifyTbl(tail(tailList, 3)))
end
if tblEq(tail(tailList, 6), {}) then
    printMsg("✅ tail(tailList, 5) == {}")
else
    printErr("❌ tail(tailList, 5) != {}")
    printErr("tail(tailList, 5) = " .. strifyTbl(tail(tailList, 5)))
end
print("=====")
function append(xs, elem)
    if type(xs) ~= "table" then return nil end
    local ys = deepcopy(xs)
    ys[#ys + 1] = deepcopy(elem)
    return ys
end

print("Append Tests:")
local appendList = {1, 2, 3, 4, 5}
printMsg("appendList: " .. strifyTbl(appendList))
if tblEq(append(appendList, 6), {1, 2, 3, 4, 5, 6}) then
    printMsg("✅ append(appendList, 6) == {1, 2, 3, 4, 5, 6}")
else
    printErr("❌ append(appendList, 6) != {1, 2, 3, 4, 5, 6}")
    printErr("append(appendList, 6) = " .. strifyTbl(append(appendList, 6)))
end

if tblEq(append(appendList, {"a", "sub", "list"}), {1, 2, 3, 4, 5, {"a", "sub", "list"}}) then
    printMsg("✅ append(appendList, {\"a\", \"sub\", \"list\"}) == {1, 2, 3, 4, 5, {\"a\", \"sub\", \"list\"}}")
else
    printErr("❌ append(appendList, {\"a\", \"sub\", \"list\"}) != {1, 2, 3, 4, 5, {\"a\", \"sub\", \"list\"}}")
    printErr("append(appendList, {\"a\", \"sub\", \"list\"}) = " .. strifyTbl(append(appendList, {"a", "sub", "list"})))
end
print("=====")
