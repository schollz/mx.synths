local FourChords={}

function FourChords:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init(o.fname)
  return o
end

-- see if the file exists
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function FourChords:init(fname)
  print("loading chords from "..fname)
  math.randomseed( os.time() )
  self.prob_total=0
  self.chords={}
  if not file_exists(fname) then return {} end
  lines = {}
  for line in io.lines(fname) do 
    chunks = {}
    for substring in line:gmatch("%S+") do
       table.insert(chunks, substring)
    end
    if #chunks==5 then
      self.prob_total=self.prob_total+tonumber(chunks[5])
      table.insert(self.chords,{tonumber(chunks[5]),chunks[1],chunks[2],chunks[3],chunks[4]})
    end
  end
  -- renormalize
  for i,v in ipairs(self.chords) do
    self.chords[i][1]=v[1]/self.prob_total
  end
end

function FourChords:random_weighted()
  local r=math.random()
  for _,v in ipairs(self.chords) do
    if (r<v[1]) then
      -- found
      do return {v[2],v[3],v[4],v[5]} end
    end
    r = r - v[1]
  end
end

function FourChords:random_unpopular()
  local v=self.chords[math.random(#self.chords-100)+100]
  return {v[2],v[3],v[4],v[5]}
end


-- fc=FourChords:new({fname="4chords_top1000.txt"})
-- for i,v in ipairs(fc:random_weighted()) do
--   print(i,v)
-- end

return FourChords
