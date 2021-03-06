exports.name = "creationix/coro-fs"
exports.version = "1.0.0"

local uv = require('uv')
local fs = exports
local pathJoin = require('luvi').path.join

local function noop() end

local function makeCallback()
  local thread = coroutine.running()
  return function (err, value, ...)
    if err then
      assert(coroutine.resume(thread, nil, err))
    else
      assert(coroutine.resume(thread, value == nil and true or value, ...))
    end
  end
end

function fs.mkdir(path, mode)
  uv.fs_mkdir(path, mode or 511, makeCallback())
  return coroutine.yield()
end
function fs.open(path, flags, mode)
  uv.fs_open(path, flags or "r", mode or 438, makeCallback())
  return coroutine.yield()
end
function fs.unlink(path)
  uv.fs_unlink(path, makeCallback())
  return coroutine.yield()
end
function fs.stat(path)
  uv.fs_stat(path, makeCallback())
  return coroutine.yield()
end
function fs.lstat(path)
  uv.fs_lstat(path, makeCallback())
  return coroutine.yield()
end
function fs.readlink(path)
  uv.fs_readlink(path, makeCallback())
  return coroutine.yield()
end
function fs.fstat(fd)
  uv.fs_fstat(fd, makeCallback())
  return coroutine.yield()
end
function fs.fchmod(fd, mode)
  uv.fs_fchmod(fd, mode, makeCallback())
  return coroutine.yield()
end
function fs.read(fd, length, offset)
  uv.fs_read(fd, length or 1024*48, offset or -1, makeCallback())
  return coroutine.yield()
end
function fs.write(fd, data, offset)
  uv.fs_write(fd, data, offset or -1, makeCallback())
  return coroutine.yield()
end
function fs.close(fd)
  uv.fs_close(fd, makeCallback())
  return coroutine.yield()
end
function fs.access(path, flags)
  uv.fs_access(path, flags or "", makeCallback())
  return coroutine.yield()
end
function fs.scandir(path)
  uv.fs_scandir(path, makeCallback())
  local req, err = coroutine.yield()
  if not req then return nil, err end
  return function ()
    return uv.fs_scandir_next(req)
  end
end

function fs.readFile(path)
  local fd, stat, data, err
  fd, err = fs.open(path)
  if err then return nil, err end
  stat, err = fs.fstat(fd)
  if stat then
    data, err = fs.read(fd, stat.size)
  end
  uv.fs_close(fd, noop)
  return data, err
end

function fs.writeFile(path, data, mkdir)
  local fd, success, err
  fd, err = fs.open(path, "w")
  if err then
    if mkdir and string.match(err, "^ENOENT:") then
      success, err = fs.mkdirp(pathJoin(path, ".."))
      if success then return fs.writeFile(path, data) end
    end
    return nil, err
  end
  success, err = fs.write(fd, data)
  uv.fs_close(fd, noop)
  return success, err
end

function fs.mkdirp(path, mode)
  local success, err = fs.mkdir(path, mode)
  if success or string.match(err, "^EEXIST") then
    return true
  end
  if string.match(err, "^ENOENT:") then
    success, err = fs.mkdirp(pathJoin(path, ".."), mode)
    if not success then return nil, err end
    return fs.mkdir(path, mode)
  end
  return nil, err
end

function fs.chroot(base)
  local chroot = {
    fstat = fs.fstat,
    fchmod = fs.fchmod,
    read = fs.read,
    write = fs.write,
    close = fs.close,
  }
  local function resolve(path)
    return pathJoin(base, pathJoin(path))
  end
  function chroot.mkdir(path, mode)
    return fs.mkdir(resolve(path), mode)
  end
  function chroot.mkdirp(path, mode)
    return fs.mkdirp(resolve(path), mode)
  end
  function chroot.open(path, flags, mode)
    return fs.open(resolve(path), flags, mode)
  end
  function chroot.unlink(path)
    return fs.unlink(resolve(path))
  end
  function chroot.stat(path)
    return fs.stat(resolve(path))
  end
  function chroot.lstat(path)
    return fs.lstat(resolve(path))
  end
  function chroot.readlink(path)
    return fs.readlink(resolve(path))
  end
  function chroot.access(path, flags)
    return fs.access(resolve(path), flags)
  end
  function chroot.scandir(path, iter)
    return fs.scandir(resolve(path), iter)
  end
  function chroot.readFile(path)
    return fs.readFile(resolve(path))
  end
  function chroot.writeFile(path, data, mkdir)
    return fs.writeFile(resolve(path), data, mkdir)
  end
  return chroot
end
