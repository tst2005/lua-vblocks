local B = require"mini.class"("vblocks")
local floor = math.floor
local math_min,math_max = math.min,math.max

function B:init(blksize)
	assert(blksize)
	self.data = {}
	self._size    = 0 -- total size in blocks
	self._blksize = blksize -- block size
	self._cursor  = 0 -- current position in byte (begin at 0)
	require "mini.class.autometa"(self, B)
end

function B:__ipairs()
	--local data = self.data
	--local _size = self._size
	--local i = 0
	return function(self, i)
		local data = self.data
		local _size = self._size
		i = (i or 0)+1
		local v = data[i]
		if i >= 1 and i <= _size and v then
			return i, v
		end
	end, self, 0
end

local function between(min,v,max)
	return math_min(max, math_max(min,v))
end
assert( between(0,1,2)==1 )
assert( between(0,-1,2)==0 )
assert( between(0,2,2)==2 )
assert( between(0,3,2)==2 )

--[[
local function jump(offset, from)
	local abs_cursor = between(0, from+offset, self._size*self._blksize)
	local segnum = floor( abs_cursor/self._blksize) +1
	return abs_cursor, segnum
end
]]--

function B:size()
	return self._size * self._blksize
end

function B:seek(whence, offset)
	local base
	if type(whence)=="number" then
		offset,whence = whence,"cur"
	end
	if offset==nil then
		offset=0
	end
	if whence == "set" then
		base=0
	elseif whence == "cur" then
		base=self._cursor
	elseif whence == "end" then
		base=self._size*self._blksize
	else
		error("seek: unknwon whence",2)
	end
	local cursor = between(0, base+offset, self._size*self._blksize)
	self._cursor = cursor
	return cursor 
end

function B:_cursor2block(cursor)
	return floor( cursor/self._blksize) +1
end

function B:read_one_block()
	local segnum = self:_cursor2block(self._cursor)
	self._cursor = self._cursor + self._blksize
	return self.data[segnum]
end

function B:insert(pos, value) -- :([pos], value)
	if value==nil then
		value,pos=pos,self._size+1
	end
	self._size=self._size+1
	self.data[pos] = value
	return self
end

function B:append(value)
	return self:insert(self._size+1, value)
end

function B:getdata(pos_begin, pos_end) -- begin+end in data position
	local first_block, last_block, first_pos, last_pos = self:_cursor2block(pos_begin), self:_cursor2block(pos_end), pos_begin % self._blksize, pos_end % self._blksize
--print("#debug", first_block, last_block, first_pos, last_pos)
	return self:getblockrange(first_block, last_block, first_pos, last_pos)
end

function B:getblockrange(first_block, last_block, first_pos, last_pos)
	local blocks = self.data
	local t_ins = table.insert
	local r = {}
	t_ins(r, (blocks[first_block]:sub( (first_pos or 0)+1, -1)))
--print("-1st:", first_block)
--print(" loop", first_block+1,last_block-1 )
	for n=first_block+1,last_block-1 do
--print("-add:", n)
		t_ins(r, blocks[n])
	end
	local b = blocks[last_block]
	if b and last_pos then
		b=b:sub(1, last_pos)
	end
--print("endloop")
--print("-last:", last_block)
	t_ins(r, b)
	r.n=1+last_block-first_block
	return r
end

function B:torealdata(pseudoblock_t, padchar)
	local pad = padchar or self._padchar or "\0"
	local r = {}
	for n=1,pseudoblock_t.n do
		local v = pseudoblock_t[n] or ""
		if #v == self._blksize then
			r[#r+1]= v
		else
			r[#r+1]= v..(pad):rep(self._blksize-#v)
		end

	end
	return table.concat(r)
end

function B:next(i)
	if i <= self._size then
		return i, self.data[i]
	end
end
-- debug
function B:ipairs()
	local i = 0
	return function()
		i=i+1
		return self:next(i)
		--if i <= self._size then
		--	return i, self.data[i]
		--end
	end
end

--debug
function B:rawget()
	return self.data[self._cursor]
end

return B
