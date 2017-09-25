local b = require "vblocks"(3)

local ro2rwss = require"mini.proxy.ro2rw-shadowself"

c = ro2rwss(b)

b:append("abc")
b:append("123")
b:append("456")
for i,v in b:ipairs() do
	print(i,v)
end
for i,v in ipairs(b) do
	print(i,v, "ipairs(b)")
end
for i,v in ipairs(c) do
	print(i,v, "ipairs(c)")
end

assert( b:seek("set", 0) == 0)
assert( b:seek("cur", 0) == 0)
assert( b:seek("set", 3) == 3)
assert( b:seek("cur", 3) == 6)
print( b:seek("end"))
print( c.seek("cur"))

--print("size", b:size() )
local lastpos = b:size()

--print("get(all)", 0, lastpos, table.concat( b:getdata(0, lastpos)))
--print("get(+1,-1)", 1, lastpos-1, table.concat( b:getdata(1, lastpos-1)))
assert(table.concat( b:getdata(0, lastpos)) == "abc123456" )
assert( table.concat( b:getdata(1, lastpos-1))=="bc12345" )

assert( tostring(b:torealdata({ "xxx", nil, "z", n=3}, "_"))=="xxx___z__")

