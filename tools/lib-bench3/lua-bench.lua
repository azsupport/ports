-- SPDX-License-Identifier: BSD-2-Clause
-- lua-bench.lua <name> [<scale>]: LuaJIT (nginx lua and stream lua): the parts its C does
-- (string library, tables and strings of the runtime, the garbage collector), and one of
-- numbers only (the machine code of the JIT: no C, the control)
local name, scale = arg[1], tonumber(arg[2] or "1")
local B = {}

function B.strings()
  local n = 0
  for i = 1, 300000 * scale do
    local s = string.format("%s:%d:%.3f:%x", "key", i, i * 0.5, i)
    local a = s:gsub("%d", "#")
    local u = (a .. s):upper():lower()
    local p = u:find("key:#+", 1)
    n = n + #u + (p or 0) + #s:rep(3, ",")
  end
  return n
end

function B.patterns()
  local line = "192.168.1.10 - - [26/Nov/2026:21:30:00 +0100] \"GET /index.php?id=42&q=test HTTP/1.1\" 200 5123 \"-\" \"Mozilla/5.0\""
  local n = 0
  for i = 1, 200000 * scale do
    local ip, d, m, path, st = line:match("^(%S+) %S+ %S+ %[([^%]]+)%] \"(%u+) ([^ ]+) [^\"]+\" (%d+)")
    for k, v in path:gmatch("([%w_]+)=([%w_]+)") do n = n + #k + #v end
    n = n + #ip + #d + #m + tonumber(st)
  end
  return n
end

function B.tables()
  local n = 0
  for r = 1, 10 * scale do
    local t = {}
    for i = 1, 200000 do t["k" .. i] = i end
    for i = 1, 400000 do n = n + (t["k" .. (i % 200000 + 1)] or 0) end
    local a = {}
    for i = 1, 100000 do a[i] = (i * 7919) % 100003 end
    table.sort(a, function(x, y) return x > y end)
    n = n + a[1] + #table.concat(a, ",", 1, 1000)
  end
  return n
end

function B.gc()
  local keep = {}
  for i = 1, 3000000 * scale do
    local o = { id = i, name = "n" .. (i % 1000), f = function() return i end }
    if i % 100 == 0 then keep[#keep + 1] = o end
    if #keep > 10000 then keep = {} end
  end
  collectgarbage()
  return #keep
end

function B.numbers()
  local function A(i, j) local ij = i + j - 1 return 1.0 / (ij * (ij - 1) * 0.5 + i) end
  local function Av(x, y, N) for i = 1, N do local a = 0 for j = 1, N do a = a + x[j] * A(i, j) end y[i] = a end end
  local function Atv(x, y, N) for i = 1, N do local a = 0 for j = 1, N do a = a + x[j] * A(j, i) end y[i] = a end end
  local N = 1500
  local u, v, t = {}, {}, {}
  for i = 1, N do u[i] = 1 end
  for i = 1, 10 * scale do Av(u, t, N) Atv(t, v, N) Av(v, t, N) Atv(t, u, N) end
  local vBv, vv = 0, 0
  for i = 1, N do local ui, vi = u[i], v[i] vBv = vBv + ui * vi vv = vv + vi * vi end
  return math.sqrt(vBv / vv)
end

if not B[name] then
  io.stderr:write("unknown benchmark ", tostring(name), "\n")
  os.exit(2)
end
io.write(tostring(B[name]()), "\n")
